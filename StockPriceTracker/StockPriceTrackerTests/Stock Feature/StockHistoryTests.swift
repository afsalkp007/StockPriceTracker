import XCTest
import StockPriceTracker

// MARK: - StockHistoryTests -

/// Tests that the `Stock` domain model correctly seeds and tracks price history.
final class StockHistoryTests: XCTestCase {

    func test_init_seedsHistoryWithInitialPrice() {
        let stock = makeStock(symbol: "AAPL", price: 150)

        XCTAssertEqual(stock.history, [150], "Expected history to be seeded with the initial price on init")
    }

    func test_history_isIndependentPerStock() {
        let stockA = makeStock(symbol: "AAPL", price: 100)
        let stockB = makeStock(symbol: "GOOG", price: 200)

        XCTAssertEqual(stockA.history, [100])
        XCTAssertEqual(stockB.history, [200])
        XCTAssertNotEqual(stockA.history, stockB.history)
    }

    func test_appendingToHistory_doesNotMutateOtherStock() {
        var stockA = makeStock(symbol: "AAPL", price: 100)
        let stockB = makeStock(symbol: "GOOG", price: 200)

        stockA.history.append(105)

        XCTAssertEqual(stockA.history, [100, 105])
        XCTAssertEqual(stockB.history, [200], "Stock B history must remain unaffected")
    }

    // MARK: - Helpers -

    private func makeStock(symbol: String, price: Double) -> Stock {
        Stock(symbol: symbol, name: "\(symbol) Inc.", description: "Description", price: price, previousPrice: price)
    }
}
