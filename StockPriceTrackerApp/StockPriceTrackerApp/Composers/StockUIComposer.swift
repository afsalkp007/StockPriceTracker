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
        onFeedStartConfigured: ((@escaping () -> Void) -> Void)? = nil,
        selection: @escaping (Stock) -> Void
    ) -> some View {
        let presentationAdapter = StockFeedPresentationAdapter(loader: feedLoader)
        let viewAdapter = StockViewAdapter(stateStore: stateStore, selection: selection)
        let startFeed = {
            presentationAdapter.didRequestFeedLoad()
            feedController.start()
        }
        
        let presenter = LoadResourcePresenter<[Stock], StockViewAdapter>(
            resourceView: viewAdapter,
            loadingView: WeakRefVirtualProxy(viewAdapter),
            errorView: WeakRefVirtualProxy(viewAdapter),
            mapper: { (stocks: [Stock]) -> StockListViewModel in
                viewAdapter.updateRawStocks(stocks)
                let stockPresenter = StockPresenter(
                    listView: viewAdapter,
                    connectionView: WeakRefVirtualProxy(viewAdapter)
                )
                stockPresenter.didConnect()
                stockPresenter.didReceive(stocks, sortedBy: stateStore.currentSort)
                return stateStore.listViewModel
            }
        )
        
        presentationAdapter.presenter = presenter
        presentationAdapter.onFeedEnd = { [weak viewAdapter] in
            viewAdapter?.display(.disconnected)
        }
        
        let view = StockListView(
            stateStore: stateStore,
            onStart: startFeed,
            onStop: {
                viewAdapter.display(.disconnected)
                Task {
                    await presentationAdapter.didCancelFeedLoad()
                    await feedController.stop()
                }
            },
            onSort: { newSort in
                let stockPresenter = StockPresenter(
                    listView: viewAdapter,
                    connectionView: WeakRefVirtualProxy(viewAdapter)
                )
                stockPresenter.didReceive(viewAdapter.currentStocks, sortedBy: newSort)
            },
            onRowSelected: { symbol in
                viewAdapter.select(symbol: symbol)
            }
        )
        
        return view.onAppear {
            onFeedStartConfigured?(startFeed)
        }
    }
}
