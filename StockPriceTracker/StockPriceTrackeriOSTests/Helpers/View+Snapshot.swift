import SwiftUI

extension View {
    @MainActor
    func snapshot(for configuration: SnapshotConfiguration) -> UIImage {
        let controller = UIHostingController(rootView: self)
        return controller.snapshot(for: configuration)
    }
}
