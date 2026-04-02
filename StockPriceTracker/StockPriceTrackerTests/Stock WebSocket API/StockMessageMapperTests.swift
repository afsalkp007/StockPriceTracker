import XCTest
import StockPriceTracker

final class StockMessageMapperTests: XCTestCase {

    func test_map_throwsErrorOnInvalidJSON() throws {
        let invalidJSONList = ["", " ", "{", "{\"invalid\": 123}", "{\"symbol\": \"AAPL\"}", "{\"price\": 150.0}"]
        
        try invalidJSONList.forEach { invalidJSON in
            XCTAssertThrowsError(
                try StockMessageMapper.map(invalidJSON),
                "Expected to throw Error.invalidMessage for payload \(invalidJSON)"
            ) { error in
                XCTAssertEqual(error as? StockMessageMapper.Error, .invalidMessage)
            }
        }
    }
    
    func test_map_deliversStockPriceUpdateOnValidJSON() throws {
        let validJSON = "{\"symbol\": \"AAPL\", \"price\": 150.25}"
        
        let update = try StockMessageMapper.map(validJSON)
        
        XCTAssertEqual(update.symbol, "AAPL")
        XCTAssertEqual(update.price, 150.25)
    }
}
