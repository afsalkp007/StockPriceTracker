import XCTest
import SwiftUI
import StockPriceTracker
import StockPriceTrackeriOS

@MainActor
final class StockListViewSnapshotTests: XCTestCase {
    private let isRecording = false

    func test_listWithContent() {
        let sut = makeSUT(configure: { stateStore in
            stateStore.connectionViewModel = .connected
            stateStore.listViewModel = StockListViewModel(rows: [
                StockRowViewModel(
                    symbol: "AAPL",
                    name: "Apple Inc.",
                    price: "$182.45",
                    priceChange: "+$4.25 (2.39%)",
                    isPositive: true
                ),
                StockRowViewModel(
                    symbol: "TSLA",
                    name: "Tesla Inc.",
                    price: "$167.20",
                    priceChange: "-$8.10 (4.62%)",
                    isPositive: false
                ),
                StockRowViewModel(
                    symbol: "NVDA",
                    name: "NVIDIA Corp.",
                    price: "$910.12",
                    priceChange: "+$21.44 (2.41%)",
                    isPositive: true
                )
            ])
        })

        verify(snapshot: sut.snapshot(for: .iPhone(style: .light)), named: "STOCK_LIST_WITH_CONTENT_light", record: isRecording)
        verify(snapshot: sut.snapshot(for: .iPhone(style: .dark)), named: "STOCK_LIST_WITH_CONTENT_dark", record: isRecording)
        verify(
            snapshot: sut.snapshot(for: .iPhone(style: .light, contentSize: .extraExtraExtraLarge)),
            named: "STOCK_LIST_WITH_CONTENT_light_extraExtraExtraLarge",
            record: isRecording
        )
    }

    func test_loadingList() {
        let sut = makeSUT(configure: { stateStore in
            stateStore.connectionViewModel = .disconnected
            stateStore.isLoading = true
        })

        verify(snapshot: sut.snapshot(for: .iPhone(style: .light)), named: "STOCK_LIST_LOADING_light", record: isRecording)
        verify(snapshot: sut.snapshot(for: .iPhone(style: .dark)), named: "STOCK_LIST_LOADING_dark", record: isRecording)
    }

    func test_listWithErrorMessage() {
        let sut = makeSUT(configure: { stateStore in
            stateStore.errorMessage = "Unable to load live prices.\nPlease try again."
        })

        verify(snapshot: sut.snapshot(for: .iPhone(style: .light)), named: "STOCK_LIST_WITH_ERROR_light", record: isRecording)
        verify(snapshot: sut.snapshot(for: .iPhone(style: .dark)), named: "STOCK_LIST_WITH_ERROR_dark", record: isRecording)
        verify(
            snapshot: sut.snapshot(for: .iPhone(style: .light, contentSize: .extraExtraExtraLarge)),
            named: "STOCK_LIST_WITH_ERROR_light_extraExtraExtraLarge",
            record: isRecording
        )
    }

    private func makeSUT(
        configure: (StockListStateStore) -> Void
    ) -> some View {
        let stateStore = StockListStateStore()
        configure(stateStore)

        return NavigationStack {
            StockListView(
                stateStore: stateStore,
                onStart: {},
                onStop: {},
                onSort: { _ in },
                onRowSelected: { _ in }
            )
        }
    }
}
