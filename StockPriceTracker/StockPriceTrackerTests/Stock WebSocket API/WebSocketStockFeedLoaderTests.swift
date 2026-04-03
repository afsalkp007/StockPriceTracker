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
    
    // MARK: - Helpers -

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: WebSocketStockFeedLoader, client: WebSocketClientSpy) {
        let client = WebSocketClientSpy()
        let sut = WebSocketStockFeedLoader(client: client, updateInterval: 0.1) // Fast interval for testing
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
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

        func completeReceive(with error: Error) {
            streamContinuation?.yield(.failure(error))
            streamContinuation?.finish()
        }
    }
}
