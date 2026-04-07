import XCTest
import SwiftUI
import StockPriceTracker
import StockPriceTrackeriOS

@MainActor
final class StockDetailViewSnapshotTests: XCTestCase {
    private let isRecording = false

    func test_detailWithContent() {
        let sut = makeSUT { stateStore in
            stateStore.viewModel = StockDetailViewModel(
                symbol: "AAPL",
                name: "Apple Inc.",
                price: "$182.45",
                priceChange: "+$4.25",
                priceChangePercent: "2.39%",
                isPositive: true,
                description: "Designs and sells consumer electronics, software, and online services including iPhone, Mac, and App Store.",
                history: [168, 171, 169, 175, 178, 176, 182]
            )
        }

        verify(snapshot: sut.snapshot(for: .iPhone(style: .light)), named: "STOCK_DETAIL_WITH_CONTENT_light", record: isRecording)
        verify(snapshot: sut.snapshot(for: .iPhone(style: .dark)), named: "STOCK_DETAIL_WITH_CONTENT_dark", record: isRecording)
        verify(
            snapshot: sut.snapshot(for: .iPhone(style: .light, contentSize: .extraExtraExtraLarge)),
            named: "STOCK_DETAIL_WITH_CONTENT_light_extraExtraExtraLarge",
            record: isRecording
        )
    }

    func test_detailWithLoadingShimmer() {
        let sut = makeSUT { stateStore in
            stateStore.isLoading = true
        }

        verify(snapshot: sut.snapshot(for: .iPhone(style: .light)), named: "STOCK_DETAIL_LOADING_light", record: isRecording)
        verify(snapshot: sut.snapshot(for: .iPhone(style: .dark)), named: "STOCK_DETAIL_LOADING_dark", record: isRecording)
    }

    private func makeSUT(
        configure: (StockDetailStateStore) -> Void
    ) -> some View {
        let stateStore = StockDetailStateStore()
        configure(stateStore)

        return NavigationStack {
            StockDetailView(
                stateStore: stateStore,
                onRetryConnection: {}
            )
        }
    }
}
