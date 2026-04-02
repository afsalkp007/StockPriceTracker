import SwiftUI
import StockPriceTracker
import StockPriceTrackeriOS

@MainActor
public final class StockUIComposer {
    private init() {}
    
    public static func stockListComposedWith(
        stateStore: StockListStateStore,
        feedLoader: @escaping () -> AsyncThrowingStream<[Stock], Error>,
        feedController: StockFeedController,
        selection: @escaping (Stock) -> Void
    ) -> some View {
        let presentationAdapter = StockFeedPresentationAdapter(loader: feedLoader)
        let viewAdapter = StockViewAdapter(stateStore: stateStore, selection: selection)
        
        let presenter = LoadResourcePresenter(
            resourceView: viewAdapter,
            loadingView: WeakRefVirtualProxy(stateStore),
            errorView: WeakRefVirtualProxy(stateStore),
            mapper: { stocks in
                viewAdapter.updateRawStocks(stocks)
                let stockPresenter = StockPresenter(
                    listView: viewAdapter,
                    connectionView: WeakRefVirtualProxy(stateStore)
                )
                stockPresenter.didConnect()
                stockPresenter.didReceive(stocks, sortedBy: stateStore.currentSort)
                return stateStore.listViewModel
            }
        )
        
        presentationAdapter.presenter = presenter
        
        let view = StockListView(
            stateStore: stateStore,
            onStart: {
                presentationAdapter.didRequestFeedLoad()
                feedController.start()
            },
            onStop: {
                stateStore.display(.disconnected)
                Task {
                    await presentationAdapter.didCancelFeedLoad()
                    await feedController.stop()
                }
            },
            onSort: { newSort in
                let stockPresenter = StockPresenter(
                    listView: viewAdapter,
                    connectionView: WeakRefVirtualProxy(stateStore)
                )
                stockPresenter.didReceive(viewAdapter.currentStocks, sortedBy: newSort)
            },
            onRowSelected: { symbol in
                viewAdapter.select(symbol: symbol)
            }
        )
        
        return view
    }
}
