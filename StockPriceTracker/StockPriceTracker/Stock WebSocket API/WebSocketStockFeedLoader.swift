import Foundation

@MainActor
public final class WebSocketStockFeedLoader {
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
}

extension WebSocketStockFeedLoader: StockFeedLoader {
    
    public func startFeed() -> AsyncThrowingStream<[Stock], Error> {
        let (stream, continuation) = AsyncThrowingStream<[Stock], Error>.makeStream()
        self.continuation = continuation
        return stream
    }
}

extension WebSocketStockFeedLoader: StockFeedController {
    
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
}

// MARK: - Private Helpers

extension WebSocketStockFeedLoader {

    private enum FeedLoopResult {
        case sendLoopCompleted
        case receiveLoopCompleted(Error?)
    }

    private enum FeedCompletion {
        case none
        case finished
        case failed(Error)
    }

    private func runFeedLoop() async {
        var didConnect = false
        var completion: FeedCompletion = .none

        defer {
            if didConnect {
                client.disconnect()
            }
            finishContinuation(with: completion)
        }

        do {
            try await client.connect()
            didConnect = true
        } catch {
            completion = .failed(error)
            return
        }

        let result = await withTaskGroup(of: FeedLoopResult.self, returning: FeedLoopResult.self) { group in
            group.addTask { await self.sendLoop() }
            group.addTask { await self.receiveLoop() }

            let firstResult = await group.next() ?? .sendLoopCompleted
            group.cancelAll()
            while await group.next() != nil {}
            return firstResult
        }

        switch result {
        case .sendLoopCompleted:
            break
        case .receiveLoopCompleted(let error):
            completion = error.map(FeedCompletion.failed) ?? .finished
        }
    }

    private func sendLoop() async -> FeedLoopResult {
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

        return .sendLoopCompleted
    }

    private func receiveLoop() async -> FeedLoopResult {
        for await result in client.receive() {
            guard !Task.isCancelled else { return .receiveLoopCompleted(nil) }
            switch result {
            case .success(let message):
                guard let updates = try? StockMessageMapper.map(message) else { continue }
                for update in updates {
                    applyUpdate(update)
                }
                continuation?.yield(currentStocks())
            case .failure(let error):
                return .receiveLoopCompleted(error)
            }
        }

        return .receiveLoopCompleted(nil)
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

    private func finishContinuation(with completion: FeedCompletion) {
        switch completion {
        case .none:
            break
        case .finished:
            continuation?.finish()
            continuation = nil
        case .failed(let error):
            continuation?.finish(throwing: error)
            continuation = nil
        }
    }
}
