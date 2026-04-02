import Foundation
import StockPriceTracker

@MainActor
public final class WeakRefVirtualProxy<T: AnyObject> {
    private weak var object: T?

    public init(_ object: T) {
        self.object = object
    }
}

extension WeakRefVirtualProxy: ResourceErrorView where T: ResourceErrorView {
    public func display(_ viewModel: ResourceErrorViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRefVirtualProxy: ResourceLoadingView where T: ResourceLoadingView {
    public func display(_ viewModel: ResourceLoadingViewModel) {
        object?.display(viewModel)
    }
}

extension WeakRefVirtualProxy: ConnectionStatusViewProtocol where T: ConnectionStatusViewProtocol {
    public func display(_ viewModel: ConnectionStatusViewModel) {
        object?.display(viewModel)
    }
}
