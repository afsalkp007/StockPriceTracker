import StockPriceTracker
import StockPriceTrackeriOS

@MainActor
final class StockDetailViewAdapter: ResourceView {
    private weak var stateStore: StockDetailStateStore?

    init(stateStore: StockDetailStateStore) {
        self.stateStore = stateStore
    }

    func display(_ viewModel: StockDetailViewModel) {
        stateStore?.viewModel = viewModel
    }
}
