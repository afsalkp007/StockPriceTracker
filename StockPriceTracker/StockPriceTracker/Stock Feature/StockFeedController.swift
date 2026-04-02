@MainActor
public protocol StockFeedController {
    func start()
    func stop() async
}

