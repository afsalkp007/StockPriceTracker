@MainActor
public protocol StockFeedLoader {
    func startFeed() -> AsyncThrowingStream<[Stock], Error>
}

