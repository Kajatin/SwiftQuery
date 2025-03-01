//
//  Mutation.swift
//  SwiftQuery
//
//  Created by Roland Kajatin on 28/02/2025.
//

import Combine
import Foundation
import OSLog

@Observable
public final class Mutation<Request: Sendable, Response>: @unchecked Sendable {
    // MARK: Public states

    /// Indicates the status of the query.
    public var status: MutationStatus
    /// A derived boolean from the ``status`` variable above, provided for convenience.
    public var isIdle: Bool {
        self.status == .idle
    }
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

    /// The last successfully resolved data for the mutation.
    public var data: Response?

    /// The error object for the mutation, if an error was thrown.
    public var error: (any Error)?

    /// The failure count for the mutation, incremented every time the mutation fails. Reset to 0 when the mutation succeeds.
    public var failureCount: UInt

    /// The date for when the mutation was submitted.
    public var submittedAt: Date?

    // MARK: Private states

    @ObservationIgnored private let mutationFn: (Request) -> AnyPublisher<Response, Error>
    @ObservationIgnored private let onError: (Error) -> Void
    @ObservationIgnored private let onSettled: (Response?, Error?) -> Void
    @ObservationIgnored private let onSuccess: (Response) -> Void
    @ObservationIgnored private let retry: UInt
    @ObservationIgnored private let retryDelay: TimeInterval

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    @ObservationIgnored private let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier!,
        category: "SwiftQuery.Mutation"
    )

    public init(
        mutationFn: @escaping (Request) -> AnyPublisher<Response, Error>,
        onError: @escaping (Error) -> Void = { _ in },
        onSettled: @escaping (Response?, Error?) -> Void = { _, _ in },
        onSuccess: @escaping (Response) -> Void = { _ in },
        retry: UInt = 3,
        retryDelay: TimeInterval? = nil
    ) {
        // Initialize public states
        self.status = .idle
        self.failureCount = 0

        // Initialize private states
        self.mutationFn = mutationFn
        self.onError = onError
        self.onSettled = onSettled
        self.onSuccess = onSuccess
        self.retry = retry
        self.retryDelay = retryDelay ?? 0.1
    }

    public func reset() {
        self.status = .idle
        self.data = nil
        self.error = nil
        self.failureCount = 0
        self.submittedAt = nil
    }

    public func mutate(_ input: Request) {
        self.logger.debug("Running `mutate()` at \(Date.now)")

        self.cancellables.forEach { $0.cancel() }
        self.cancellables.removeAll()

        self.status = .pending
        self.submittedAt = Date()

        mutationFn(input)
            .sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        self.error = error
                        self.logger.error(
                            "Error mutating data at \(Date.now): \(error.localizedDescription)"
                        )

                        self.status = .error
                        self.failureCount += 1
                        
                        self.onError(error)
                        self.onSettled(nil, error)
                    case .finished:
                        self.error = nil

                        self.status = .success
                        self.failureCount = 0
                    }

                    self.cancellables.removeAll()

                    if self.failureCount > 0 && self.failureCount <= self.retry {
                        self.logger.debug(
                            "Retrying mutation after \(self.retryDelay) seconds (failed \(self.failureCount)/\(self.retry) times)"
                        )
                        self.createRetryTimer(input)
                    }
                },
                receiveValue: { value in
                    self.data = value
                    self.onSuccess(value)
                    self.onSettled(value, nil)
                }
            )
            .store(in: &self.cancellables)
    }

    private func createRetryTimer(_ input: Request) {
        Timer.scheduledTimer(withTimeInterval: self.retryDelay, repeats: false) { [input] timer in
            self.mutate(input)
            timer.invalidate()
        }
    }
}
