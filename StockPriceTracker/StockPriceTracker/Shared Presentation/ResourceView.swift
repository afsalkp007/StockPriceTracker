@MainActor
public protocol ResourceView<ResourceViewModel> {
    associatedtype ResourceViewModel
    func display(_ viewModel: ResourceViewModel)
}


@MainActor
public protocol ResourceLoadingView {
    func display(_ viewModel: ResourceLoadingViewModel)
}

@MainActor
public protocol ResourceErrorView {
    func display(_ viewModel: ResourceErrorViewModel)
}
