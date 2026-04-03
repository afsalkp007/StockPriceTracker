import XCTest
import StockPriceTracker

final class StockTests: XCTestCase {

    func test_init_setsStoredProperties() {
        let sut = makeSUT(
            symbol: "AAPL",
            name: "Apple Inc.",
            description: "Apple description",
            price: 150.0,
            previousPrice: 140.0
        )

        XCTAssertEqual(sut.symbol, "AAPL")
        XCTAssertEqual(sut.name, "Apple Inc.")
        XCTAssertEqual(sut.description, "Apple description")
        XCTAssertEqual(sut.price, 150.0)
        XCTAssertEqual(sut.previousPrice, 140.0)
    }

    func test_init_seedsHistoryWithCurrentPrice() {
        let sut = makeSUT(price: 150.0, previousPrice: 140.0)

        XCTAssertEqual(sut.history, [150.0])
    }

    func test_priceChange_calculatesDifferenceCorrectly() {
        let sut = makeSUT(price: 150.0, previousPrice: 100.0)
        XCTAssertEqual(sut.priceChange, 50.0)
        
        let sutNegative = makeSUT(price: 80.0, previousPrice: 100.0)
        XCTAssertEqual(sutNegative.priceChange, -20.0)
    }

    func test_priceChange_updatesWhenPriceAndPreviousPriceChange() {
        var sut = makeSUT(price: 150.0, previousPrice: 100.0)

        sut.previousPrice = 150.0
        sut.price = 155.5

        XCTAssertEqual(sut.priceChange, 5.5)
    }
    
    func test_priceChangePercent_calculatesPercentageCorrectly() {
        let sut = makeSUT(price: 150.0, previousPrice: 100.0)
        XCTAssertEqual(sut.priceChangePercent, 50.0) // (50/100) * 100
        
        let sutNegative = makeSUT(price: 50.0, previousPrice: 100.0)
        XCTAssertEqual(sutNegative.priceChangePercent, -50.0) // (-50/100) * 100
    }

    func test_priceChangePercent_calculatesFractionalPercentageCorrectly() {
        let sut = makeSUT(price: 105.5, previousPrice: 100.0)

        XCTAssertEqual(sut.priceChangePercent, 5.5)
    }
    
    func test_priceChangePercent_returnsZeroWhenPreviousPriceIsZero() {
        let sut = makeSUT(price: 150.0, previousPrice: 0.0)
        XCTAssertEqual(sut.priceChangePercent, 0.0)
    }
    
    func test_isPositive_returnsTrueForGainOrStable() {
        XCTAssertTrue(makeSUT(price: 101.0, previousPrice: 100.0).isPositive, "Expected true for price increase")
        XCTAssertTrue(makeSUT(price: 100.0, previousPrice: 100.0).isPositive, "Expected true for price stable")
    }
    
    func test_isPositive_returnsFalseForLoss() {
        XCTAssertFalse(makeSUT(price: 99.0, previousPrice: 100.0).isPositive, "Expected false for price decrease")
    }
    
    private func makeSUT(
        symbol: String = "ANY",
        name: String = "Any Name",
        description: String = "Any description",
        price: Double,
        previousPrice: Double
    ) -> Stock {
        Stock(
            symbol: symbol,
            name: name,
            description: description,
            price: price,
            previousPrice: previousPrice
        )
    }
}
