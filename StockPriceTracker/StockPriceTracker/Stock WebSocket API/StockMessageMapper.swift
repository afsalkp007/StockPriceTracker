import Foundation

public enum StockMessageMapper {
    public struct StockPriceUpdate: Decodable {
        public let symbol: String
        public let price: Double
    }

    public enum Error: Swift.Error {
        case invalidMessage
    }

    public static func map(_ message: String) throws -> [StockPriceUpdate] {
        guard
            let data = message.data(using: .utf8),
            let updates = try? JSONDecoder().decode([StockPriceUpdate].self, from: data)
        else {
            throw Error.invalidMessage
        }
        return updates
    }
}
