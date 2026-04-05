import Foundation

@MainActor
public final class StockPresenter {
    private let listView: any ResourceView<StockListViewModel>
    private let connectionView: any ConnectionStatusViewProtocol
    private let priceFormatter: NumberFormatter
    private let percentFormatter: NumberFormatter

    public static var title: String { Localized.title }
    public static var sortTitle: String { Localized.sortTitle }
    public static var sortByPriceTitle: String { Localized.sortByPriceTitle }
    public static var sortByChangeTitle: String { Localized.sortByChangeTitle }

    public init(
        listView: any ResourceView<StockListViewModel>,
        connectionView: any ConnectionStatusViewProtocol,
        locale: Locale = .current
    ) {
        self.listView = listView
        self.connectionView = connectionView
        self.priceFormatter = Self.makePriceFormatter(locale: locale)
        self.percentFormatter = Self.makePercentFormatter(locale: locale)
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
        let sign = change > 0 ? "+" : ""
        let formattedChange = priceFormatter.string(from: NSNumber(value: change)) ?? ""
        let formattedPercent = percentFormatter.string(from: NSNumber(value: abs(percent))) ?? ""
        return "\(sign)\(formattedChange) (\(formattedPercent))"
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
        formatter.multiplier = 1 // Our model's percent is e.g. 2.5 for 2.5%, so multiplier is 1.
        formatter.locale = locale
        formatter.maximumFractionDigits = 2
        formatter.minimumFractionDigits = 2
        return formatter
    }
}

@MainActor
public protocol ConnectionStatusViewProtocol {
    func display(_ viewModel: ConnectionStatusViewModel)
}

private enum Localized {
    static var title: String {
        localized("STOCK_VIEW_TITLE")
    }

    static var sortTitle: String {
        localized("STOCK_LIST_SORT")
    }

    static var sortByPriceTitle: String {
        localized("STOCK_LIST_SORT_BY_PRICE")
    }

    static var sortByChangeTitle: String {
        localized("STOCK_LIST_SORT_BY_CHANGE")
    }

    private static func localized(_ key: String) -> String {
        NSLocalizedString(
            key,
            tableName: "StockPresentation",
            bundle: Bundle(for: StockPresenter.self),
            comment: ""
        )
    }
}
