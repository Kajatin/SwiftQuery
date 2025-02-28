//
//  QueryStatus.swift
//  SwiftQuery
//
//  Created by Roland Kajatin on 23/02/2025.
//

import Foundation

extension Query {
    /// Indicates the current status of the query operation.
    public enum QueryStatus {
        /// No query attempt was finished yet. This is the first state any ``Query`` gets into.
        case pending
        /// The query attempt resulted in an error.
        case error
        /// The query has received a response with no errors and is ready to display its data.
        case success
    }
}
