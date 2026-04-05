import XCTest
import StockPriceTracker

final class ConnectionStatusViewModelTests: XCTestCase {

    func test_connectedLabel_isLocalized() {
        XCTAssertEqual(
            ConnectionStatusViewModel.connected.label,
            localizedString(
                forKey: "CONNECTION_STATUS_CONNECTED",
                table: "StockPresentation",
                bundle: Bundle(for: StockPresenter.self)
            )
        )
    }

    func test_disconnectedLabel_isLocalized() {
        XCTAssertEqual(
            ConnectionStatusViewModel.disconnected.label,
            localizedString(
                forKey: "CONNECTION_STATUS_DISCONNECTED",
                table: "StockPresentation",
                bundle: Bundle(for: StockPresenter.self)
            )
        )
    }
}
