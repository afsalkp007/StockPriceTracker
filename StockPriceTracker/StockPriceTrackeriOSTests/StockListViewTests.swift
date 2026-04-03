import SwiftUI
import XCTest
@testable import StockPriceTrackeriOS

@MainActor
final class StockListViewTests: XCTestCase {

    func test_handleScenePhaseChange_toBackground_stopsFeed() {
        let stateStore = StockListStateStore()
        var stopCallCount = 0

        let sut = StockListView(
            stateStore: stateStore,
            onStart: {},
            onStop: { stopCallCount += 1 },
            onSort: { _ in },
            onRowSelected: { _ in }
        )

        sut.handleScenePhaseChange(.background)

        XCTAssertEqual(stopCallCount, 1)
    }

    func test_handleScenePhaseChange_toActive_startsFeed() {
        let stateStore = StockListStateStore()
        var startCallCount = 0

        let sut = StockListView(
            stateStore: stateStore,
            onStart: { startCallCount += 1 },
            onStop: {},
            onSort: { _ in },
            onRowSelected: { _ in }
        )

        sut.handleScenePhaseChange(.active)

        XCTAssertEqual(startCallCount, 1)
    }

    func test_handleScenePhaseChange_toInactive_doesNotStartOrStopFeed() {
        let stateStore = StockListStateStore()
        var startCallCount = 0
        var stopCallCount = 0

        let sut = StockListView(
            stateStore: stateStore,
            onStart: { startCallCount += 1 },
            onStop: { stopCallCount += 1 },
            onSort: { _ in },
            onRowSelected: { _ in }
        )

        sut.handleScenePhaseChange(.inactive)

        XCTAssertEqual(startCallCount, 0)
        XCTAssertEqual(stopCallCount, 0)
    }
}
