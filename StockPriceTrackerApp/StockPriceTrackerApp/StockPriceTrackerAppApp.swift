import SwiftUI
import Combine
import StockPriceTracker

@main
struct StockPriceTrackerAppApp: App {
    @StateObject private var serviceState = AppServiceState()
    
    var body: some Scene {
        WindowGroup {
            NavigationStack {
                StockUIComposer.stockListComposedWith(
                    feedLoader: serviceState.service.makeFeedLoader(),
                    feedController: serviceState.service.feedController(),
                    selection: { stock in
                        serviceState.selectedStock = stock
                    }
                )
                .navigationDestination(item: $serviceState.selectedStock) { stock in
                    StockDetailUIComposer.stockDetailComposedWith(stock: stock)
                }
            }
        }
    }
}

// AppServiceState ensures StockService is retained and provides observable state for SwiftUI Navigation
@MainActor
final class AppServiceState: ObservableObject {
    let service = StockService()
    @Published var selectedStock: Stock?
}
