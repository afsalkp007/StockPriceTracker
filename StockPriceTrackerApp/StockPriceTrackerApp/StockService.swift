import Foundation
import StockPriceTracker

@MainActor
public final class StockService {
    private lazy var webSocketClient: WebSocketClient = {
        let url = URL(string: "wss://ws.postman-echo.com/raw")!
        return URLSessionWebSocketClient(url: url)
    }()
    
    private lazy var feedLoader = WebSocketStockFeedLoader(client: webSocketClient)
    
    public init() {}
    
    public func makeFeedLoader() -> () -> AsyncThrowingStream<[Stock], Error> {
        return { [feedLoader] in
            feedLoader.startFeed()
        }
    }
    
    public func feedController() -> StockFeedController {
        return feedLoader
    }
}
