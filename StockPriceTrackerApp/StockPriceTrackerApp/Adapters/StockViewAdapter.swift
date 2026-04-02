import Foundation
import StockPriceTracker
import StockPriceTrackeriOS

@MainActor
public final class StockViewAdapter: ResourceView {
    private weak var stateStore: StockListStateStore?
    public var currentStocks: [Stock] { stateStore?.rawStocks ?? [] }

    // Allows us to navigate when a user selects a row
    private let selection: (Stock) -> Void

    public init(
        stateStore: StockListStateStore,
        selection: @escaping (Stock) -> Void
    ) {
        self.stateStore = stateStore
        self.selection = selection
    }

    public func display(_ viewModel: StockListViewModel) {
        stateStore?.listViewModel = viewModel
    }
    
    public func updateRawStocks(_ stocks: [Stock]) {
        stateStore?.rawStocks = stocks
    }
    
    public func select(symbol: String) {
        if let stock = currentStocks.first(where: { $0.symbol == symbol }) {
            selection(stock)
        }
    }
}

extension StockListStateStore: ResourceLoadingView {
    public func display(_ viewModel: ResourceLoadingViewModel) {
        self.isLoading = viewModel.isLoading
    }
}

extension StockListStateStore: ResourceErrorView {
    public func display(_ viewModel: ResourceErrorViewModel) {
        self.errorMessage = viewModel.message
    }
}

extension StockListStateStore: ConnectionStatusViewProtocol {
    public func display(_ viewModel: ConnectionStatusViewModel) {
        self.connectionViewModel = viewModel
    }
}
