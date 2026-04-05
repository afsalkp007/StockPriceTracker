import XCTest
import StockPriceTracker

final class ConnectionStatusViewModelTests: XCTestCase {

    func test_connectedValues_areLocalized() {
        XCTAssertEqual(
            ConnectionStatusViewModel.connected.label,
            localizedPresentationString(forKey: "CONNECTION_STATUS_CONNECTED")
        )

        XCTAssertEqual(
            ConnectionStatusViewModel.connected.controlTitle,
            localizedPresentationString(forKey: "STOCK_LIST_CONTROL_STOP")
        )
    }

    func test_disconnectedValues_areLocalized() {
        XCTAssertEqual(
            ConnectionStatusViewModel.disconnected.label,
            localizedPresentationString(forKey: "CONNECTION_STATUS_DISCONNECTED")
        )

        XCTAssertEqual(
            ConnectionStatusViewModel.disconnected.controlTitle,
            localizedPresentationString(forKey: "STOCK_LIST_CONTROL_START")
        )
    }
}
