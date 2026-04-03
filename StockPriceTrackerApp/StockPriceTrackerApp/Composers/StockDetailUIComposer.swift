import SwiftUI
import Combine
import StockPriceTracker
import StockPriceTrackeriOS

@MainActor
public final class StockDetailUIComposer {
    private init() {}
    
    public static func stockDetailComposedWith(
        stock: Stock,
        stockUpdates: AnyPublisher<[Stock], Never>
    ) -> some View {
        let stateStore = StockDetailStateStore()
        let viewAdapter = StockDetailViewAdapter(stateStore: stateStore)
        let presenter = StockDetailPresenter(detailView: viewAdapter)
        presenter.didReceive(stock)
        
        return StockDetailView(stateStore: stateStore)
            .onReceive(stockUpdates.receive(on: DispatchQueue.main)) { stocks in
                if let updatedStock = stocks.first(where: { $0.symbol == stock.symbol }) {
                    presenter.didReceive(updatedStock)
                }
            }
    }
}
