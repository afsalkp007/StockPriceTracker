import SwiftUI
import Combine
import StockPriceTracker

public struct StockListView: View {
    @ObservedObject private var stateStore: StockListStateStore
    private let onStart: () -> Void
    private let onStop: () -> Void
    private let onSort: (SortOption) -> Void
    private let onRowSelected: (String) -> Void
    
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var hasAppeared = false
    
    public init(
        stateStore: StockListStateStore,
        onStart: @escaping () -> Void,
        onStop: @escaping () -> Void,
        onSort: @escaping (SortOption) -> Void,
        onRowSelected: @escaping (String) -> Void
    ) {
        self.stateStore = stateStore
        self.onStart = onStart
        self.onStop = onStop
        self.onSort = onSort
        self.onRowSelected = onRowSelected
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            if let error = stateStore.errorMessage {
                ErrorBannerView(message: error)
            }
            
            toolbarView
            
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(stateStore.listViewModel.rows) { row in
                        Button { onRowSelected(row.symbol) } label: {
                            StockRowView(viewModel: row)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(PlainButtonStyle())
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(Color(.systemGroupedBackground))
            .overlay(Group {
                if stateStore.isLoading && stateStore.listViewModel.rows.isEmpty {
                    StockListShimmerView()
                }
            })
        }
        .navigationTitle(StockPresenter.title)
        .onAppear {
            guard !hasAppeared else { return }
            hasAppeared = true
            onStart()
        }
        .onChange(of: scenePhase) { _, newPhase in
            handleScenePhaseChange(newPhase)
        }
    }

    private func handleScenePhaseChange(_ newPhase: ScenePhase) {
        if newPhase == .active {
            onStart()
        } else if newPhase == .background {
            onStop()
        }
    }
    
    private var toolbarView: some View {
        Group {
            if dynamicTypeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        ConnectionStatusView(viewModel: stateStore.connectionViewModel)
                        Spacer()
                        startStopButton
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text(StockPresenter.sortTitle)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                        menuSortPicker
                    }
                }
            } else {
                HStack(spacing: 12) {
                    ConnectionStatusView(viewModel: stateStore.connectionViewModel)
                    
                    Spacer()
                    
                    startStopButton
                    
                    segmentedSortPicker
                        .frame(maxWidth: 220)
                }
            }
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)
    }

    private var startStopButton: some View {
        Button {
            if stateStore.connectionViewModel.isConnected {
                onStop()
            } else {
                onStart()
            }
        } label: {
            Text(stateStore.connectionViewModel.controlTitle)
                .font(.subheadline)
                .fontWeight(.semibold)
                .padding(.horizontal, 16)
                .padding(.vertical, 6)
                .background(stateStore.connectionViewModel.isConnected ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                .foregroundColor(stateStore.connectionViewModel.isConnected ? .red : .green)
                .cornerRadius(8)
        }
    }

    private var segmentedSortPicker: some View {
        Picker(StockPresenter.sortTitle, selection: sortSelection) {
            Text(StockPresenter.sortByPriceTitle).tag(SortOption.byPrice)
            Text(StockPresenter.sortByChangeTitle).tag(SortOption.byPriceChange)
        }
        .pickerStyle(.segmented)
    }

    private var menuSortPicker: some View {
        Picker(StockPresenter.sortTitle, selection: sortSelection) {
            Text(StockPresenter.sortByPriceTitle).tag(SortOption.byPrice)
            Text(StockPresenter.sortByChangeTitle).tag(SortOption.byPriceChange)
        }
        .pickerStyle(.menu)
    }

    private var sortSelection: Binding<SortOption> {
        Binding(
            get: { stateStore.currentSort },
            set: { newSort in
                stateStore.currentSort = newSort
                onSort(newSort)
            }
        )
    }
}

@MainActor
public final class StockListStateStore: ObservableObject {
    @Published public var listViewModel = StockListViewModel(rows: [])
    @Published public var connectionViewModel = ConnectionStatusViewModel.disconnected
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var currentSort: SortOption = .byPrice
    @Published public var rawStocks: [Stock] = []

    public init() {}
}

private struct ErrorBannerView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.footnote)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(Color.red)
    }
}
