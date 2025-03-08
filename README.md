# SwiftQuery

[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FKajatin%2FSwiftQuery%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/Kajatin/SwiftQuery)
[![](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2FKajatin%2FSwiftQuery%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/Kajatin/SwiftQuery)

SwiftQuery is a lightweight, Combine-based query and mutation library for Swift,
designed to simplify data fetching and caching while supporting automatic revalidation.

### Features

- 📦 Declarative API – Define queries and mutations with ease.
- 🔄 Automatic Revalidation – Keep your data fresh with built-in refetching.
- ❌ Query Invalidations – Invalidate and refetch queries programmatically.
- ⏳ Retry Mechanism – Automatically retry failed requests.
- 🚀 Optimized for SwiftUI – Uses @Observable for seamless UI updates.

## Installation

SwiftQuery is available via Swift Package Manager (SPM).

### Add via Xcode:

1. Open your project and go to **File > Add Package Dependencies...**
1. Enter the package URL: https://github.com/Kajatin/SwiftQuery
1. Choose **"Up to Next Major Version"** and click Add Package.

### Add via `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Kajatin/SwiftQuery.git", from: "0.1.0")
]
```

## Usage

You can pass in any Combine compatible query function to be wrapped by `Query`.
A simple example using SwiftUI would be:

```swift
import Combine
import SwiftUI
import SwiftQuery

struct UserView: View {
    struct User: Codable, Identifiable {
        let id: Int
        let name: String
    }

    let query = Query<[User]>(
        queryKey: .init(["users"]),
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

    var body: some View {
        VStack {
            if userQuery.isLoading {
                ProgressView()
            } else if userQuery.isError {
                Text("Failed to fetch user")
            } else if let user = userQuery.data {
                Text("Hello, \(user.name)!")
            }
        }
    }
}

#Preview {
  UserView()
}
```

## Documentation

The full API documentation is available on the Swift Package Index: SwiftQuery Documentation

## Contributing

Contributions are welcome! Feel free to open issues or submit pull requests.

## License

This project uses the MIT license.
