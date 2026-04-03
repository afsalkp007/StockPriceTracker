import Foundation
import Combine
import StockPriceTracker
import StockPriceTrackeriOS

@MainActor
public final class StockDetailViewAdapter: ResourceView {
    private weak var stateStore: StockDetailStateStore?
    private var cancellable: AnyCancellable?

    public init(stateStore: StockDetailStateStore) {
        self.stateStore = stateStore
    }

    public func display(_ viewModel: StockDetailViewModel) {
        stateStore?.viewModel = viewModel
    }
    
    public func observe(_ updates: AnyPublisher<[Stock], Never>, for symbol: String, presenter: StockDetailPresenter) {
        cancellable = updates
            .receive(on: DispatchQueue.main)
            .sink { [weak presenter] stocks in
                if let updated = stocks.first(where: { $0.symbol == symbol }) {
                    presenter?.didReceive(updated)
                }
            }
    }
}
