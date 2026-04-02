import Foundation

@MainActor
public final class StockDetailPresenter {
    private let detailView: any ResourceView<StockDetailViewModel>
    private let priceFormatter: NumberFormatter

    public init(detailView: any ResourceView<StockDetailViewModel>) {
        self.detailView = detailView
        self.priceFormatter = Self.makePriceFormatter()
    }

    public func didReceive(_ stock: Stock) {
        detailView.display(map(stock))
    }

    // MARK: - Private Helpers -

    private func map(_ stock: Stock) -> StockDetailViewModel {
        StockDetailViewModel(
            symbol: stock.symbol,
            name: stock.name,
            price: priceFormatter.string(from: NSNumber(value: stock.price)) ?? "",
            priceChange: formatChange(stock.priceChange),
            priceChangePercent: String(format: "%.2f%%", abs(stock.priceChangePercent)),
            isPositive: stock.isPositive,
            description: stock.description
        )
    }

    private func formatChange(_ change: Double) -> String {
        let sign = change >= 0 ? "+" : ""
        return "\(sign)\(priceFormatter.string(from: NSNumber(value: change)) ?? "")"
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
