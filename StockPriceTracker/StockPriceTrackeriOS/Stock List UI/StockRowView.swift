import SwiftUI
import StockPriceTracker

public struct StockRowView: View {
    private let viewModel: StockRowViewModel
    
    public init(viewModel: StockRowViewModel) {
        self.viewModel = viewModel
    }
    
    public var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(viewModel.symbol)
                    .font(.headline)
                Text(viewModel.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text(viewModel.price)
                    .font(.headline)
                    .monospacedDigit()
                
                PriceChangeView(
                    text: viewModel.priceChange,
                    isPositive: viewModel.isPositive
                )
            }
            
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(Color(.tertiaryLabel))
                .padding(.leading, 8)
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(16)
    }
}
