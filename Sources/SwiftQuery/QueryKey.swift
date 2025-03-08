//
//  QueryKey.swift
//  SwiftQuery
//
//  Created by Roland Kajatin on 25/02/2025.
//

import Foundation

/// A wrapper for a unique set of keys to represent a ``Query``.
///
/// Keys contain an array of items to reference a ``Query``. This can be
/// used to invalidate queries. Note that invalidation can be done with partial
/// key overlapping.
///
/// Invalidating `["key"]` will refetch both of these queries with keys: `["key"]`
/// and `["key", "anotherKey"`].
public struct QueryKey: Hashable, CustomDebugStringConvertible {
    private let keys: [AnyHashable]

    public var debugDescription: String {
        "[" + self.keys.map(\.self.description).joined(separator: ", ") + "]"
    }

    /// Initializer that takes an array of hashable items (most frequently `String` or some number.
    public init(_ keys: [AnyHashable] = [AnyHashable]()) {
        self.keys = keys
    }

    public static func == (lhs: QueryKey, rhs: QueryKey) -> Bool {
        return lhs.keys == rhs.keys
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(keys)
    }

    internal func isCompleteSubset(of other: QueryKey) -> Bool {
        return self.keys.allSatisfy { key in
            other.keys.contains(key)
        }
    }
}
