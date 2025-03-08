//
//  QuerySubscriber.swift
//  SwiftQuery
//
//  Created by Roland Kajatin on 08/03/2025.
//

import Foundation
import SwiftUI

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
    func querySubscriber(for keys: [QueryKey]) -> some View {
        modifier(QuerySubscriber(keys: keys))
    }

    func querySubscriber(for key: QueryKey) -> some View {
        modifier(QuerySubscriber(keys: [key]))
    }
}
