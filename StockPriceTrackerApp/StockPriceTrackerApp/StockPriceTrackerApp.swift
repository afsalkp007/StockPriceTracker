import SwiftUI
import Combine
import StockPriceTracker
import StockPriceTrackeriOS

@main
struct StockPriceTrackerApp: App {
    @StateObject private var serviceState = AppServiceState()
    @StateObject private var stockListStateStore = StockListStateStore()

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                StockUIComposer.stockListComposedWith(
                    stateStore: stockListStateStore,
                    feedLoader: serviceState.makeFeedLoader(),
                    feedController: serviceState.feedController,
                    onFeedStartConfigured: { serviceState.startFeed = $0 },
                    selection: { stock in
                        serviceState.selectedStock = stock
                    }
                )
                .navigationDestination(item: $serviceState.selectedStock) { stock in
                    StockDetailUIComposer.stockDetailComposedWith(
                        stock: stock,
                        stockUpdates: stockListStateStore.$rawStocks.eraseToAnyPublisher(),
                        connectionStatus: stockListStateStore.$connectionViewModel.eraseToAnyPublisher(),
                        onRetryConnection: { serviceState.startFeed?() }
                    )
                }
            }
        }
    }
}

@MainActor
final class AppServiceState: ObservableObject {
    private let stockFeed: any StockFeedLoader & StockFeedController
    @Published var selectedStock: Stock?
    var startFeed: (() -> Void)?

    init(stockFeed: (any StockFeedLoader & StockFeedController)? = nil) {
        self.stockFeed = stockFeed ?? Self.makeDefaultStockFeed()
    }

    var feedController: StockFeedController {
        stockFeed
    }

    func makeFeedLoader() -> () -> AsyncThrowingStream<[Stock], Error> {
        { [stockFeed] in
            stockFeed.startFeed()
        }
    }

    private static func makeDefaultStockFeed() -> any StockFeedLoader & StockFeedController {
        let url = URL(string: "wss://ws.postman-echo.com/raw")!
        let client = URLSessionWebSocketClient(url: url)
        return WebSocketStockFeedLoader(client: client)
    }
}
