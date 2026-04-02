public struct ResourceErrorViewModel {
    public let message: String?

    public static var noError: ResourceErrorViewModel {
        ResourceErrorViewModel(message: nil)
    }

    public static func error(message: String) -> ResourceErrorViewModel {
        ResourceErrorViewModel(message: message)
    }

    private init(message: String?) {
        self.message = message
    }
}
