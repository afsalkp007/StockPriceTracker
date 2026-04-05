import Foundation
import StockPriceTracker
import StockPriceTrackeriOS

@MainActor
final class StockFeedPresentationAdapter {
    private let loader: () -> AsyncThrowingStream<[Stock], Error>
    var presenter: LoadResourcePresenter<[Stock], StockViewAdapter>?
    var onFeedEnd: (() -> Void)?
    
    // We hold a reference to the active iteration task so we don't leak it
    private var feedTask: Task<Void, Never>?

    init(loader: @escaping () -> AsyncThrowingStream<[Stock], Error>) {
        self.loader = loader
    }

    deinit {
        feedTask?.cancel()
    }

    func didRequestFeedLoad() {
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
                guard !Task.isCancelled else { return }
                self.onFeedEnd?()
            } catch {
                guard !Task.isCancelled else { return }
                self.presenter?.didFinishLoading(with: error)
                self.onFeedEnd?()
            }
        }
    }
    
    func didCancelFeedLoad() async {
        let task = feedTask
        feedTask = nil
        task?.cancel()
        await task?.value
    }
}
