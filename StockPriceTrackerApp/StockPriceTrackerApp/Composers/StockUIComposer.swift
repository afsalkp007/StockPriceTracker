import SwiftUI
import StockPriceTracker
import StockPriceTrackeriOS

@MainActor
public final class StockUIComposer {
    private init() {}
    
    public static func stockListComposedWith(
        feedLoader: @escaping () -> AsyncThrowingStream<[Stock], Error>,
        feedController: StockFeedController,
        selection: @escaping (Stock) -> Void
    ) -> some View {
        let stateStore = StockListStateStore()
        let presentationAdapter = StockFeedPresentationAdapter(loader: feedLoader)
        let viewAdapter = StockViewAdapter(stateStore: stateStore, selection: selection)
        
        let presenter = LoadResourcePresenter(
            resourceView: viewAdapter,
            loadingView: WeakRefVirtualProxy(stateStore),
            errorView: WeakRefVirtualProxy(stateStore),
            mapper: { stocks in
                let stockPresenter = StockPresenter(
                    listView: viewAdapter,
                    connectionView: WeakRefVirtualProxy(stateStore)
                )
                // Default sorting option applied here; StockPresenter does the mapping
                stockPresenter.didReceive(stocks, sortedBy: stateStore.currentSort)
                // Returning a dummy wrapper since StockPresenter handled the direct display
                // (Alternatively, StockPresenter itself mapping `-> StockListViewModel` can be passed)
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
                presentationAdapter.didCancelFeedLoad()
                feedController.stop()
            },
            onSort: { newSort in
                // TODO
            },
            onRowSelected: { symbol in
                // TODO
            }
        )
        
        return view
    }
}
