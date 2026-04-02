import Foundation

public struct StockRowViewModel: Identifiable, Equatable {
    public var id: String { symbol }
    public let symbol: String
    public let name: String
    public let price: String
    public let priceChange: String
    public let isPositive: Bool
}

public struct StockListViewModel: Equatable {
    public let rows: [StockRowViewModel]
}

public struct StockDetailViewModel: Equatable {
    public let symbol: String
    public let name: String
    public let price: String
    public let priceChange: String
    public let priceChangePercent: String
    public let isPositive: Bool
    public let description: String
}

public struct ConnectionStatusViewModel: Equatable {
    public let isConnected: Bool
    public let label: String

    public static var connected: ConnectionStatusViewModel {
        ConnectionStatusViewModel(isConnected: true, label: "Connected")
    }

    public static var disconnected: ConnectionStatusViewModel {
        ConnectionStatusViewModel(isConnected: false, label: "Disconnected")
    }

    private init(isConnected: Bool, label: String) {
        self.isConnected = isConnected
        self.label = label
    }
}
