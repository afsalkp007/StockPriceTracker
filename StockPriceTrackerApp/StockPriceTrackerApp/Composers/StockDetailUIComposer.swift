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
    @State private var showsConnectionRetryAlert = false

    var body: some View {
        StockDetailView(stateStore: stateStore)
            .alert("Connection Lost", isPresented: $showsConnectionRetryAlert) {
                Button("Retry") {
                    showsConnectionRetryAlert = false
                    onRetryConnection()
                }
                Button("Cancel", role: .cancel) {
                    showsConnectionRetryAlert = false
                }
            } message: {
                Text("Live updates stopped because the socket disconnected.")
            }
            .onReceive(stockUpdates.receive(on: DispatchQueue.main)) { stocks in
                if let updatedStock = stocks.first(where: { $0.symbol == stock.symbol }) {
                    presenter.didReceive(updatedStock)
                }
            }
            .onReceive(connectionStatus.removeDuplicates().receive(on: DispatchQueue.main)) { status in
                if status.isConnected {
                    showsConnectionRetryAlert = false
                } else if lastConnectionStatus.isConnected {
                    showsConnectionRetryAlert = true
                }

                lastConnectionStatus = status
            }
    }
}
