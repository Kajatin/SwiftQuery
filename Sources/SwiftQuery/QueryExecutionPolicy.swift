//
//  QueryExecutionPolicy.swift
//  SwiftQuery
//
//  Created by Roland Kajatin on 08/03/2025.
//

import Foundation

/// Specifies how a ``Query`` executes refetches.
public enum QueryExecutionPolicy {
    /// Refetching executes automatically.
    case automatic
    /// Refetching is based on subscriptions. Useful in combination with ``QuerySubscriber`` modifier in views.
    case subscriptionBased(UInt)
}
