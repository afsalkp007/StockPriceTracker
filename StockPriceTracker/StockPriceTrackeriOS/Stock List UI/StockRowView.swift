import SwiftUI
import StockPriceTracker

public struct StockRowView: View {
    private let viewModel: StockRowViewModel
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    public init(viewModel: StockRowViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 12) {
                    headerContent
                    valueContent(alignment: .leading)
                }
            } else {
                HStack {
                    headerContent
                    
                    Spacer()
                    
                    valueContent(alignment: .trailing)
                    
                    chevron
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }

    private var headerContent: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.symbol)
                    .font(.headline)
                Text(viewModel.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(dynamicTypeSize.isAccessibilitySize ? 2 : 1)
            }
            
            if dynamicTypeSize.isAccessibilitySize {
                Spacer(minLength: 12)
                chevron
            }
        }
    }

    private func valueContent(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(viewModel.price)
                .font(.headline)
                .monospacedDigit()
            
            PriceChangeView(
                text: viewModel.priceChange,
                isPositive: viewModel.isPositive
            )
        }
    }

    private var chevron: some View {
        Image(systemName: "chevron.right")
            .font(.subheadline.weight(.semibold))
            .foregroundColor(Color(.tertiaryLabel))
            .padding(.leading, 8)
    }
}
