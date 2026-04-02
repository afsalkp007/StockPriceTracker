import XCTest
import StockPriceTracker // Using @testable to test pure models

final class StockTests: XCTestCase {

    func test_priceChange_calculatesDifferenceCorrectly() {
        let sut = makeSUT(price: 150.0, previousPrice: 100.0)
        XCTAssertEqual(sut.priceChange, 50.0)
        
        let sutNegative = makeSUT(price: 80.0, previousPrice: 100.0)
        XCTAssertEqual(sutNegative.priceChange, -20.0)
    }
    
    func test_priceChangePercent_calculatesPercentageCorrectly() {
        let sut = makeSUT(price: 150.0, previousPrice: 100.0)
        XCTAssertEqual(sut.priceChangePercent, 50.0) // (50/100) * 100
        
        let sutNegative = makeSUT(price: 50.0, previousPrice: 100.0)
        XCTAssertEqual(sutNegative.priceChangePercent, -50.0) // (-50/100) * 100
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
    
    // MARK: - Helpers -
    
    private func makeSUT(price: Double, previousPrice: Double) -> Stock {
        Stock(
            symbol: "ANY",
            name: "Any Name",
            description: "Any description",
            price: price,
            previousPrice: previousPrice
        )
    }
}
