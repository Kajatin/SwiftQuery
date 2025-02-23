//
//  QueryStatus.swift
//  SwiftQuery
//
//  Created by Roland Kajatin on 23/02/2025.
//

import Foundation

public enum QueryStatus {
    /// If no query attempt was finished yet.
    case pending
    /// If the query attempt resulted in an error.
    case error
    /// If the query has received a response with no errors and is ready to display its data.
    case success
}
