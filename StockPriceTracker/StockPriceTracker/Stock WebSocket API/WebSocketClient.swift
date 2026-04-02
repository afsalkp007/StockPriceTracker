public protocol WebSocketClient {
    func connect() async throws
    func disconnect()
    func send(_ message: String) async throws
    func receive() -> AsyncStream<Result<String, Error>>
}
