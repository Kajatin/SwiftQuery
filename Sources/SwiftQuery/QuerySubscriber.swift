//
//  QuerySubscriber.swift
//  SwiftQuery
//
//  Created by Roland Kajatin on 08/03/2025.
//

import Foundation
import SwiftUI

/// Conveniently manages a subscription to queries on a view based on appearance and disappearance events.
struct QuerySubscriber: ViewModifier {
    var keys: [QueryKey]

    func body(content: Content) -> some View {
        content
            .onAppear {
                QueryClient.shared.subscribeToQueries(with: keys)
            }
            .onDisappear {
                QueryClient.shared.unsubscribeFromQueries(with: keys)
            }
    }
}

public extension View {
    /// Modifier to subscribe to queries.
    func querySubscriber(for keys: [QueryKey]) -> some View {
        modifier(QuerySubscriber(keys: keys))
    }

    /// Modifier to subscribe to a query.
    func querySubscriber(for key: QueryKey) -> some View {
        modifier(QuerySubscriber(keys: [key]))
    }
}
