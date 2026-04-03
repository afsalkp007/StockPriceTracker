import XCTest
import StockPriceTracker
import StockPriceTrackeriOS
import StockPriceTrackerApp

@MainActor
final class StockUIIntegrationTests: XCTestCase {

    func test_feedLoad_updatesListStateStore() async {
        let (adapter, stateStore, loader) = makeSUT()
        
        XCTAssertEqual(stateStore.listViewModel.rows.count, 0)
        XCTAssertFalse(stateStore.isLoading)
        
        adapter.didRequestFeedLoad()
        
        XCTAssertTrue(stateStore.isLoading, "Expected loading state to be true after requesting feed load")
        
        let stock1 = makeStock(symbol: "A", price: 100)
        loader.emit([stock1])
        
        // Yield to allow the async sequence to process the emitted element
        try? await Task.sleep(nanoseconds: 10_000_000)
        
        XCTAssertEqual(stateStore.listViewModel.rows.count, 1)
        XCTAssertEqual(stateStore.listViewModel.rows.first?.symbol, "A")
        XCTAssertFalse(stateStore.isLoading, "Expected loading state to be false after receiving first feed payload")
        
        let stock2 = makeStock(symbol: "B", price: 200)
        loader.emit([stock1, stock2])
        
        try? await Task.sleep(nanoseconds: 10_000_000)
        XCTAssertEqual(stateStore.listViewModel.rows.count, 2)
        XCTAssertFalse(stateStore.isLoading)
        
        await adapter.didCancelFeedLoad()
    }
    
    func test_feedLoad_completesWithError() async {
        let (adapter, stateStore, loader) = makeSUT()
        
        adapter.didRequestFeedLoad()
        XCTAssertTrue(stateStore.isLoading)
        
        loader.complete(with: NSError(domain: "any error", code: 0))
        
        try? await Task.sleep(nanoseconds: 10_000_000)
        
        XCTAssertNotNil(stateStore.errorMessage)
        XCTAssertFalse(stateStore.isLoading)
        
        await adapter.didCancelFeedLoad()
    }

    // MARK: - Helpers

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (
        adapter: StockFeedPresentationAdapter,
        stateStore: StockListStateStore,
        loader: MockStreamLoader
    ) {
        let stateStore = StockListStateStore()
        let loader = MockStreamLoader()
        
        let presentationAdapter = StockFeedPresentationAdapter(loader: { loader.stream })
        let viewAdapter = StockViewAdapter(stateStore: stateStore, selection: { _ in })
        
        let presenter = LoadResourcePresenter<[Stock], StockViewAdapter>(
            resourceView: viewAdapter,
            loadingView: WeakRefVirtualProxy(viewAdapter),
            errorView: WeakRefVirtualProxy(viewAdapter),
            mapper: { (stocks: [Stock]) -> StockListViewModel in
                viewAdapter.updateRawStocks(stocks)
                let stockPresenter = StockPresenter(
                    listView: viewAdapter,
                    connectionView: WeakRefVirtualProxy(viewAdapter)
                )
                stockPresenter.didReceive(stocks, sortedBy: stateStore.currentSort)
                return stateStore.listViewModel 
            }
        )
        presentationAdapter.presenter = presenter
        
        // Simple manual validation leak checks, because trackForMemoryLeaks requires nonisolated contexts
        addTeardownBlock { [weak presentationAdapter, weak stateStore] in
            XCTAssertNil(presentationAdapter, "Expected adapter to be deallocated", file: file, line: line)
            XCTAssertNil(stateStore, "Expected state store to be deallocated", file: file, line: line)
        }
        
        return (presentationAdapter, stateStore, loader)
    }
    
    private func makeStock(symbol: String, price: Double) -> Stock {
        Stock(symbol: symbol, name: "Name", description: "Desc", price: price, previousPrice: price)
    }

    private class MockStreamLoader {
        let (stream, continuation) = AsyncThrowingStream<[Stock], Error>.makeStream()
        
        func emit(_ element: [Stock]) {
            continuation.yield(element)
        }
        
        func complete(with error: Error? = nil) {
            if let error = error {
                continuation.finish(throwing: error)
            } else {
                continuation.finish()
            }
        }
    }
}
