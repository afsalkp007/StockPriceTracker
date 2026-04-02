import Foundation
import StockPriceTracker
import StockPriceTrackeriOS

@MainActor
public final class StockFeedPresentationAdapter {
    private let loader: () -> AsyncThrowingStream<[Stock], Error>
    public var presenter: LoadResourcePresenter<[Stock], StockViewAdapter>?
    
    // We hold a reference to the active iteration task so we don't leak it
    private var feedTask: Task<Void, Never>?

    public init(loader: @escaping () -> AsyncThrowingStream<[Stock], Error>) {
        self.loader = loader
    }

    public func didRequestFeedLoad() {
        presenter?.didStartLoading()
        
        feedTask?.cancel()
        feedTask = Task { [weak self] in
            guard let self else { return }
            do {
                let stream = self.loader()
                for try await stocks in stream {
                    guard !Task.isCancelled else { break }
                    self.presenter?.didFinishLoading(with: stocks)
                }
            } catch {
                guard !Task.isCancelled else { return }
                self.presenter?.didFinishLoading(with: error)
            }
        }
    }
    
    public func didCancelFeedLoad() {
        feedTask?.cancel()
        feedTask = nil
    }
}
