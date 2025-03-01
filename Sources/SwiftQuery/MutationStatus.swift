//
//  MutationStatus.swift
//  SwiftQuery
//
//  Created by Roland Kajatin on 28/02/2025.
//

import Foundation

extension Mutation {
    /// Represents the current state of the fetching operation.
    public enum MutationStatus {
        /// Initial status prior to the mutation function executing.
        case idle
        /// The mutation function is currently executing.
        case pending
        /// The last mutation attempt resulted in an error.
        case error
        /// The last mutation attempt was successful.
        case success
    }
}
