import Foundation
import Testing

@testable import SwiftQuery

@Suite("QueryKey")
struct QueryKeyTests {
    @Test("Basic query key arithmetic")
    func compareQueryKeys() async throws {
        let key1 = QueryKey(["abc", "anotherKey", 12])
        let key2 = QueryKey(["abc", "anotherKey", 11])

        #expect(key1 == key1)
        #expect(key1 != key2)
    }
}

@Suite("QueryClient")
struct QueryClientTests {
    @Test("Invalidation notification name is correct")
    func ensureNotificationName() async throws {
        #expect(QueryClient.invalidateNotificationName == Notification.Name("swiftquery.invalidate"))
    }

    @Test("Notification received when invalidating a query")
    func ensureNotificationReceived() async throws {
        let key1 = QueryKey(["abc"])

        QueryClient.shared.register(key1)

        await confirmation() { confirmation in
            let observer = NotificationCenter
                .default
                .addObserver(forName: QueryClient.invalidateNotificationName, object: nil, queue: nil) { _ in
                    confirmation()
                }

            QueryClient.shared.invalidateQuery(for: key1)

            NotificationCenter.default.removeObserver(observer)
        }
    }
}

@Test(.disabled())
func queryKeySetProperly() throws {
    struct User: Codable, Identifiable {
        let id: Int
        let name: String
    }

    let query = Query<[User]>(
        queryKey: .init(["key1", "users", "test"]),
        queryFn: {
            URLSession.shared
                .dataTaskPublisher(for: URL(string: "https://jsonplaceholder.typicode.com/users")!)
                .tryMap { data, response in
                    guard let httpResponse = response as? HTTPURLResponse,
                        (200..<300).contains(httpResponse.statusCode)
                    else { throw URLError(.badServerResponse) }
                    return data
                }
                .decode(type: [User].self, decoder: JSONDecoder())
                .receive(on: DispatchQueue.main)
                .eraseToAnyPublisher()
        }
    )

    #expect(query.isLoading == true)
}
