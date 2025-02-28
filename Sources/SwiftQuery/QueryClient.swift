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

extension QueryClient {
    /// Registers the provided `QueryKey` into the shared registry. Registered queries can be
    /// referenced later for operations such as invalidation.
    public func register(_ key: QueryKey) {
        if self.registeredQueries.contains(key) {
            return
        }

        self.registeredQueries.append(key)
    }
}

extension QueryClient {
    /// Publishes an invalidation notification for all of the registered queries. This function forces **all**
    /// queries to refetch.
    public func invalidateQueries() {
        self.invalidateQueries(for: self.registeredQueries)
    }

    /// Publishes an invalidation notification for the provided queries.
    public func invalidateQueries(for keys: [QueryKey]) {
        registeredQueries.forEach { key in
            self.invalidateQuery(for: key)
        }
    }

    /// Publishes an invalidation notification for the provided query.
    public func invalidateQuery(for key: QueryKey) {
        NotificationCenter.default.post(
            name: Notification.Name("swiftquery.invalidate"),
            object: key
        )
    }
}

internal extension QueryClient {
    static let invalidateNotificationName = Notification.Name("swiftquery.invalidate")
}
