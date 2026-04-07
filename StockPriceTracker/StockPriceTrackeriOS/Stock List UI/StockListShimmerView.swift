import SwiftUI

struct StockListShimmerView: View {
    var body: some View {
        ScrollView {
            LazyVStack(spacing: 12) {
                ForEach(0..<6, id: \.self) { _ in
                    StockRowPlaceholderView()
                }
            }
            .padding(.horizontal)
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .allowsHitTesting(false)
    }
}

private struct StockRowPlaceholderView: View {
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 8) {
                placeholder(width: 68, height: 18)
                placeholder(width: 144, height: 14)
            }

            Spacer(minLength: 16)

            VStack(alignment: .trailing, spacing: 8) {
                placeholder(width: 92, height: 18)
                placeholder(width: 84, height: 26)
            }

            placeholder(width: 10, height: 16)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
        .modifier(ShimmerModifier())
    }

    private func placeholder(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color(UIColor.secondarySystemFill))
            .frame(width: width, height: height)
    }
}

private struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = -1

    func body(content: Content) -> some View {
        content
            .overlay {
                GeometryReader { proxy in
                    LinearGradient(
                        colors: [
                            Color.white.opacity(0),
                            Color.white.opacity(0.65),
                            Color.white.opacity(0)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .frame(width: proxy.size.width * 0.65, height: proxy.size.height * 2)
                    .rotationEffect(.degrees(18))
                    .offset(x: phase * proxy.size.width * 1.6)
                }
                .mask(content)
                .allowsHitTesting(false)
            }
            .onAppear {
                phase = -1
                withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                    phase = 1.2
                }
            }
    }
}
