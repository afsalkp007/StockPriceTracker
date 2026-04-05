import XCTest
import StockPriceTracker

final class StockPresentationLocalizationTests: XCTestCase {

    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        assertLocalizedKeyAndValuesExist(in: Bundle(for: StockPresenter.self), table: "StockPresentation")
    }
}
