import Combine
import Foundation

@Observable
final class SwiftQuery<Response: Codable> {
    // MARK: Public states
    
    /// TODO
    var status: QueryStatus
    /// A derived boolean from the `status` variable above, provided for convenience.
    var isPending: Bool {
        self.status == .pending
    }
    /// A derived boolean from the `status` variable above, provided for convenience.
    var isError: Bool {
        self.status == .error
    }
    /// A derived boolean from the `status` variable above, provided for convenience.
    var isSuccess: Bool {
        self.status == .success
    }
    
    /// The last successfully resolved data for the query.
    var data: String?
    /// The date for when the query most recently returned the status as `QueryStatus.success`.
    var dataUpdatedAt: Date?
    
    /// The error object for the query, if an error was thrown.
    var error: String?
    /// The timestamp for when the query most recently returned the status as `QueryStatus.error`.
    var errorUpdatedAt: Date?
    
    /// TODO
    var fetchStatus: FetchStatus
    /// A derived boolean from the `fetchStatus` variable above, provided for convenience.
    var isFetching: Bool {
        self.fetchStatus == .fetching
    }
    /// A derived boolean from the `fetchStatus` variable above, provided for convenience.
    var isPaused: Bool {
        self.fetchStatus == .paused
    }
    /// Is true whenever a background refetch is in-flight, which does not include initial pending.
    var isRefetching: Bool {
        self.isFetching && !self.isPending
    }
    
    /// Is true whenever the first fetch for a query is in-flight. The same as `isFetching && isPending`.
    var isLoading: Bool {
        self.isFetching && self.isPending
    }
    
    /// The failure count for the query incremented every time the query fails. Reset to 0 when the query succeeds.
    var failureCount: UInt
    
    /// A function to manually refetch the query.
//    var refetch: (Request) -> Void
    
    // MARK: Private states
    
    private let queryKey: String
    private let queryFn: () -> AnyPublisher<Response, Error>
    private let refetchInterval: TimeInterval?
    private let retry: Int
    private let retryDelay: TimeInterval?
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: Functions
    
    public init(
        queryKey: String,
        queryFn: @escaping () -> AnyPublisher<Response, Error>,
        refetchInterval: TimeInterval? = nil,
        retry: Int = 3,
        retryDelay: TimeInterval? = nil
    ) {
        // Initialize public states
        self.status = .pending
        self.fetchStatus = .fetching
        self.failureCount = 0
        
        // Initialize private states
        self.queryKey = queryKey
        self.queryFn = queryFn
        self.refetchInterval = refetchInterval
        self.retry = retry
        self.retryDelay = retryDelay
        
        self.refetch()
    }
    
    public func refetch() {
        queryFn()
            .sink(receiveCompletion: { completion in
                print("Completion: \(completion)")
            }, receiveValue: { value in
                print("Value: \(value)")
            })
            .store(in: &self.cancellables)
    }
}
