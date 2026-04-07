import XCTest
import StockPriceTracker

final class StockViewModelsTests: XCTestCase {

    func test_stockRowViewModel_idMatchesSymbol() {
        let sut = StockRowViewModel(
            symbol: "AAPL",
            name: "Apple",
            price: "$100.00",
            priceChange: "+$5.00 (5.00%)",
            isPositive: true
        )

        XCTAssertEqual(sut.id, "AAPL")
    }

    func test_stockListViewModel_initStoresRows() {
        let rows = [
            StockRowViewModel(
                symbol: "AAPL",
                name: "Apple",
                price: "$100.00",
                priceChange: "+$5.00 (5.00%)",
                isPositive: true
            ),
            StockRowViewModel(
                symbol: "TSLA",
                name: "Tesla",
                price: "$200.00",
                priceChange: "-$10.00 (5.00%)",
                isPositive: false
            )
        ]

        let sut = StockListViewModel(rows: rows)

        XCTAssertEqual(sut.rows, rows)
    }

    func test_stockDetailViewModel_initStoresValuesAndDefaultsHistoryToEmpty() {
        let sut = StockDetailViewModel(
            symbol: "AAPL",
            name: "Apple",
            price: "$100.00",
            priceChange: "+$5.00",
            priceChangePercent: "5.00%",
            isPositive: true,
            description: "Apple description"
        )

        XCTAssertEqual(sut.symbol, "AAPL")
        XCTAssertEqual(sut.name, "Apple")
        XCTAssertEqual(sut.price, "$100.00")
        XCTAssertEqual(sut.priceChange, "+$5.00")
        XCTAssertEqual(sut.priceChangePercent, "5.00%")
        XCTAssertTrue(sut.isPositive)
        XCTAssertEqual(sut.description, "Apple description")
        XCTAssertEqual(sut.history, [])
    }

    func test_stockDetailViewModel_initStoresCustomHistory() {
        let sut = StockDetailViewModel(
            symbol: "AAPL",
            name: "Apple",
            price: "$100.00",
            priceChange: "+$5.00",
            priceChangePercent: "5.00%",
            isPositive: true,
            description: "Apple description",
            history: [95, 100, 105]
        )

        XCTAssertEqual(sut.history, [95, 100, 105])
    }

    func test_connectionRetryAlertViewModel_initStoresValues() {
        let sut = ConnectionRetryAlertViewModel(
            title: "Connection Lost",
            message: "Socket disconnected.",
            retryActionTitle: "Retry",
            cancelActionTitle: "Cancel"
        )

        XCTAssertEqual(sut.title, "Connection Lost")
        XCTAssertEqual(sut.message, "Socket disconnected.")
        XCTAssertEqual(sut.retryActionTitle, "Retry")
        XCTAssertEqual(sut.cancelActionTitle, "Cancel")
    }
}
