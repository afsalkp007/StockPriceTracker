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
                    headerView(for: viewModel)
                    sparklineCard(for: viewModel)
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
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text(viewModel.name)
                    .font(.title2)
                    .fontWeight(.semibold)
                
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
                    
                    Text("(\(viewModel.priceChangePercent))")
                        .font(.headline)
                        .foregroundColor(viewModel.isPositive ? .green : .red)
                }
            }
            Spacer()
        }
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
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.secondarySystemBackground))
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
