import XCTest
import StockPriceTracker

@MainActor
final class StockPresenterTests: XCTestCase {

    func test_title_isLocalized() {
        XCTAssertEqual(
            StockPresenter.title,
            localizedString(
                forKey: "STOCK_VIEW_TITLE",
                table: "StockPresentation",
                bundle: Bundle(for: StockPresenter.self)
            )
        )
    }

    func test_didConnect_displaysConnectedStatus() {
        let (sut, view) = makeSUT()
        
        sut.didConnect()
        
        XCTAssertEqual(view.messages, [.displayStatus(.connected)])
    }

    func test_didDisconnect_displaysDisconnectedStatus() {
        let (sut, view) = makeSUT()
        
        sut.didDisconnect()
        
        XCTAssertEqual(view.messages, [.displayStatus(.disconnected)])
    }
    
    func test_didReceiveStocks_createsViewModelsSortedByPrice() {
        let (sut, view) = makeSUT()
        let stocks = [
            makeStock(symbol: "A", price: 100, previousPrice: 100),
            makeStock(symbol: "B", price: 200, previousPrice: 200)
        ]
        
        sut.didReceive(stocks, sortedBy: .byPrice)
        
        guard case let .displayList(listViewModel)? = view.messages.first else {
            XCTFail("Expected list view model, got \(view.messages)")
            return
        }
        
        XCTAssertEqual(listViewModel.rows.map { $0.symbol }, ["B", "A"])
        XCTAssertEqual(listViewModel.rows[0].price, "$200.00")
        XCTAssertEqual(listViewModel.rows[1].price, "$100.00")
    }

    func test_didReceiveStocks_createsViewModelsSortedByPriceChangeMagnitude() {
        let (sut, view) = makeSUT()
        let stocks = [
            makeStock(symbol: "A", price: 110, previousPrice: 100),
            makeStock(symbol: "B", price: 80, previousPrice: 100),
            makeStock(symbol: "C", price: 105, previousPrice: 100)
        ]

        sut.didReceive(stocks, sortedBy: .byPriceChange)

        guard case let .displayList(listViewModel)? = view.messages.first else {
            XCTFail("Expected list view model, got \(view.messages)")
            return
        }

        XCTAssertEqual(listViewModel.rows.map(\.symbol), ["B", "A", "C"])
    }

    func test_didReceiveStocks_createsViewModelsWithFormattedPriceChange() {
        let (sut, view) = makeSUT()
        let stocks = [
            makeStock(symbol: "POS", price: 110, previousPrice: 100),
            makeStock(symbol: "NEG", price: 80, previousPrice: 100),
            makeStock(symbol: "ZER", price: 100, previousPrice: 100)
        ]

        sut.didReceive(stocks, sortedBy: .byPrice)

        guard case let .displayList(listViewModel)? = view.messages.first else {
            XCTFail("Expected list view model, got \(view.messages)")
            return
        }

        XCTAssertEqual(listViewModel.rows, [
            StockRowViewModel(
                symbol: "POS",
                name: "POS Name",
                price: "$110.00",
                priceChange: "+$10.00 (10.00%)",
                isPositive: true
            ),
            StockRowViewModel(
                symbol: "ZER",
                name: "ZER Name",
                price: "$100.00",
                priceChange: "$0.00 (0.00%)",
                isPositive: true
            ),
            StockRowViewModel(
                symbol: "NEG",
                name: "NEG Name",
                price: "$80.00",
                priceChange: "-$20.00 (20.00%)",
                isPositive: false
            )
        ])
    }

    func test_didReceiveStocks_formatsValuesUsingLocale() {
        let (sut, view) = makeSUT(locale: Locale(identifier: "pt_BR"))
        let stocks = [
            makeStock(symbol: "AAPL", price: 1234.56, previousPrice: 1200.00)
        ]

        sut.didReceive(stocks, sortedBy: .byPrice)

        guard case let .displayList(listViewModel)? = view.messages.first else {
            XCTFail("Expected list view model, got \(view.messages)")
            return
        }

        XCTAssertEqual(listViewModel.rows, [
            StockRowViewModel(
                symbol: "AAPL",
                name: "AAPL Name",
                price: "US$ 1.234,56",
                priceChange: "+US$ 34,56 (2,88%)",
                isPositive: true
            )
        ])
    }

    private func makeSUT(
        locale: Locale = Locale(identifier: "en_US"),
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: StockPresenter, view: ViewSpy) {
        let view = ViewSpy()
        let sut = StockPresenter(listView: view, connectionView: view, locale: locale)
        trackForMemoryLeaks(view, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, view)
    }

    private func makeStock(symbol: String, price: Double, previousPrice: Double) -> Stock {
        Stock(symbol: symbol, name: "\(symbol) Name", description: "Desc", price: price, previousPrice: previousPrice)
    }

    private class ViewSpy: ResourceView, ConnectionStatusViewProtocol {
        typealias ResourceViewModel = StockListViewModel
        
        enum Message: Equatable {
            case displayStatus(ConnectionStatusViewModel)
            case displayList(StockListViewModel)
        }
        
        private(set) var messages = [Message]()
        
        func display(_ viewModel: ConnectionStatusViewModel) {
            messages.append(.displayStatus(viewModel))
        }
        
        func display(_ viewModel: StockListViewModel) {
            messages.append(.displayList(viewModel))
        }
    }
}
