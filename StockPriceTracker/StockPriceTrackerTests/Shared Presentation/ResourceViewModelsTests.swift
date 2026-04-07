import XCTest
import StockPriceTracker

final class ResourceViewModelsTests: XCTestCase {

    func test_noError_createsViewModelWithNilMessage() {
        let sut = ResourceErrorViewModel.noError

        XCTAssertNil(sut.message)
    }

    func test_error_createsViewModelWithMessage() {
        let sut = ResourceErrorViewModel.error(message: "any message")

        XCTAssertEqual(sut.message, "any message")
    }

    func test_init_storesLoadingState() {
        XCTAssertTrue(ResourceLoadingViewModel(isLoading: true).isLoading)
        XCTAssertFalse(ResourceLoadingViewModel(isLoading: false).isLoading)
    }
}
