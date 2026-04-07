import SwiftUI

struct StockDetailShimmerView: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                placeholder(width: 92, height: 34)
                placeholder(width: 160, height: 20)
            }
            .padding(.horizontal)

            VStack(spacing: 16) {
                priceCard
                historyCard
                aboutCard
                detailCards
            }
            .padding(.horizontal)
        }
        .padding(.vertical)
        .allowsHitTesting(false)
    }

    private var priceCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            placeholder(width: 96, height: 14)
            placeholder(width: 148, height: 34)
            HStack(spacing: 8) {
                placeholder(width: 88, height: 28)
                placeholder(width: 64, height: 18)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(cardBackground)
        .modifier(DetailShimmerModifier())
    }

    private var historyCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                placeholder(width: 112, height: 14)
                Spacer()
                placeholder(width: 72, height: 12)
            }

            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color(UIColor.secondarySystemFill))
                .frame(height: 80)
        }
        .padding()
        .background(cardBackground)
        .modifier(DetailShimmerModifier())
    }

    private var aboutCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            placeholder(width: 56, height: 18)
            VStack(alignment: .leading, spacing: 8) {
                placeholder(width: 220, height: 14)
                placeholder(width: 250, height: 14)
                placeholder(width: 186, height: 14)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(cardBackground)
        .modifier(DetailShimmerModifier())
    }

    @ViewBuilder
    private var detailCards: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(spacing: 16) {
                detailCard
                detailCard
            }
        } else {
            HStack(spacing: 16) {
                detailCard
                detailCard
            }
        }
    }

    private var detailCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            placeholder(width: 64, height: 14)
            placeholder(width: 118, height: 18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(cardBackground)
        .modifier(DetailShimmerModifier())
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color(.secondarySystemGroupedBackground))
    }

    private func placeholder(width: CGFloat, height: CGFloat) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(Color(UIColor.secondarySystemFill))
            .frame(width: width, height: height)
    }
}

private struct DetailShimmerModifier: ViewModifier {
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
