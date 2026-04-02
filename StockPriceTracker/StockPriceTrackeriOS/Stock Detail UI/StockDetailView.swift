import SwiftUI
import Combine
import StockPriceTracker

public struct StockDetailView: View {
    @ObservedObject public var stateStore: StockDetailStateStore
    
    public init(stateStore: StockDetailStateStore) {
        self.stateStore = stateStore
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let viewModel = stateStore.viewModel {
                    headerView(for: viewModel)
                    Divider()
                    descriptionView(for: viewModel)
                } else if stateStore.isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 40)
                }
                
                if let error = stateStore.errorMessage {
                    Text(error)
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .padding()
        }
        .navigationTitle(stateStore.viewModel?.symbol ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func headerView(for viewModel: StockDetailViewModel) -> some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(viewModel.price)
                    .font(.system(size: 40, weight: .bold, design: .default))
                    .monospacedDigit()
                
                HStack(spacing: 8) {
                    PriceChangeView(
                        text: viewModel.priceChange,
                        isPositive: viewModel.isPositive
                    )
                    
                    Text("(\(viewModel.priceChangePercent))")
                        .font(.headline)
                        .foregroundColor(viewModel.isPositive ? .green : .red)
                }
            }
            Spacer()
        }
    }
    
    private func descriptionView(for viewModel: StockDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)
            
            Text(viewModel.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
    }
}

// State Store to bridge the UIKit-style Presenter protocol logic into SwiftUI
@MainActor
public final class StockDetailStateStore: ObservableObject {
    @Published public var viewModel: StockDetailViewModel?
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    
    public init() {}
}
