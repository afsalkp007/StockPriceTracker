import Foundation
import StockPriceTracker
import StockPriceTrackeriOS

@MainActor
public final class StockDetailViewAdapter: ResourceView {
    private weak var stateStore: StockDetailStateStore?

    public init(stateStore: StockDetailStateStore) {
        self.stateStore = stateStore
    }

    public func display(_ viewModel: StockDetailViewModel) {
        stateStore?.viewModel = viewModel
    }
}
