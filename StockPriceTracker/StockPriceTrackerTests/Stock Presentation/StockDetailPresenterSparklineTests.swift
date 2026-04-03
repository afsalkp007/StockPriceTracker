import XCTest
import StockPriceTracker

// MARK: - StockDetailPresenterSparklineTests -

/// Tests that `StockDetailPresenter` correctly maps `Stock.history` into the Detail ViewModel.
@MainActor
final class StockDetailPresenterSparklineTests: XCTestCase {

    func test_didReceive_mapsHistoryIntoDetailViewModel() {
        let (sut, view) = makeSUT()
        var stock = makeStock(symbol: "AAPL", price: 150)
        stock.history = [140, 145, 150]

        sut.didReceive(stock)

        XCTAssertEqual(view.lastViewModel?.history, [140, 145, 150], "Expected presenter to map full stock history to the view model")
    }

    func test_didReceive_mapsEmptyHistoryIntoDetailViewModel() {
        let (sut, view) = makeSUT()
        var stock = makeStock(symbol: "AAPL", price: 150)
        stock.history = []

        sut.didReceive(stock)

        XCTAssertEqual(view.lastViewModel?.history, [], "Expected presenter to pass empty history through without crashing")
    }

    func test_didReceive_preservesHistoryOrder() {
        let (sut, view) = makeSUT()
        var stock = makeStock(symbol: "AAPL", price: 150)
        stock.history = [150, 145, 160, 155]

        sut.didReceive(stock)

        XCTAssertEqual(view.lastViewModel?.history, [150, 145, 160, 155])
    }

    func test_didReceive_preservesDuplicateHistoryValues() {
        let (sut, view) = makeSUT()
        var stock = makeStock(symbol: "AAPL", price: 150)
        stock.history = [150, 150, 151, 151, 150]

        sut.didReceive(stock)

        XCTAssertEqual(view.lastViewModel?.history, [150, 150, 151, 151, 150])
    }

    func test_didReceive_updatesHistoryOnEachNewTick() {
        let (sut, view) = makeSUT()
        var stock = makeStock(symbol: "AAPL", price: 150)
        stock.history = [150]

        sut.didReceive(stock)
        XCTAssertEqual(view.lastViewModel?.history, [150])

        stock.history.append(155)
        stock.price = 155
        sut.didReceive(stock)

        XCTAssertEqual(view.lastViewModel?.history, [150, 155], "Expected history to grow with each new price tick")
    }

    func test_didReceive_slidingWindowOf30_dropsOldestPriceWhenFull() {
        let (sut, view) = makeSUT()
        var stock = makeStock(symbol: "AAPL", price: 100)
        // Simulate a full 30-point history window
        stock.history = Array(1...30).map { Double($0) }

        sut.didReceive(stock)
        XCTAssertEqual(view.lastViewModel?.history.count, 30)
        XCTAssertEqual(view.lastViewModel?.history.first, 1.0)

        // Simulate 31st tick — oldest should have been dropped by the loader
        stock.history = Array(2...31).map { Double($0) }
        sut.didReceive(stock)

        XCTAssertEqual(view.lastViewModel?.history.count, 30, "Expected a maximum of 30 history points")
        XCTAssertEqual(view.lastViewModel?.history.first, 2.0, "Expected oldest price (1.0) to have been dropped")
        XCTAssertEqual(view.lastViewModel?.history.last, 31.0)
    }

    func test_didReceive_replacesHistoryWithLatestPayload() {
        let (sut, view) = makeSUT()
        var stock = makeStock(symbol: "AAPL", price: 150)
        stock.history = [140, 145, 150]

        sut.didReceive(stock)
        XCTAssertEqual(view.lastViewModel?.history, [140, 145, 150])

        stock.history = [148, 149, 151]
        sut.didReceive(stock)

        XCTAssertEqual(view.lastViewModel?.history, [148, 149, 151])
    }

    // MARK: - Helpers -

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: StockDetailPresenter, view: DetailViewSpy) {
        let view = DetailViewSpy()
        let sut = StockDetailPresenter(detailView: view, locale: Locale(identifier: "en_US"))
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }

    private func makeStock(symbol: String, price: Double) -> Stock {
        Stock(symbol: symbol, name: "\(symbol) Inc.", description: "Description", price: price, previousPrice: price)
    }

    private class DetailViewSpy: ResourceView {
        typealias ResourceViewModel = StockDetailViewModel

        private(set) var lastViewModel: StockDetailViewModel?

        func display(_ viewModel: StockDetailViewModel) {
            lastViewModel = viewModel
        }
    }
}
