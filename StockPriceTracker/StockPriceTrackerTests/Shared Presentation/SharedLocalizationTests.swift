import XCTest
import StockPriceTracker

final class SharedLocalizationTests: XCTestCase {

    func test_localizedStrings_haveKeysAndValuesForAllSupportedLocalizations() {
        assertLocalizedKeyAndValuesExist(
            in: Bundle(for: LoadResourcePresenter<String, DummyView>.self),
            table: "Shared"
        )
    }

    private final class DummyView: ResourceView {
        func display(_ viewModel: String) {}
    }
}
