import XCTest
import StockPriceTracker

@MainActor
final class StockDetailPresenterTests: XCTestCase {

    func test_staticTitles_areLocalized() {
        XCTAssertEqual(
            StockDetailPresenter.priceHistoryTitle,
            localizedPresentationString(forKey: "STOCK_DETAIL_PRICE_HISTORY")
        )

        XCTAssertEqual(
            StockDetailPresenter.aboutTitle,
            localizedPresentationString(forKey: "STOCK_DETAIL_ABOUT")
        )
    }

    func test_lastTicksTitle_isLocalized() {
        XCTAssertEqual(
            StockDetailPresenter.lastTicksTitle(1),
            localizedPresentationStringWithFormat("STOCK_DETAIL_LAST_SINGLE_TICK", 1)
        )

        XCTAssertEqual(
            StockDetailPresenter.lastTicksTitle(3),
            localizedPresentationStringWithFormat("STOCK_DETAIL_LAST_MULTIPLE_TICKS", 3)
        )
    }

    func test_connectionRetryAlert_isLocalized() {
        XCTAssertEqual(
            StockDetailPresenter.connectionRetryAlert,
            ConnectionRetryAlertViewModel(
                title: localizedPresentationString(forKey: "STOCK_DETAIL_CONNECTION_RETRY_ALERT_TITLE"),
                message: localizedPresentationString(forKey: "STOCK_DETAIL_CONNECTION_RETRY_ALERT_MESSAGE"),
                retryActionTitle: localizedPresentationString(forKey: "STOCK_DETAIL_CONNECTION_RETRY_ACTION"),
                cancelActionTitle: localizedPresentationString(forKey: "STOCK_DETAIL_CONNECTION_CANCEL_ACTION")
            )
        )
    }

    func test_didReceive_mapsStockDetailsToViewModel() {
        let (sut, view) = makeSUT()
        let stock = makeStock(
            symbol: "AAPL",
            name: "Apple",
            description: "Apple description",
            price: 110,
            previousPrice: 100,
            history: [95, 100, 110]
        )

        sut.didReceive(stock)

        XCTAssertEqual(view.receivedViewModels, [
            StockDetailViewModel(
                symbol: "AAPL",
                name: "Apple",
                price: "$110.00",
                priceChange: "+$10.00",
                priceChangePercent: "10.00%",
                isPositive: true,
                description: "Apple description",
                history: [95, 100, 110]
            )
        ])
    }

    func test_didReceive_formatsNegativePriceChange() {
        let (sut, view) = makeSUT()
        let stock = makeStock(
            symbol: "AAPL",
            name: "Apple",
            description: "Apple description",
            price: 80,
            previousPrice: 100
        )

        sut.didReceive(stock)

        XCTAssertEqual(view.receivedViewModels.last?.priceChange, "-$20.00")
        XCTAssertEqual(view.receivedViewModels.last?.priceChangePercent, "20.00%")
        XCTAssertEqual(view.receivedViewModels.last?.isPositive, false)
    }

    func test_didReceive_usesZeroPercentWhenPreviousPriceIsZero() {
        let (sut, view) = makeSUT()
        let stock = makeStock(
            symbol: "AAPL",
            name: "Apple",
            description: "Apple description",
            price: 10,
            previousPrice: 0
        )

        sut.didReceive(stock)

        XCTAssertEqual(view.receivedViewModels.last?.priceChange, "+$10.00")
        XCTAssertEqual(view.receivedViewModels.last?.priceChangePercent, "0.00%")
    }

    func test_didReceive_formatsValuesUsingLocale() {
        let (sut, view) = makeSUT(locale: Locale(identifier: "pt_BR"))
        let stock = makeStock(
            symbol: "AAPL",
            name: "Apple",
            description: "Apple description",
            price: 1234.56,
            previousPrice: 1200.00
        )

        sut.didReceive(stock)

        XCTAssertEqual(view.receivedViewModels.last?.price, "US$ 1.234,56")
        XCTAssertEqual(view.receivedViewModels.last?.priceChange, "+US$ 34,56")
        XCTAssertEqual(view.receivedViewModels.last?.priceChangePercent, "2,88%")
    }

    private func makeSUT(
        locale: Locale = Locale(identifier: "en_US"),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: StockDetailPresenter, view: DetailViewSpy) {
        let view = DetailViewSpy()
        let sut = StockDetailPresenter(detailView: view, locale: locale)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }

    private func makeStock(
        symbol: String,
        name: String,
        description: String,
        price: Double,
        previousPrice: Double,
        history: [Double] = []
    ) -> Stock {
        var stock = Stock(
            symbol: symbol,
            name: name,
            description: description,
            price: price,
            previousPrice: previousPrice
        )
        stock.history = history
        return stock
    }

    private final class DetailViewSpy: ResourceView {
        typealias ResourceViewModel = StockDetailViewModel

        private(set) var receivedViewModels = [StockDetailViewModel]()

        func display(_ viewModel: StockDetailViewModel) {
            receivedViewModels.append(viewModel)
        }
    }
}
