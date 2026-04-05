import SwiftUI
import Combine
import StockPriceTracker
import StockPriceTrackeriOS

@MainActor
public final class StockDetailUIComposer {
    private init() {}
    
    public static func stockDetailComposedWith(
        stock: Stock,
        stockUpdates: AnyPublisher<[Stock], Never>,
        connectionStatus: AnyPublisher<ConnectionStatusViewModel, Never> = Just(.connected).eraseToAnyPublisher(),
        onRetryConnection: @escaping () -> Void = {},
        stateStore: StockDetailStateStore? = nil
    ) -> some View {
        let stateStore = stateStore ?? StockDetailStateStore()
        let viewAdapter = StockDetailViewAdapter(stateStore: stateStore)
        let presenter = StockDetailPresenter(detailView: viewAdapter)
        presenter.didReceive(stock)
        
        return ComposedStockDetailView(
            stock: stock,
            presenter: presenter,
            stateStore: stateStore,
            stockUpdates: stockUpdates,
            connectionStatus: connectionStatus,
            onRetryConnection: onRetryConnection
        )
    }
}

private struct ComposedStockDetailView: View {
    let stock: Stock
    let presenter: StockDetailPresenter
    @ObservedObject var stateStore: StockDetailStateStore
    let stockUpdates: AnyPublisher<[Stock], Never>
    let connectionStatus: AnyPublisher<ConnectionStatusViewModel, Never>
    let onRetryConnection: () -> Void

    @State private var lastConnectionStatus = ConnectionStatusViewModel.disconnected

    var body: some View {
        StockDetailView(
            stateStore: stateStore,
            onRetryConnection: onRetryConnection
        )
            .onReceive(stockUpdates.receive(on: DispatchQueue.main)) { stocks in
                if let updatedStock = stocks.first(where: { $0.symbol == stock.symbol }) {
                    presenter.didReceive(updatedStock)
                }
            }
            .onReceive(connectionStatus.removeDuplicates().receive(on: DispatchQueue.main)) { status in
                let shouldShowRetryAlert = !status.isConnected && lastConnectionStatus.isConnected
                lastConnectionStatus = status

                DispatchQueue.main.async {
                    if status.isConnected {
                        stateStore.connectionRetryAlert = nil
                    } else if shouldShowRetryAlert {
                        stateStore.connectionRetryAlert = StockDetailPresenter.connectionRetryAlert
                    }
                }
            }
    }
}
