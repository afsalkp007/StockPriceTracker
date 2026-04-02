import SwiftUI
import StockPriceTracker

public struct ConnectionStatusView: View {
    public let viewModel: ConnectionStatusViewModel
    
    public init(viewModel: ConnectionStatusViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(viewModel.isConnected ? Color.green : Color.red)
                .frame(width: 8, height: 8)
                .modifier(BlinkEffect(isConnected: viewModel.isConnected))
            
            Text(viewModel.label)
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

private struct BlinkEffect: ViewModifier {
    let isConnected: Bool
    @State private var isOpacityReduced = false
    
    func body(content: Content) -> some View {
        content
            .opacity(isOpacityReduced ? 0.3 : 1.0)
            .onAppear { resetAnimation() }
            .onChange(of: isConnected) { _ in resetAnimation() }
    }
    
    private func resetAnimation() {
        if isConnected {
            withAnimation(.easeInOut(duration: 0.8).repeatForever()) {
                isOpacityReduced = true
            }
        } else {
            withAnimation {
                isOpacityReduced = false
            }
        }
    }
}
