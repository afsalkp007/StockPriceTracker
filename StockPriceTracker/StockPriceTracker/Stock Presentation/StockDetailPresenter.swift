import Foundation

@MainActor
public final class StockDetailPresenter {
    private let detailView: any ResourceView<StockDetailViewModel>
    private let priceFormatter: NumberFormatter
    private let percentFormatter: NumberFormatter

    public init(detailView: any ResourceView<StockDetailViewModel>, locale: Locale = .current) {
        self.detailView = detailView
        self.priceFormatter = Self.makePriceFormatter(locale: locale)
        self.percentFormatter = Self.makePercentFormatter(locale: locale)
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
            priceChangePercent: percentFormatter.string(from: NSNumber(value: abs(stock.priceChangePercent))) ?? "",
            isPositive: stock.isPositive,
            description: stock.description
        )
    }

    private func formatChange(_ change: Double) -> String {
        let sign = change > 0 ? "+" : ""
        return "\(sign)\(priceFormatter.string(from: NSNumber(value: change)) ?? "")"
    }

    private static func makePriceFormatter(locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        formatter.locale = locale
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }

    private static func makePercentFormatter(locale: Locale) -> NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .percent
        formatter.multiplier = 1
        formatter.locale = locale
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
}
