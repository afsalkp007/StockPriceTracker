import Foundation
import StockPriceTracker

@MainActor
public final class StockService {
    private let stockFeed: any StockFeedLoader & StockFeedController

    public init(stockFeed: (any StockFeedLoader & StockFeedController)? = nil) {
        self.stockFeed = stockFeed ?? Self.makeDefaultStockFeed()
    }
    
    public func makeFeedLoader() -> () -> AsyncThrowingStream<[Stock], Error> {
        return { [stockFeed] in
            stockFeed.startFeed()
        }
    }
    
    public func feedController() -> StockFeedController {
        return stockFeed
    }

    private static func makeDefaultStockFeed() -> any StockFeedLoader & StockFeedController {
        let url = URL(string: "wss://ws.postman-echo.com/raw")!
        let client = URLSessionWebSocketClient(url: url)
        return WebSocketStockFeedLoader(client: client)
    }
}
