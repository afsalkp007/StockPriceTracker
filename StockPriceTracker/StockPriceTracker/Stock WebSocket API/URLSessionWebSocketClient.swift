import Foundation

public final class URLSessionWebSocketClient: WebSocketClient {
    private let url: URL
    private let session: URLSession
    private var task: URLSessionWebSocketTask?

    public init(url: URL, session: URLSession = .shared) {
        self.url = url
        self.session = session
    }

    public func connect() async throws {
        task = session.webSocketTask(with: url)
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

    // MARK: - Private Helpers -

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
