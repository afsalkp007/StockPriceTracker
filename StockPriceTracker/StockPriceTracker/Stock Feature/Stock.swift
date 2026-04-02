import Foundation

public struct Stock: Hashable, Sendable {
    public let symbol: String
    public let name: String
    public let description: String
    public var price: Double
    public var previousPrice: Double

    public init(
        symbol: String,
        name: String,
        description: String,
        price: Double,
        previousPrice: Double
    ) {
        self.symbol = symbol
        self.name = name
        self.description = description
        self.price = price
        self.previousPrice = previousPrice
    }

    public var priceChange: Double {
        price - previousPrice
    }

    public var priceChangePercent: Double {
        guard previousPrice != 0 else { return 0 }
        return (priceChange / previousPrice) * 100
    }

    public var isPositive: Bool {
        priceChange >= 0
    }
}
