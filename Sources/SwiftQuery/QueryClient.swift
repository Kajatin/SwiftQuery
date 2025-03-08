//
//  QueryClient.swift
//  SwiftQuery
//
//  Created by Roland Kajatin on 26/02/2025.
//

import Foundation

/// Shared interface to register queries and issue operations on them (e.g. invalidation).
public class QueryClient: @unchecked Sendable {
    /// The app's shared query client to interact with registered queries. Most used for invalidation.
    public static let shared = QueryClient()
    private init() {}

    private var registeredQueries = [QueryKey]()
}

public extension QueryClient {
    /// Registers the provided `QueryKey` into the shared registry. Registered queries can be
    /// referenced later for operations such as invalidation.
    func register(_ key: QueryKey) {
        if self.registeredQueries.contains(key) {
            return
        }

        self.registeredQueries.append(key)
    }
}

public extension QueryClient {
    /// Publishes an invalidation notification for all of the registered queries. This function forces **all** queries to refetch.
    func invalidateQueries() {
        self.invalidateQueries(with: self.registeredQueries)
    }

    /// Publishes an invalidation notification for the provided queries.
    func invalidateQueries(with keys: [QueryKey]) {
        keys.forEach { key in
            self.invalidateQuery(with: key)
        }
    }

    /// Publishes an invalidation notification for the provided query.
    func invalidateQuery(with key: QueryKey) {
        NotificationCenter.default.post(
            name: QueryClient.invalidateNotificationName,
            object: key
        )
    }
}

public extension QueryClient {
    /// Notifies the corresponding queries of intent to receive up to date information from the queries.
    func subscribeToQueries(with keys: [QueryKey]) {
        keys.forEach { key in
            self.subscribeToQuery(with: key)
        }
    }

    /// Notifies the corresponding query of intent to receive up to date information from the query.
    func subscribeToQuery(with key: QueryKey) {
        NotificationCenter.default.post(
            name: QueryClient.subscriberOnNotificationName,
            object: key
        )
    }
}

public extension QueryClient {
    /// Notifies the corresponding queries of the revocation of intent to receive up to date information from the queries.
    func unsubscribeFromQueries(with keys: [QueryKey]) {
        keys.forEach { key in
            self.unsubscribeFromQuery(with: key)
        }
    }

    /// Notifies the corresponding query of the revocation of intent to receive up to date information from the query.
    func unsubscribeFromQuery(with key: QueryKey) {
        NotificationCenter.default.post(
            name: QueryClient.subscriberOffNotificationName,
            object: key
        )
    }
}

internal extension QueryClient {
    static let invalidateNotificationName = Notification.Name("swiftquery.invalidate")
    static let subscriberOnNotificationName = Notification.Name("swiftquery.subscriber.on")
    static let subscriberOffNotificationName = Notification.Name("swiftquery.subscriber.off")
}
