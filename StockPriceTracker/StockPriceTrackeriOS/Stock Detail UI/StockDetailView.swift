import SwiftUI
import Combine
import StockPriceTracker

public struct StockDetailView: View {
    @ObservedObject private var stateStore: StockDetailStateStore
    private let onRetryConnection: () -> Void
    
    public init(
        stateStore: StockDetailStateStore,
        onRetryConnection: @escaping () -> Void = {}
    ) {
        self.stateStore = stateStore
        self.onRetryConnection = onRetryConnection
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if let viewModel = stateStore.viewModel {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(viewModel.symbol)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        Text(viewModel.name)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .padding(.horizontal)
                    
                    VStack(spacing: 16) {
                        headerView(for: viewModel)
                        sparklineCard(for: viewModel)
                        descriptionView(for: viewModel)
                        
                        HStack(spacing: 16) {
                            detailCard(title: "Symbol", value: viewModel.symbol)
                            detailCard(title: "Company", value: viewModel.name)
                        }
                    }
                    .padding(.horizontal)
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
            .padding(.vertical)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(stateStore.viewModel?.symbol ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .alert(connectionRetryAlertTitle, isPresented: isShowingConnectionRetryAlert) {
            Button(connectionRetryAlert?.retryActionTitle ?? "") {
                stateStore.connectionRetryAlert = nil
                onRetryConnection()
            }
            Button(connectionRetryAlert?.cancelActionTitle ?? "", role: .cancel) {
                stateStore.connectionRetryAlert = nil
            }
        } message: {
            Text(connectionRetryAlert?.message ?? "")
        }
    }
    
    private func headerView(for viewModel: StockDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Current Price")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(viewModel.price)
                .font(.system(size: 40, weight: .bold, design: .default))
                .monospacedDigit()
                .contentTransition(.numericText())
                .animation(.default, value: viewModel.price)
            
            HStack(spacing: 8) {
                PriceChangeView(
                    text: viewModel.priceChange,
                    isPositive: viewModel.isPositive
                )
                
                Text(viewModel.priceChangePercent)
                    .font(.headline)
                    .foregroundColor(viewModel.isPositive ? .green : .red)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }
    
    private func sparklineCard(for viewModel: StockDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(StockDetailPresenter.priceHistoryTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.secondary)
                Spacer()
                Text(StockDetailPresenter.lastTicksTitle(viewModel.history.count))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            SparklineView(data: viewModel.history, isPositive: viewModel.isPositive)
                .frame(height: 80)
                .animation(.easeInOut(duration: 0.4), value: viewModel.history)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemGroupedBackground))
        )
    }
    
    private func descriptionView(for viewModel: StockDetailViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(StockDetailPresenter.aboutTitle)
                .font(.headline)
            
            Text(viewModel.description)
                .font(.body)
                .foregroundColor(.secondary)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }
    
    private func detailCard(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Color(.secondarySystemGroupedBackground)))
    }

    private var connectionRetryAlert: ConnectionRetryAlertViewModel? {
        stateStore.connectionRetryAlert
    }

    private var connectionRetryAlertTitle: String {
        connectionRetryAlert?.title ?? ""
    }

    private var isShowingConnectionRetryAlert: Binding<Bool> {
        Binding(
            get: { connectionRetryAlert != nil },
            set: { _ in }
        )
    }
}

@MainActor
public final class StockDetailStateStore: ObservableObject {
    @Published public var viewModel: StockDetailViewModel?
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var connectionRetryAlert: ConnectionRetryAlertViewModel?
    
    public init() {}
}
