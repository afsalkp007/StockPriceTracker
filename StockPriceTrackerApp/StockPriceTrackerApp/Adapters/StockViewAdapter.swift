import Foundation
import StockPriceTracker
import StockPriceTrackeriOS

@MainActor
public final class StockViewAdapter {
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

    public func updateRawStocks(_ stocks: [Stock]) {
        stateStore?.rawStocks = stocks
    }
    
    public func select(symbol: String) {
        if let stock = currentStocks.first(where: { $0.symbol == symbol }) {
            selection(stock)
        }
    }
}

extension StockViewAdapter: ResourceView {
    public typealias ResourceViewModel = StockListViewModel

    public func display(_ viewModel: StockListViewModel) {
        stateStore?.listViewModel = viewModel
    }
}

extension StockViewAdapter: ResourceLoadingView {
    public func display(_ viewModel: ResourceLoadingViewModel) {
        stateStore?.isLoading = viewModel.isLoading
    }
}

extension StockViewAdapter: ResourceErrorView {
    public func display(_ viewModel: ResourceErrorViewModel) {
        stateStore?.errorMessage = viewModel.message
    }
}

extension StockViewAdapter: ConnectionStatusViewProtocol {
    public func display(_ viewModel: ConnectionStatusViewModel) {
        stateStore?.connectionViewModel = viewModel
    }
}
