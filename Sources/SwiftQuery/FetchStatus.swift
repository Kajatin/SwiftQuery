//
//  FetchStatus.swift
//  SwiftQuery
//
//  Created by Roland Kajatin on 23/02/2025.
//

import Foundation

public enum FetchStatus {
    /// Is true whenever the query function is executing, which includes initial pending as well as background refetches.
    case fetching
    /// The query wanted to fetch, but has been paused.
    case paused
    /// The query is not fetching.
    case idle
}
