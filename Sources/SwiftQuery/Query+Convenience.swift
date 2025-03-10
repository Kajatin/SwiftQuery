//
//  Query+Convenience.swift
//  SwiftQuery
//
//  Created by Roland Kajatin on 08/03/2025.
//

import Combine
import Foundation

extension Query {
    /// Convenience initializer for ``Query`` with a key and function. The query will not refetch automatically.
    public convenience init(
        queryKey: QueryKey,
        queryFn: @escaping () -> AnyPublisher<Response, Error>,
        executionPolicy: QueryExecutionPolicy = .automatic
    ) {
        self.init(
            queryKey: queryKey,
            queryFn: queryFn,
            executionPolicy: executionPolicy,
            refetchInterval: nil,
            retry: 3,
            retryDelay: 0.1
        )
    }

    /// Convenience initializer for ``Query`` with automatic refetching at the provided refetch interval.
    public convenience init(
        queryKey: QueryKey,
        queryFn: @escaping () -> AnyPublisher<Response, Error>,
        refetchInterval: TimeInterval,
        executionPolicy: QueryExecutionPolicy = .automatic
    ) {
        self.init(
            queryKey: queryKey,
            queryFn: queryFn,
            executionPolicy: executionPolicy,
            refetchInterval: refetchInterval,
            retry: 3,
            retryDelay: 0.1
        )
    }

    /// Convenience initializer for ``Query`` with custom retry configuration. The query will not refetch automatically.
    public convenience init(
        queryKey: QueryKey,
        queryFn: @escaping () -> AnyPublisher<Response, Error>,
        retry: UInt,
        retryDelay: TimeInterval,
        executionPolicy: QueryExecutionPolicy = .automatic
    ) {
        self.init(
            queryKey: queryKey,
            queryFn: queryFn,
            executionPolicy: executionPolicy,
            refetchInterval: nil,
            retry: retry,
            retryDelay: retryDelay
        )
    }
}
