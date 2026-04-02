import SwiftUI
import StockPriceTracker
import StockPriceTrackeriOS

@MainActor
public final class StockDetailUIComposer {
    private init() {}
    
    public static func stockDetailComposedWith(stock: Stock) -> some View {
        let stateStore = StockDetailStateStore()
        let viewAdapter = StockDetailViewAdapter(stateStore: stateStore)
        let presenter = StockDetailPresenter(detailView: viewAdapter)
        
        presenter.didReceive(stock)
        
        return StockDetailView(stateStore: stateStore)
    }
}
