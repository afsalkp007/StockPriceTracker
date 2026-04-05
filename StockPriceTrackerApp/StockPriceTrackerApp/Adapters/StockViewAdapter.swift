import Foundation
import StockPriceTracker
import StockPriceTrackeriOS

@MainActor
final class StockViewAdapter {
    private weak var stateStore: StockListStateStore?
    var currentStocks: [Stock] { stateStore?.rawStocks ?? [] }

    // Allows us to navigate when a user selects a row
    private let selection: (Stock) -> Void

    init(
        stateStore: StockListStateStore,
        selection: @escaping (Stock) -> Void
    ) {
        self.stateStore = stateStore
        self.selection = selection
    }

    func updateRawStocks(_ stocks: [Stock]) {
        stateStore?.rawStocks = stocks
    }
    
    func select(symbol: String) {
        if let stock = currentStocks.first(where: { $0.symbol == symbol }) {
            selection(stock)
        }
    }
}

extension StockViewAdapter: ResourceView {
    typealias ResourceViewModel = StockListViewModel

    func display(_ viewModel: StockListViewModel) {
        stateStore?.listViewModel = viewModel
    }
}

extension StockViewAdapter: ResourceLoadingView {
    func display(_ viewModel: ResourceLoadingViewModel) {
        stateStore?.isLoading = viewModel.isLoading
    }
}

extension StockViewAdapter: ResourceErrorView {
    func display(_ viewModel: ResourceErrorViewModel) {
        stateStore?.errorMessage = viewModel.message
    }
}

extension StockViewAdapter: ConnectionStatusViewProtocol {
    func display(_ viewModel: ConnectionStatusViewModel) {
        stateStore?.connectionViewModel = viewModel
    }
}
