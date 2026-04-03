import XCTest
import StockPriceTracker

@MainActor
final class LoadResourcePresenterTests: XCTestCase {

    func test_init_doesNotSendMessagesToView() {
        let (_, view) = makeSUT()

        XCTAssertTrue(view.messages.isEmpty)
    }

    func test_didStartLoading_displaysNoErrorMessageAndStartsLoading() {
        let (sut, view) = makeSUT()

        sut.didStartLoading()

        XCTAssertEqual(view.messages, [
            .displayErrorMessage(nil),
            .displayLoading(true)
        ])
    }

    func test_didFinishLoading_displaysMappedResourceAndStopsLoading() {
        let (sut, view) = makeSUT(mapper: { resource in
            "\(resource) view model"
        })

        sut.didFinishLoading(with: "resource")

        XCTAssertEqual(view.messages, [
            .displayResource("resource view model"),
            .displayLoading(false)
        ])
    }

    func test_didFinishLoading_withoutMapper_displaysResourceAndStopsLoading() {
        let (sut, view) = makeIdentitySUT()

        sut.didFinishLoading(with: "resource")

        XCTAssertEqual(view.messages, [
            .displayResource("resource"),
            .displayLoading(false)
        ])
    }

    func test_didFinishLoadingWithMapperError_displaysErrorMessageAndStopsLoading() {
        let error = anyNSError()

        let (sut, view) = makeSUT(mapper: { _ in
            throw error
        })

        sut.didFinishLoading(with: "resource")

        XCTAssertEqual(view.messages, [
            .displayErrorMessage(anyNSError().localizedDescription),
            .displayLoading(false)
        ])
    }

    func test_didFinishLoadingWithError_displaysErrorMessageAndStopsLoading() {
        let (sut, view) = makeSUT()

        sut.didFinishLoading(with: anyNSError())

        XCTAssertEqual(view.messages, [
            .displayErrorMessage(anyNSError().localizedDescription),
            .displayLoading(false)
        ])
    }

    private typealias SUT = LoadResourcePresenter<String, ViewSpy>
    private typealias IdentitySUT = LoadResourcePresenter<String, ViewSpy>

    private func makeSUT(
        mapper: @escaping SUT.Mapper = { _ in "any" },
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: SUT, view: ViewSpy) {
        let view = ViewSpy()
        let sut = SUT(resourceView: view, loadingView: view, errorView: view, mapper: mapper)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }

    private func makeIdentitySUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: IdentitySUT, view: ViewSpy) {
        let view = ViewSpy()
        let sut = IdentitySUT(resourceView: view, loadingView: view, errorView: view)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }

    private final class ViewSpy: ResourceView, ResourceLoadingView, ResourceErrorView {
        typealias ResourceViewModel = String

        enum Message: Equatable {
            case displayErrorMessage(String?)
            case displayLoading(Bool)
            case displayResource(String)
        }

        private(set) var messages = [Message]()

        func display(_ viewModel: String) {
            messages.append(.displayResource(viewModel))
        }

        func display(_ viewModel: ResourceLoadingViewModel) {
            messages.append(.displayLoading(viewModel.isLoading))
        }

        func display(_ viewModel: ResourceErrorViewModel) {
            messages.append(.displayErrorMessage(viewModel.message))
        }
    }
}
