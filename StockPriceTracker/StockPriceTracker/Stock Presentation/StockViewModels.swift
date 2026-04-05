import Foundation

public struct StockRowViewModel: Identifiable, Equatable {
    public var id: String { symbol }
    public let symbol: String
    public let name: String
    public let price: String
    public let priceChange: String
    public let isPositive: Bool

    public init(symbol: String, name: String, price: String, priceChange: String, isPositive: Bool) {
        self.symbol = symbol
        self.name = name
        self.price = price
        self.priceChange = priceChange
        self.isPositive = isPositive
    }
}

public struct StockListViewModel: Equatable {
    public let rows: [StockRowViewModel]

    public init(rows: [StockRowViewModel]) {
        self.rows = rows
    }
}

public struct StockDetailViewModel: Equatable {
    public let symbol: String
    public let name: String
    public let price: String
    public let priceChange: String
    public let priceChangePercent: String
    public let isPositive: Bool
    public let description: String
    public let history: [Double]

    public init(symbol: String, name: String, price: String, priceChange: String, priceChangePercent: String, isPositive: Bool, description: String, history: [Double] = []) {
        self.symbol = symbol
        self.name = name
        self.price = price
        self.priceChange = priceChange
        self.priceChangePercent = priceChangePercent
        self.isPositive = isPositive
        self.description = description
        self.history = history
    }
}

public struct ConnectionStatusViewModel: Equatable {
    public let isConnected: Bool
    public let label: String
    public let controlTitle: String

    public static var connected: ConnectionStatusViewModel {
        ConnectionStatusViewModel(
            isConnected: true,
            label: Localized.connected,
            controlTitle: Localized.stopControlTitle
        )
    }

    public static var disconnected: ConnectionStatusViewModel {
        ConnectionStatusViewModel(
            isConnected: false,
            label: Localized.disconnected,
            controlTitle: Localized.startControlTitle
        )
    }

    private init(isConnected: Bool, label: String, controlTitle: String) {
        self.isConnected = isConnected
        self.label = label
        self.controlTitle = controlTitle
    }
}

private enum Localized {
    static var connected: String {
        localized("CONNECTION_STATUS_CONNECTED")
    }

    static var disconnected: String {
        localized("CONNECTION_STATUS_DISCONNECTED")
    }

    static var startControlTitle: String {
        localized("STOCK_LIST_CONTROL_START")
    }

    static var stopControlTitle: String {
        localized("STOCK_LIST_CONTROL_STOP")
    }

    private static func localized(_ key: String) -> String {
        NSLocalizedString(
            key,
            tableName: "StockPresentation",
            bundle: Bundle(for: BundleToken.self),
            comment: ""
        )
    }

    private final class BundleToken {}
}
