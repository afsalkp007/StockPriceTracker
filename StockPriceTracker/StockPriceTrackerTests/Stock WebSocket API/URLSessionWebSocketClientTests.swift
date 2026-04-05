import XCTest
import Foundation
import StockPriceTracker

final class URLSessionWebSocketClientTests: XCTestCase {

    func test_connect_requestsWebSocketTaskForURLAndResumesIt() async throws {
        let url = URL(string: "wss://example.com/socket")!
        let (sut, session, task) = makeSUT(url: url)

        try await sut.connect()

        XCTAssertEqual(session.requestedURLs, [url])
        XCTAssertEqual(task.resumeCallCount, 1)
    }

    func test_disconnect_cancelsTaskWithNormalClosure() async throws {
        let (sut, _, task) = makeSUT()
        try await sut.connect()

        sut.disconnect()

        XCTAssertEqual(task.cancelCallCount, 1)
        XCTAssertEqual(task.cancelledCloseCode, .normalClosure)
        XCTAssertNil(task.cancelledReason)
    }

    func test_send_forwardsStringMessageToTask() async throws {
        let (sut, _, task) = makeSUT()
        try await sut.connect()

        try await sut.send("a message")

        XCTAssertEqual(task.sentStringMessages, ["a message"])
    }

    func test_receive_deliversStringMessagesInOrder() async throws {
        let (sut, _, task) = makeSUT()
        try await sut.connect()
        let stream = sut.receive()
        var iterator = stream.makeAsyncIterator()

        task.completeReceive(with: .success(.string("first")))
        task.completeReceive(with: .success(.string("second")))
        task.completeReceive(with: .failure(anyNSError()))

        let firstMessage = try await iterator.next()?.get()
        let secondMessage = try await iterator.next()?.get()

        XCTAssertEqual(firstMessage, "first")
        XCTAssertEqual(secondMessage, "second")
    }

    func test_receive_ignoresNonStringMessages() async throws {
        let (sut, _, task) = makeSUT()
        try await sut.connect()
        let stream = sut.receive()
        var iterator = stream.makeAsyncIterator()

        task.completeReceive(with: .success(.data(Data("ignored".utf8))))
        task.completeReceive(with: .success(.string("delivered")))
        task.completeReceive(with: .failure(anyNSError()))

        let deliveredMessage = try await iterator.next()?.get()

        XCTAssertEqual(deliveredMessage, "delivered")
    }

    func test_receive_deliversErrorAndFinishesStreamOnFailure() async throws {
        let (sut, _, task) = makeSUT()
        try await sut.connect()
        let stream = sut.receive()
        var iterator = stream.makeAsyncIterator()
        let error = anyNSError()

        task.completeReceive(with: .failure(error))

        let receivedError = await iterator.nextError() as NSError?
        let nextValue = await iterator.next()

        XCTAssertEqual(receivedError, error)
        XCTAssertNil(nextValue)
    }

    private func makeSUT(
        url: URL = URL(string: "wss://example.com/socket")!,
        file: StaticString = #filePath,
        line: UInt = #line
    ) -> (sut: WebSocketClient, session: SessionSpy, task: TaskSpy) {
        let task = TaskSpy()
        let session = SessionSpy(task: task)
        let sut = URLSessionWebSocketClient(url: url, webSocketSession: session)
        trackForMemoryLeaks(task, file: file, line: line)
        trackForMemoryLeaks(session, file: file, line: line)
        trackForMemoryLeaks(sut, file: file, line: line)
        return (sut, session, task)
    }

    private final class SessionSpy: URLSessionWebSocketSession {
        private(set) var requestedURLs = [URL]()
        private let task: TaskSpy

        init(task: TaskSpy) {
            self.task = task
        }

        func makeWebSocketTask(with url: URL) -> any URLSessionWebSocketTasking {
            requestedURLs.append(url)
            return task
        }
    }

    private final class TaskSpy: URLSessionWebSocketTasking {
        private(set) var resumeCallCount = 0
        private(set) var cancelCallCount = 0
        private(set) var cancelledCloseCode: URLSessionWebSocketTask.CloseCode?
        private(set) var cancelledReason: Data?
        private(set) var sentStringMessages = [String]()
        private var receiveCompletions = [@Sendable (Result<URLSessionWebSocketTask.Message, Error>) -> Void]()

        func resume() {
            resumeCallCount += 1
        }

        func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
            cancelCallCount += 1
            cancelledCloseCode = closeCode
            cancelledReason = reason
        }

        func send(_ message: URLSessionWebSocketTask.Message) async throws {
            if case let .string(text) = message {
                sentStringMessages.append(text)
            }
        }

        func receive(completionHandler: @escaping @Sendable (Result<URLSessionWebSocketTask.Message, Error>) -> Void) {
            receiveCompletions.append(completionHandler)
        }

        func completeReceive(with result: Result<URLSessionWebSocketTask.Message, Error>, at index: Int = 0) {
            receiveCompletions.remove(at: index)(result)
        }
    }
}

private extension AsyncStream<Result<String, Error>>.AsyncIterator {
    mutating func nextError() async -> Error? {
        guard let result = await next() else { return nil }

        switch result {
        case .success:
            return nil
        case let .failure(error):
            return error
        }
    }
}
