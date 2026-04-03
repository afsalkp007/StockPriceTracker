import XCTest
import StockPriceTracker

final class StockMessageMapperTests: XCTestCase {

    func test_map_throwsErrorOnInvalidJSON() throws {
        let invalidJSONList = ["", " ", "{", "{\"symbol\": \"AAPL\", \"price\": 150.0}", "[{\"invalid\": 123}]", "[{\"symbol\": \"AAPL\"}]", "[{\"price\": 150.0}]"]
        
        try invalidJSONList.forEach { invalidJSON in
            XCTAssertThrowsError(
                try StockMessageMapper.map(invalidJSON),
                "Expected to throw Error.invalidMessage for payload \(invalidJSON)"
            ) { error in
                XCTAssertEqual(error as? StockMessageMapper.Error, .invalidMessage)
            }
        }
    }
    
    func test_map_deliversStockPriceUpdateOnValidJSONArray() throws {
        let validJSON = "[{\"symbol\": \"AAPL\", \"price\": 150.25}, {\"symbol\": \"GOOG\", \"price\": 200.0}]"
        
        let updates = try StockMessageMapper.map(validJSON)
        
        XCTAssertEqual(updates.count, 2)
        XCTAssertEqual(updates[0].symbol, "AAPL")
        XCTAssertEqual(updates[0].price, 150.25)
        XCTAssertEqual(updates[1].symbol, "GOOG")
        XCTAssertEqual(updates[1].price, 200.0)
    }
}
