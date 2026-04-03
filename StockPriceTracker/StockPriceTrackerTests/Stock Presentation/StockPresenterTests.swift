import XCTest
import StockPriceTracker

@MainActor
final class StockPresenterTests: XCTestCase {

    func test_title_isLocalized() {
        XCTAssertEqual(StockPresenter.title, "Stocks")
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
        
        // Expected sort: B ($200) then A ($100)
        XCTAssertEqual(listViewModel.rows.map { $0.symbol }, ["B", "A"])
        XCTAssertEqual(listViewModel.rows[0].price, "$200.00")
        XCTAssertEqual(listViewModel.rows[1].price, "$100.00")
    }

    // MARK: - Helpers -

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: StockPresenter, view: ViewSpy) {
        let view = ViewSpy()
        let sut = StockPresenter(listView: view, connectionView: view, locale: Locale(identifier: "en_US"))
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
