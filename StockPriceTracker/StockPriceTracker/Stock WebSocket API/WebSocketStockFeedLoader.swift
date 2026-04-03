import Foundation

@MainActor
public final class WebSocketStockFeedLoader: StockFeedLoader, StockFeedController {
    private let client: WebSocketClient
    private let updateInterval: TimeInterval
    private var stocks: [String: Stock]
    private var feedTask: Task<Void, Never>?
    private var activeFeedID: UUID?
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
        let feedID = UUID()
        activeFeedID = feedID
        feedTask = Task { [weak self] in
            guard let self else { return }
            defer { self.clearFeedTaskIfNeeded(for: feedID) }
            await self.runFeedLoop()
        }
    }

    public func stop() async {
        let task = feedTask
        feedTask = nil
        activeFeedID = nil
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

        defer { client.disconnect() }

        await withTaskGroup(of: Void.self) { group in
            group.addTask { await self.sendLoop() }
            group.addTask { await self.receiveLoop() }
            await group.next()
            group.cancelAll()
            while await group.next() != nil {}
        }
    }

    private func sendLoop() async {
        while !Task.isCancelled {
            var updates: [[String: Any]] = []
            for symbol in StockDescriptions.symbols {
                guard let current = stocks[symbol] else { continue }
                let newPrice = current.price * Double.random(in: 0.985...1.015)
                updates.append(["symbol": symbol, "price": newPrice])
            }
            
            if !updates.isEmpty, let payload = try? JSONSerialization.data(withJSONObject: updates), let message = String(data: payload, encoding: .utf8) {
                try? await client.send(message)
            }
            
            try? await Task.sleep(nanoseconds: UInt64(updateInterval * 1_000_000_000))
        }
    }

    private func receiveLoop() async {
        for await result in client.receive() {
            guard !Task.isCancelled else { break }
            switch result {
            case .success(let message):
                guard let updates = try? StockMessageMapper.map(message) else { continue }
                for update in updates {
                    applyUpdate(update)
                }
                continuation?.yield(currentStocks())
            case .failure(let error):
                continuation?.finish(throwing: error)
                return
            }
        }

        guard !Task.isCancelled else { return }
        continuation?.finish()
    }

    private func applyUpdate(_ update: StockMessageMapper.StockPriceUpdate) {
        guard var stock = stocks[update.symbol] else { return }
        stock.previousPrice = stock.price
        stock.price = update.price
        stock.history.append(update.price)
        if stock.history.count > 30 { stock.history.removeFirst() }
        stocks[update.symbol] = stock
    }

    private func currentStocks() -> [Stock] {
        StockDescriptions.symbols.compactMap { stocks[$0] }
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

    private func clearFeedTaskIfNeeded(for feedID: UUID) {
        guard activeFeedID == feedID else { return }
        feedTask = nil
        activeFeedID = nil
    }
}
