import SwiftUI
import StockPriceTracker

public struct ConnectionStatusView: View {
    private let viewModel: ConnectionStatusViewModel
    @ScaledMetric(relativeTo: .caption) private var indicatorSize = 8
    
    public init(viewModel: ConnectionStatusViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(viewModel.isConnected ? Color.green : Color.red)
                .frame(width: indicatorSize, height: indicatorSize)
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
            .onChange(of: isConnected) { resetAnimation() }
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
