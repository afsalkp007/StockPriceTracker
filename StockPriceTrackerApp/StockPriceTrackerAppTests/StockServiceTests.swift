import XCTest
import StockPriceTracker
import StockPriceTrackerApp

@MainActor
final class StockServiceTests: XCTestCase {
    func test_makeFeedLoader_usesInjectedFeedLoader() {
        let (sut, feed) = makeSUT()

        _ = sut.makeFeedLoader()()

        XCTAssertEqual(feed.startFeedCallCount, 1)
    }

    func test_feedController_usesInjectedFeedController() async {
        let (sut, feed) = makeSUT()

        let controller = sut.feedController()
        controller.start()
        await controller.stop()

        XCTAssertEqual(feed.startCallCount, 1)
        XCTAssertEqual(feed.stopCallCount, 1)
    }

    private func makeSUT(
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: StockService, feed: StockFeedSpy) {
        let feed = StockFeedSpy()
        let sut = StockService(stockFeed: feed)
        return (sut, feed)
    }

    private final class StockFeedSpy: StockFeedLoader, StockFeedController {
        private(set) var startFeedCallCount = 0
        private(set) var startCallCount = 0
        private(set) var stopCallCount = 0
        private let stream = AsyncThrowingStream<[Stock], Error> { _ in }

        func startFeed() -> AsyncThrowingStream<[Stock], Error> {
            startFeedCallCount += 1
            return stream
        }

        func start() {
            startCallCount += 1
        }

        func stop() async {
            stopCallCount += 1
        }
    }
}
