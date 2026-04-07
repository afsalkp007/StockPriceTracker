import Foundation

public protocol URLSessionWebSocketSession {
    func makeWebSocketTask(with url: URL) -> any URLSessionWebSocketTasking
}

public protocol URLSessionWebSocketTasking: AnyObject {
    func resume()
    func cancel(with closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?)
    func send(_ message: URLSessionWebSocketTask.Message) async throws
    func receive(completionHandler: @escaping @Sendable (Result<URLSessionWebSocketTask.Message, Error>) -> Void)
}

public final class URLSessionWebSocketClient {
    private let url: URL
    private let session: any URLSessionWebSocketSession
    private var task: (any URLSessionWebSocketTasking)?

    public init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    public init(url: URL, webSocketSession: any URLSessionWebSocketSession) {
        self.url = url
        self.session = webSocketSession
    }
}

extension URLSessionWebSocketClient: WebSocketClient {
    
    public func connect() async throws {
        task = session.makeWebSocketTask(with: url)
        task?.resume()
    }

    public func disconnect() {
        task?.cancel(with: .normalClosure, reason: nil)
        task = nil
    }

    public func send(_ message: String) async throws {
        try await task?.send(.string(message))
    }

    public func receive() -> AsyncStream<Result<String, Error>> {
        AsyncStream { [weak self] continuation in
            self?.receiveNext(continuation: continuation)
        }
    }
}

extension URLSessionWebSocketClient {

    private func receiveNext(continuation: AsyncStream<Result<String, Error>>.Continuation) {
        task?.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    continuation.yield(.success(text))
                }
                self?.receiveNext(continuation: continuation)
            case .failure(let error):
                continuation.yield(.failure(error))
                continuation.finish()
            }
        }
    }
}

extension URLSession: URLSessionWebSocketSession {
    public func makeWebSocketTask(with url: URL) -> any URLSessionWebSocketTasking {
        webSocketTask(with: url)
    }
}

extension URLSessionWebSocketTask: URLSessionWebSocketTasking {}
