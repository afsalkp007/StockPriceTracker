import Foundation

@MainActor
public final class StockPresenter {
    private let listView: any ResourceView<StockListViewModel>
    private let connectionView: any ConnectionStatusViewProtocol
    private let priceFormatter: NumberFormatter

    public static var title: String { "Stocks" }

    public init(
        listView: any ResourceView<StockListViewModel>,
        connectionView: any ConnectionStatusViewProtocol
    ) {
        self.listView = listView
        self.connectionView = connectionView
        self.priceFormatter = Self.makePriceFormatter()
    }

    public func didReceive(_ stocks: [Stock], sortedBy option: SortOption) {
        listView.display(StockListViewModel(rows: sorted(stocks, by: option).map(map)))
    }

    public func didConnect() {
        connectionView.display(.connected)
    }

    public func didDisconnect() {
        connectionView.display(.disconnected)
    }

    // MARK: - Private Helpers -

    private func sorted(_ stocks: [Stock], by option: SortOption) -> [Stock] {
        switch option {
        case .byPrice:
            return stocks.sorted { $0.price > $1.price }
        case .byPriceChange:
            return stocks.sorted { abs($0.priceChange) > abs($1.priceChange) }
        }
    }

    private func map(_ stock: Stock) -> StockRowViewModel {
        StockRowViewModel(
            symbol: stock.symbol,
            name: stock.name,
            price: priceFormatter.string(from: NSNumber(value: stock.price)) ?? "",
            priceChange: formatChange(stock.priceChange, percent: stock.priceChangePercent),
            isPositive: stock.isPositive
        )
    }

    private func formatChange(_ change: Double, percent: Double) -> String {
        let sign = change >= 0 ? "+" : ""
        let formattedChange = priceFormatter.string(from: NSNumber(value: change)) ?? ""
        let formattedPercent = String(format: "%.2f", abs(percent))
        return "\(sign)\(formattedChange) (\(formattedPercent)%)"
    }

    private static func makePriceFormatter() -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencySymbol = "$"
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
}

@MainActor
public protocol ConnectionStatusViewProtocol {
    func display(_ viewModel: ConnectionStatusViewModel)
}
