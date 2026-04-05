import Foundation

@MainActor
public final class StockDetailPresenter {
    private let detailView: any ResourceView<StockDetailViewModel>
    private let priceFormatter: NumberFormatter
    private let percentFormatter: NumberFormatter

    public static var priceHistoryTitle: String {
        Localized.priceHistoryTitle
    }

    public static var aboutTitle: String {
        Localized.aboutTitle
    }

    public static var connectionRetryAlert: ConnectionRetryAlertViewModel {
        ConnectionRetryAlertViewModel(
            title: Localized.connectionRetryAlertTitle,
            message: Localized.connectionRetryAlertMessage,
            retryActionTitle: Localized.connectionRetryActionTitle,
            cancelActionTitle: Localized.connectionRetryCancelActionTitle
        )
    }

    public static func lastTicksTitle(_ count: Int) -> String {
        Localized.lastTicksTitle(count)
    }

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
            description: stock.description,
            history: stock.history
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

private enum Localized {
    static var priceHistoryTitle: String {
        localized("STOCK_DETAIL_PRICE_HISTORY")
    }

    static var aboutTitle: String {
        localized("STOCK_DETAIL_ABOUT")
    }

    static var connectionRetryAlertTitle: String {
        localized("STOCK_DETAIL_CONNECTION_RETRY_ALERT_TITLE")
    }

    static var connectionRetryAlertMessage: String {
        localized("STOCK_DETAIL_CONNECTION_RETRY_ALERT_MESSAGE")
    }

    static var connectionRetryActionTitle: String {
        localized("STOCK_DETAIL_CONNECTION_RETRY_ACTION")
    }

    static var connectionRetryCancelActionTitle: String {
        localized("STOCK_DETAIL_CONNECTION_CANCEL_ACTION")
    }

    static func lastTicksTitle(_ count: Int) -> String {
        let key = count == 1 ? "STOCK_DETAIL_LAST_SINGLE_TICK" : "STOCK_DETAIL_LAST_MULTIPLE_TICKS"
        return String(format: localized(key), locale: Locale.current, arguments: [count])
    }

    private static func localized(_ key: String) -> String {
        NSLocalizedString(
            key,
            tableName: "StockPresentation",
            bundle: Bundle(for: StockDetailPresenter.self),
            comment: ""
        )
    }
}
