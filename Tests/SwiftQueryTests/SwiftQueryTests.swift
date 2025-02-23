import Foundation
import Testing

@testable import SwiftQuery

@Test func queryKeySetProperly() throws {
    struct User: Codable, Identifiable {
        let id: Int
        let name: String
    }
    
    let query = SwiftQuery<[User]>(
        queryKey: "test",
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
