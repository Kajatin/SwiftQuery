//
//  Query.swift
//  SwiftQuery
//
//  Created by Roland Kajatin on 23/02/2025.
//

import Combine
import Foundation
import OSLog

/// Main interface to create smart data fetching functionality.
/// It supports automatic revalidation for any Combine compatible query.

@Observable
public final class Query<Response: Codable>: @unchecked Sendable {
    // MARK: Public states

    /// Indicates the status of the query.
    public var status: QueryStatus
    /// A derived boolean from the ``status`` variable above, provided for convenience.
    public var isPending: Bool {
        self.status == .pending
    }
    /// A derived boolean from the ``status`` variable above, provided for convenience.
    public var isError: Bool {
        self.status == .error
    }
    /// A derived boolean from the ``status`` variable above, provided for convenience.
    public var isSuccess: Bool {
        self.status == .success
    }

    /// The last successfully resolved data for the query.
    public var data: Response?
    /// The date for when the query most recently returned the status as `QueryStatus.success`.
    public var dataUpdatedAt: Date?

    /// The error object for the query, if an error was thrown.
    public var error: (any Error)?
    /// The timestamp for when the query most recently returned the status as `QueryStatus.error`.
    public var errorUpdatedAt: Date?

    /// Indicates the status of the fetch operation.
    public var fetchStatus: FetchStatus
    /// A derived boolean from the ``fetchStatus`` variable above, provided for convenience.
    public var isFetching: Bool {
        self.fetchStatus == .fetching
    }
    /// A derived boolean from the ``fetchStatus`` variable above, provided for convenience.
    public var isPaused: Bool {
        self.fetchStatus == .paused
    }
    /// Is true whenever a background refetch is in-flight, which does not include initial pending.
    public var isRefetching: Bool {
        self.isFetching && !self.isPending
    }

    /// Is true whenever the first fetch for a query is in-flight. The same as `isFetching && isPending`.
    public var isLoading: Bool {
        self.isFetching && self.isPending
    }

    /// The failure count for the query incremented every time the query fails. Reset to 0 when the query succeeds.
    public var failureCount: UInt

    // MARK: Private states

    @ObservationIgnored private let queryFn: () -> AnyPublisher<Response, Error>
    @ObservationIgnored private let queryKey: QueryKey
    @ObservationIgnored private let refetchInterval: TimeInterval?
    @ObservationIgnored private let retry: UInt
    @ObservationIgnored private let retryDelay: TimeInterval

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var timerCancellables = Set<AnyCancellable>()
    @ObservationIgnored private var notificationCancellables = Set<
        AnyCancellable
    >()

    @ObservationIgnored private var executionPolicy: QueryExecutionPolicy

    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "SwiftQuery.Query"
    )

    // MARK: Functions

    /// Initializes a new query with the provided key and automatically registers it in the shared ``QueryClient``.
    public init(
        queryKey: QueryKey,
        queryFn: @escaping () -> AnyPublisher<Response, Error>,
        executionPolicy: QueryExecutionPolicy,
        refetchInterval: TimeInterval?,
        retry: UInt,
        retryDelay: TimeInterval
    ) {
        // Initialize public states
        self.status = .pending
        self.fetchStatus = .fetching
        self.failureCount = 0

        // Initialize private states
        self.queryFn = queryFn
        self.queryKey = queryKey
        self.refetchInterval = refetchInterval
        self.retry = retry
        self.retryDelay = retryDelay

        self.executionPolicy = executionPolicy

        // Registerting this query with the client enables the
        // sending of messages by referencing the query key from
        // anywhere in the code (e.g. to invalidate the query).
        QueryClient.shared.register(queryKey)

        self.subscribeToNotifications()

        // Let's kick-start the refetch process by invalidating immediately
        QueryClient.shared.invalidateQuery(with: self.queryKey)
    }

    private func refetch() {
        self.logger.debug("Running `refetch()` at \(Date.now)")

        self.setupTimer()

        if case .subscriptionBased(let value) = self.executionPolicy {
            if value == 0 {
                self.fetchStatus = .paused

                self.logger.debug("No active subscribers, query is paused")

                return
            }
        }

        self.fetchStatus = .fetching

        queryFn()
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        self.error = error
                        self.errorUpdatedAt = Date.now
                        self.logger.error(
                            "Error fetching data for query with key \(self.queryKey.debugDescription) at \(self.errorUpdatedAt!): \(error.localizedDescription)"
                        )

                        self.status = .error
                        self.failureCount += 1

                        self.timerCancellables.forEach { $0.cancel() }
                        self.timerCancellables.removeAll()
                    case .finished:
                        self.error = nil
                        self.errorUpdatedAt = nil

                        self.status = .success
                        self.failureCount = 0
                    }

                    self.fetchStatus = .idle

                    if self.failureCount > 0 && self.failureCount <= self.retry {
                        self.logger.debug(
                            "Retrying query with key \(self.queryKey.debugDescription) after \(self.retryDelay) seconds (failed \(self.failureCount)/\(self.retry) times)"
                        )
                        self.createRetryTimer()
                    }
                },
                receiveValue: { value in
                    self.data = value
                    self.dataUpdatedAt = Date.now
                    self.logger.debug(
                        "Successfully fetched new data for query with key \(self.queryKey.debugDescription) at \(self.dataUpdatedAt!)"
                    )
                }
            )
            .store(in: &self.cancellables)
    }

    private func setupTimer() {
        if !self.timerCancellables.isEmpty {
            return
        }

        if let interval = self.refetchInterval {
            Timer.publish(every: interval, on: .main, in: .common)
                .autoconnect()
                .sink(
                    receiveCompletion: { completion in
                        self.timerCancellables.removeAll()
                    },
                    receiveValue: { value in
                        self.refetch()
                    }
                )
                .store(in: &timerCancellables)
        }
    }

    private func createRetryTimer() {
        Timer.scheduledTimer(withTimeInterval: self.retryDelay, repeats: false) { timer in
            self.refetch()
            timer.invalidate()
        }
    }
}

// MARK: Extensions

extension Query {
    private func subscribeToInvalidationNotifications() {
        NotificationCenter
            .default
            .publisher(for: QueryClient.invalidateNotificationName)
            .eraseToAnyPublisher()
            .sink(receiveValue: { value in
                if let invalidationKey = value.object as? QueryKey {
                    if !invalidationKey.isCompleteSubset(of: self.queryKey) {
                        return
                    }

                    self.timerCancellables.forEach { $0.cancel() }
                    self.timerCancellables.removeAll()

                    self.cancellables.forEach { $0.cancel() }
                    self.cancellables.removeAll()

                    self.refetch()
                }
            })
            .store(in: &notificationCancellables)
    }

    private func subscribeToSubscriberOnNotifications() {
        NotificationCenter
            .default
            .publisher(for: QueryClient.subscriberOnNotificationName)
            .eraseToAnyPublisher()
            .sink(receiveValue: { value in
                if let invalidationKey = value.object as? QueryKey {
                    if !invalidationKey.isCompleteSubset(of: self.queryKey) {
                        return
                    }

                    if case .subscriptionBased(let value) = self.executionPolicy {
                        self.executionPolicy = .subscriptionBased(value + 1)

                        self.refetch()
                    }
                }
            })
            .store(in: &notificationCancellables)
    }

    private func subscribeToSubscriberOffNotifications() {
        NotificationCenter
            .default
            .publisher(for: QueryClient.subscriberOffNotificationName)
            .eraseToAnyPublisher()
            .sink(receiveValue: { value in
                if let invalidationKey = value.object as? QueryKey {
                    if !invalidationKey.isCompleteSubset(of: self.queryKey) {
                        return
                    }

                    if case .subscriptionBased(let value) = self.executionPolicy {
                        self.executionPolicy = .subscriptionBased(max(value - 1, 0))
                    }
                }
            })
            .store(in: &notificationCancellables)
    }

    private func subscribeToNotifications() {
        self.subscribeToInvalidationNotifications()
        self.subscribeToSubscriberOnNotifications()
        self.subscribeToSubscriberOffNotifications()
    }
}
