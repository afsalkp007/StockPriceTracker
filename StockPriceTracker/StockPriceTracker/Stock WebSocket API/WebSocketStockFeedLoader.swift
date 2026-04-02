import Foundation

@MainActor
public final class WebSocketStockFeedLoader: StockFeedLoader, StockFeedController {
    private let client: WebSocketClient
    private let updateInterval: TimeInterval
    private var stocks: [String: Stock]
    private var feedTask: Task<Void, Never>?
    private var continuation: AsyncThrowingStream<[Stock], Error>.Continuation?

    public init(client: WebSocketClient, updateInterval: TimeInterval = 1.5) {
        self.client = client
        self.updateInterval = updateInterval
        self.stocks = Self.makeInitialStocks()
    }

    public func startFeed() -> AsyncThrowingStream<[Stock], Error> {
        let (stream, continuation) = AsyncThrowingStream<[Stock], Error>.makeStream()
        self.continuation = continuation
        return stream
    }

    public func start() {
        guard feedTask == nil else { return }
        feedTask = Task { [weak self] in
            guard let self else { return }
            await self.runFeedLoop()
        }
    }

    public func stop() async {
        let task = feedTask
        feedTask = nil
        task?.cancel()
        client.disconnect()
        continuation?.finish()
        continuation = nil
        await task?.value
    }

    // MARK: - Private Helpers -

    private func runFeedLoop() async {
        do {
            try await client.connect()
        } catch {
            continuation?.finish(throwing: error)
            return
        }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.sendLoop() }
            group.addTask { await self.receiveLoop() }
        }
    }

    private func sendLoop() async {
        while !Task.isCancelled {
            for symbol in StockDescriptions.symbols {
                guard !Task.isCancelled else { return }
                guard let current = stocks[symbol] else { continue }
                let newPrice = current.price * Double.random(in: 0.985...1.015)
                try? await client.send(makeMessage(symbol: symbol, price: newPrice))
            }
            try? await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
        }
    }

    private func receiveLoop() async {
        for await result in client.receive() {
            guard !Task.isCancelled else { break }
            switch result {
            case .success(let message):
                guard let update = try? StockMessageMapper.map(message) else { continue }
                applyUpdate(update)
                continuation?.yield(currentStocks())
            case .failure(let error):
                continuation?.finish(throwing: error)
                return
            }
        }
    }

    private func applyUpdate(_ update: StockMessageMapper.StockPriceUpdate) {
        guard var stock = stocks[update.symbol] else { return }
        stock.previousPrice = stock.price
        stock.price = update.price
        stocks[update.symbol] = stock
    }

    private func currentStocks() -> [Stock] {
        StockDescriptions.symbols.compactMap { stocks[$0] }
    }

    private func makeMessage(symbol: String, price: Double) -> String {
        let payload: [String: Any] = ["symbol": symbol, "price": price]
        return (try? JSONSerialization.data(withJSONObject: payload))
            .flatMap { String(data: $0, encoding: .utf8) } ?? ""
    }

    private static func makeInitialStocks() -> [String: Stock] {
        StockDescriptions.catalog.reduce(into: [:]) { result, entry in
            let seedPrice = Double.random(in: 50...500)
            result[entry.key] = Stock(
                symbol: entry.key,
                name: entry.value.name,
                description: entry.value.description,
                price: seedPrice,
                previousPrice: seedPrice
            )
        }
    }
}
