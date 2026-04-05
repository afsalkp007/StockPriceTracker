import XCTest
import SwiftUI
import UIKit
import StockPriceTracker
import StockPriceTrackeriOS
import StockPriceTrackerApp
import Combine

@MainActor
final class StockUIIntegrationTests: XCTestCase {

    func test_feedLoad_updatesListStateStore() async {
        let (sut, stateStore, loader, feedController) = makeSUT()
        
        XCTAssertEqual(stateStore.listViewModel.rows.count, 0)
        XCTAssertFalse(stateStore.isLoading)
        
        sut.simulateAppearance()
        
        XCTAssertEqual(feedController.startCallCount, 1)
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

        loader.complete()
    }
    
    func test_feedLoad_completesWithError() async {
        let (sut, stateStore, loader, feedController) = makeSUT()
        
        sut.simulateAppearance()

        XCTAssertEqual(feedController.startCallCount, 1)
        XCTAssertTrue(stateStore.isLoading)
        
        loader.complete(with: NSError(domain: "any error", code: 0))
        
        try? await Task.sleep(nanoseconds: 10_000_000)
        
        XCTAssertNotNil(stateStore.errorMessage)
        XCTAssertFalse(stateStore.isLoading)
    }
    
    func test_stockDetailComposition_rendersInitialAndUpdatedMatchingStock() {
        let initialStock = makeStock(
            symbol: "AAPL",
            name: "Apple",
            description: "Initial description",
            price: 150
        )
        let updates = PassthroughSubject<[Stock], Never>()
        let stateStore = StockDetailStateStore()
        let sut = ViewHost(
            rootView: StockDetailUIComposer.stockDetailComposedWith(
                stock: initialStock,
                stockUpdates: updates.eraseToAnyPublisher(),
                stateStore: stateStore
            )
        )
        sut.simulateAppearance()

        XCTAssertEqual(stateStore.viewModel?.name, "Apple")
        XCTAssertEqual(stateStore.viewModel?.description, "Initial description")

        updates.send([
            makeStock(
                symbol: "AAPL",
                name: "Apple Updated",
                description: "Updated description",
                price: 155
            )
        ])

        let exp = expectation(description: "Wait for main queue dispatch")
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)
        sut.render()

        XCTAssertEqual(stateStore.viewModel?.name, "Apple Updated")
        XCTAssertEqual(stateStore.viewModel?.description, "Updated description")
    }

    func test_stockDetailComposition_showsRetryAlertOnConnectionDrop() {
        let initialStock = makeStock(
            symbol: "AAPL",
            name: "Apple",
            description: "Initial description",
            price: 150
        )
        let updates = PassthroughSubject<[Stock], Never>()
        let connectionStatus = PassthroughSubject<ConnectionStatusViewModel, Never>()
        let stateStore = StockDetailStateStore()
        let sut = ViewHost(
            rootView: StockDetailUIComposer.stockDetailComposedWith(
                stock: initialStock,
                stockUpdates: updates.eraseToAnyPublisher(),
                connectionStatus: connectionStatus.eraseToAnyPublisher(),
                stateStore: stateStore
            )
        )
        sut.simulateAppearance()

        connectionStatus.send(.connected)
        waitForMainQueue()
        sut.render()

        connectionStatus.send(.disconnected)
        waitForMainQueue()
        sut.render()

        XCTAssertEqual(sut.presentedAlertTitle, StockDetailPresenter.connectionRetryAlert.title)
    }

    func test_stockDetailComposition_doesNotShowRetryAlertWithoutPriorConnection() {
        let initialStock = makeStock(
            symbol: "AAPL",
            name: "Apple",
            description: "Initial description",
            price: 150
        )
        let updates = PassthroughSubject<[Stock], Never>()
        let connectionStatus = PassthroughSubject<ConnectionStatusViewModel, Never>()
        let stateStore = StockDetailStateStore()
        let sut = ViewHost(
            rootView: StockDetailUIComposer.stockDetailComposedWith(
                stock: initialStock,
                stockUpdates: updates.eraseToAnyPublisher(),
                connectionStatus: connectionStatus.eraseToAnyPublisher(),
                stateStore: stateStore
            )
        )
        sut.simulateAppearance()

        connectionStatus.send(.disconnected)
        waitForMainQueue()
        sut.render()

        XCTAssertNil(sut.presentedAlertTitle)
    }

    func test_stockDetailComposition_hidesRetryAlertWhenConnectionRecovers() {
        let initialStock = makeStock(
            symbol: "AAPL",
            name: "Apple",
            description: "Initial description",
            price: 150
        )
        let updates = PassthroughSubject<[Stock], Never>()
        let connectionStatus = PassthroughSubject<ConnectionStatusViewModel, Never>()
        let stateStore = StockDetailStateStore()
        let sut = ViewHost(
            rootView: StockDetailUIComposer.stockDetailComposedWith(
                stock: initialStock,
                stockUpdates: updates.eraseToAnyPublisher(),
                connectionStatus: connectionStatus.eraseToAnyPublisher(),
                stateStore: stateStore
            )
        )
        sut.simulateAppearance()

        connectionStatus.send(.connected)
        waitForMainQueue()
        sut.render()

        connectionStatus.send(.disconnected)
        waitForMainQueue()
        sut.render()

        connectionStatus.send(.connected)
        waitForMainQueue()
        sut.render()

        sut.waitUntilAlertIsDismissed()
        XCTAssertNil(sut.presentedAlertTitle)
    }

    // MARK: - Helpers

    private func makeSUT() -> (
        sut: ViewHost<AnyView>,
        stateStore: StockListStateStore,
        loader: MockStreamLoader,
        feedController: FeedControllerSpy
    ) {
        let stateStore = StockListStateStore()
        let loader = MockStreamLoader()
        let feedController = FeedControllerSpy()
        let sut = ViewHost(
            rootView: AnyView(
                StockUIComposer.stockListComposedWith(
                    stateStore: stateStore,
                    feedLoader: { loader.stream },
                    feedController: feedController,
                    selection: { _ in }
                )
            )
        )
        
        return (sut, stateStore, loader, feedController)
    }
    
    private func makeStock(
        symbol: String,
        name: String = "Name",
        description: String = "Desc",
        price: Double
    ) -> Stock {
        Stock(symbol: symbol, name: name, description: description, price: price, previousPrice: price)
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

    private final class FeedControllerSpy: StockFeedController {
        private(set) var startCallCount = 0

        func start() {
            startCallCount += 1
        }

        func stop() async {}
    }

    private func waitForMainQueue(
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        let exp = expectation(description: "Wait for main queue dispatch")
        DispatchQueue.main.async { exp.fulfill() }
        wait(for: [exp], timeout: 1.0)
    }
}

@MainActor
private final class ViewHost<Content: View> {
    private let window = UIWindow(frame: UIScreen.main.bounds)
    private let controller: UIHostingController<Content>

    init(rootView: Content) {
        controller = UIHostingController(rootView: rootView)
        controller.loadViewIfNeeded()
        window.rootViewController = controller
    }

    func simulateAppearance() {
        window.makeKeyAndVisible()
        controller.beginAppearanceTransition(true, animated: false)
        controller.endAppearanceTransition()
        render()
    }

    func render() {
        controller.view.setNeedsLayout()
        controller.view.layoutIfNeeded()
        RunLoop.current.run(until: Date().addingTimeInterval(0.01))
    }

    func waitUntilAlertIsDismissed(timeout: TimeInterval = 1.0) {
        let endDate = Date().addingTimeInterval(timeout)

        while presentedAlertTitle != nil && Date() < endDate {
            render()
        }
    }

    var presentedAlertTitle: String? {
        (controller.presentedViewController as? UIAlertController)?.title
    }
}
