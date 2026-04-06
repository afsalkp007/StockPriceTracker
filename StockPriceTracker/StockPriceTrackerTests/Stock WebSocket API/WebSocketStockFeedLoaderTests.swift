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
        await waitUntil { client.connectionCallCount == 1 }
        
        XCTAssertEqual(client.connectionCallCount, 1)
        
        // Stop explicitly to cancel the infinite loop task, allowing `sut` to deallocate.
        await sut.stop()
    }

    func test_startFeed_finishesWithConnectError() async {
        let (sut, client) = makeSUT()
        let expectedError = anyNSError()
        let stream = sut.startFeed()
        client.connectError = expectedError

        sut.start()

        let receivedError = await completionError(from: stream)

        XCTAssertEqual(receivedError, expectedError)
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

        let firstStream = sut.startFeed()
        sut.start()
        await waitUntil { client.connectionCallCount == 1 }
        client.completeReceive(with: anyNSError())
        _ = await completionError(from: firstStream)

        _ = sut.startFeed()
        sut.start()
        await waitUntil { client.connectionCallCount == 2 }

        XCTAssertEqual(client.connectionCallCount, 2)
        
        await sut.stop()
    }

    func test_start_whenAlreadyStarted_doesNotConnectAgain() async {
        let (sut, client) = makeSUT()

        sut.start()
        sut.start()
        await waitUntil { client.connectionCallCount == 1 }

        XCTAssertEqual(client.connectionCallCount, 1)

        await sut.stop()
    }

    func test_startFeed_finishesWithReceiveError() async {
        let (sut, client) = makeSUT()
        let expectedError = anyNSError()
        let stream = sut.startFeed()

        sut.start()
        await waitUntil { client.connectionCallCount == 1 }
        client.completeReceive(with: expectedError)

        let receivedError = await completionError(from: stream)
        await waitUntil { client.disconnectedCalled == true }

        XCTAssertEqual(receivedError, expectedError)
    }

    func test_receivedMessage_appendsPriceToStockHistory() async throws {
        let (sut, client) = makeSUT()
        let stream = sut.startFeed()
        let batchesTask = Task {
            try await collectBatches(from: stream, count: 2)
        }
        sut.start()

        client.yieldMessage(makeBatchJSON([("AAPL", 150.0)]))
        client.yieldMessage(makeBatchJSON([("AAPL", 155.0)]))

        let batches = try await batchesTask.value

        await sut.stop()

        guard let lastBatch = batches.last,
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
        let batchesTask = Task {
            try await collectBatches(from: stream, count: 35, timeout: 2.0)
        }
        sut.start()

        for i in 1...35 {
            client.yieldMessage(makeBatchJSON([("AAPL", Double(100 + i))]))
        }

        let batches = try await batchesTask.value

        await sut.stop()

        guard let lastBatch = batches.last,
              let aapl = lastBatch.first(where: { $0.symbol == "AAPL" }) else {
            XCTFail("Expected at least one batch with AAPL")
            return
        }

        XCTAssertLessThanOrEqual(aapl.history.count, 30, "Expected history to be capped at 30 entries, got \(aapl.history.count)")
    }

    func test_receivedInvalidMessage_ignoresPayloadUntilValidUpdateArrives() async throws {
        let (sut, client) = makeSUT()
        let stream = sut.startFeed()
        let batchesTask = Task {
            try await collectBatches(from: stream, count: 1)
        }
        sut.start()

        client.yieldMessage("{\"symbol\":\"AAPL\"}")
        client.yieldMessage(makeBatchJSON([("AAPL", 150.0)]))

        let batches = try await batchesTask.value

        await sut.stop()

        XCTAssertEqual(batches.count, 1)
        XCTAssertEqual(batches.first?.first(where: { $0.symbol == "AAPL" })?.price, 150.0)
    }
    
    // MARK: - Helpers -

    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> (sut: WebSocketStockFeedLoader, client: WebSocketClientSpy) {
        let client = WebSocketClientSpy()
        let sut = WebSocketStockFeedLoader(client: client, updateInterval: 0.1)
        trackForMemoryLeaks(client, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, client)
    }

    private func makeBatchJSON(_ pairs: [(String, Double)]) -> String {
        let entries = pairs.map { "\"symbol\":\"\($0.0)\",\"price\":\($0.1)" }.map { "{\($0)}" }.joined(separator: ",")
        return "[\(entries)]"
    }

    private func collectBatches(
        from stream: AsyncThrowingStream<[Stock], Error>,
        count expectedCount: Int,
        timeout: TimeInterval = 1.0
    ) async throws -> [[Stock]] {
        let batchesBox = BatchesBox()
        let errorBox = ErrorBox()
        let exp = expectation(description: "Wait for \(expectedCount) batches")
        exp.expectedFulfillmentCount = expectedCount

        let task = Task { @MainActor in
            do {
                for try await batch in stream {
                    await batchesBox.append(batch)
                    exp.fulfill()

                    if await batchesBox.count == expectedCount {
                        break
                    }
                }
            } catch {
                await errorBox.set(error as NSError)
            }
        }

        await fulfillment(of: [exp], timeout: timeout)
        task.cancel()
        _ = await task.result

        if let error = await errorBox.value {
            throw error
        }

        return await batchesBox.value
    }

    private func completionError(
        from stream: AsyncThrowingStream<[Stock], Error>,
        timeout: TimeInterval = 2.0
    ) async -> NSError? {
        let errorBox = ErrorBox()
        let exp = expectation(description: "Wait for stream completion")

        Task { @MainActor in
            do {
                for try await _ in stream {}
            } catch {
                await errorBox.set(error as NSError)
            }
            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: timeout)
        return await errorBox.value
    }

    private func waitUntil(
        timeout: TimeInterval = 1.0,
        file: StaticString = #filePath,
        line: UInt = #line,
        condition: @escaping () -> Bool
    ) async {
        let exp = expectation(description: "Wait until condition is met")

        Task { @MainActor in
            let deadline = Date().addingTimeInterval(timeout)

            while !condition() && Date() < deadline {
                await Task.yield()
            }

            exp.fulfill()
        }

        await fulfillment(of: [exp], timeout: timeout)
        XCTAssertTrue(condition(), file: file, line: line)
    }

    private class WebSocketClientSpy: WebSocketClient {
        var connectionCallCount = 0
        var disconnectedCalled: Bool?
        var connectError: Error?
        
        private var streamContinuation: AsyncStream<Result<String, Error>>.Continuation?
        private var pendingResults = [Result<String, Error>]()
        
        func connect() async throws {
            connectionCallCount += 1
            if let connectError {
                throw connectError
            }
        }
        
        func disconnect() {
            disconnectedCalled = true
            streamContinuation?.finish()
            streamContinuation = nil
        }
        
        func send(_ message: String) async throws {
            // No-op for this test scope
        }
        
        func receive() -> AsyncStream<Result<String, Error>> {
            AsyncStream { [weak self] continuation in
                self?.streamContinuation = continuation
                self?.flushPendingResults()
                if self?.disconnectedCalled == true {
                    continuation.finish()
                    self?.streamContinuation = nil
                }
            }
        }

        func yieldMessage(_ message: String) {
            emit(.success(message))
        }

        func completeReceive(with error: Error) {
            emit(.failure(error))
        }

        private func emit(_ result: Result<String, Error>) {
            guard streamContinuation != nil else {
                pendingResults.append(result)
                return
            }
            deliver(result)
        }

        private func flushPendingResults() {
            let results = pendingResults
            pendingResults.removeAll()
            results.forEach(deliver)
        }

        private func deliver(_ result: Result<String, Error>) {
            switch result {
            case .success(let message):
                streamContinuation?.yield(.success(message))
            case .failure(let error):
                streamContinuation?.yield(.failure(error))
                streamContinuation?.finish()
                streamContinuation = nil
            }
        }
    }

    private actor ErrorBox {
        private(set) var value: NSError?

        func set(_ error: NSError) {
            value = error
        }
    }

    private actor BatchesBox {
        private(set) var value = [[Stock]]()

        var count: Int {
            value.count
        }

        func append(_ batch: [Stock]) {
            value.append(batch)
        }
    }
}
