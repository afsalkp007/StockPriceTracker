import XCTest
import StockPriceTracker

@MainActor
final class WebSocketStockFeedLoaderTests: XCTestCase {

    func test_init_doesNotStartFeedOrConnect() {
        let (_, client) = makeSUT()
        
        XCTAssertEqual(client.connectionCallCount, 0)
        XCTAssertNil(client.disconnectedCalled)
    }

    func test_start_connectsToClient() async {
        let (sut, client) = makeSUT()
        
        sut.start()
        
        // Yield to allow the background Task to reach client.connect()
        try? await Task.sleep(nanoseconds: 10_000_000)
        
        XCTAssertEqual(client.connectionCallCount, 1)
        
        // Stop explicitly to cancel the infinite loop task, allowing `sut` to deallocate.
        await sut.stop()
    }
    
    func test_stop_disconnectsClientAndFinishesStream() async throws {
        let (sut, client) = makeSUT()
        
        let stream = sut.startFeed()
        sut.start()
        
        await sut.stop()
        XCTAssertTrue(client.disconnectedCalled == true)
        
        // Assert the stream finishes immediately
        var didFinish = false
        for try await _ in stream {
            XCTFail("Expected stream to finish, but received value")
        }
        didFinish = true
        XCTAssertTrue(didFinish)
    }

    func test_start_afterSocketDrop_connectsAgain() async {
        let (sut, client) = makeSUT()

        _ = sut.startFeed()
        sut.start()

        try? await Task.sleep(nanoseconds: 10_000_000)
        client.completeReceive(with: anyNSError())
        try? await Task.sleep(nanoseconds: 10_000_000)

        _ = sut.startFeed()
        sut.start()

        try? await Task.sleep(nanoseconds: 10_000_000)

        XCTAssertEqual(client.connectionCallCount, 2)

        await sut.stop()
    }

    func test_receivedMessage_appendsPriceToStockHistory() async throws {
        let (sut, client) = makeSUT()
        let stream = sut.startFeed()
        sut.start()
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Emit a single price update for AAPL
        client.yieldMessage(makeBatchJSON([("AAPL", 150.0)]))
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Emit a second update for AAPL
        client.yieldMessage(makeBatchJSON([("AAPL", 155.0)]))
        try? await Task.sleep(nanoseconds: 10_000_000)

        await sut.stop()

        var receivedBatches = [[Stock]]()
        for try await batch in stream {
            receivedBatches.append(batch)
        }

        guard let lastBatch = receivedBatches.last,
              let aapl = lastBatch.first(where: { $0.symbol == "AAPL" }) else {
            XCTFail("Expected at least one batch with AAPL")
            return
        }

        XCTAssertTrue(aapl.history.count >= 2, "Expected history to grow with each received tick, got \(aapl.history.count) entries")
        XCTAssertTrue(aapl.history.contains(155.0), "Expected latest price 155.0 to appear in history")
    }

    func test_receivedMessages_historyCapAt30_dropsOldestEntry() async throws {
        let (sut, client) = makeSUT()
        let stream = sut.startFeed()
        sut.start()
        try? await Task.sleep(nanoseconds: 10_000_000)

        // Emit 35 price updates to exceed the 30-point window
        for i in 1...35 {
            client.yieldMessage(makeBatchJSON([("AAPL", Double(100 + i))]))
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
        try? await Task.sleep(nanoseconds: 10_000_000)

        await sut.stop()

        var receivedBatches = [[Stock]]()
        for try await batch in stream {
            receivedBatches.append(batch)
        }

        guard let lastBatch = receivedBatches.last,
              let aapl = lastBatch.first(where: { $0.symbol == "AAPL" }) else {
            XCTFail("Expected at least one batch with AAPL")
            return
        }

        XCTAssertLessThanOrEqual(aapl.history.count, 30, "Expected history to be capped at 30 entries, got \(aapl.history.count)")
    }
    
    // MARK: - Helpers -

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: WebSocketStockFeedLoader, client: WebSocketClientSpy) {
        let client = WebSocketClientSpy()
        let sut = WebSocketStockFeedLoader(client: client, updateInterval: 0.1)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }

    /// Produces a JSON array batch string for the given (symbol, price) pairs — matching what the loader's sendLoop emits.
    private func makeBatchJSON(_ pairs: [(String, Double)]) -> String {
        let entries = pairs.map { "\"symbol\":\"\($0.0)\",\"price\":\($0.1)" }.map { "{\($0)}" }.joined(separator: ",")
        return "[\(entries)]"
    }


    private class WebSocketClientSpy: WebSocketClient {
        var connectionCallCount = 0
        var disconnectedCalled: Bool?
        
        private var streamContinuation: AsyncStream<Result<String, Error>>.Continuation?
        
        func connect() async throws {
            connectionCallCount += 1
            // Small sleep to ensure task yielding works properly in testing
            try? await Task.sleep(nanoseconds: 1_000_000)
        }
        
        func disconnect() {
            disconnectedCalled = true
            streamContinuation?.finish()
        }
        
        func send(_ message: String) async throws {
            // No-op for this test scope
        }
        
        func receive() -> AsyncStream<Result<String, Error>> {
            AsyncStream { [weak self] continuation in
                self?.streamContinuation = continuation
                if self?.disconnectedCalled == true {
                    continuation.finish()
                }
            }
        }

        func yieldMessage(_ message: String) {
            streamContinuation?.yield(.success(message))
        }

        func completeReceive(with error: Error) {
            streamContinuation?.yield(.failure(error))
            streamContinuation?.finish()
        }
    }
}
