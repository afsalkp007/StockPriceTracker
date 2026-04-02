import SwiftUI
import Combine
import StockPriceTracker

public struct StockListView: View {
    @ObservedObject public var stateStore: StockListStateStore
    public let onStart: () -> Void
    public let onStop: () -> Void
    public let onSort: (SortOption) -> Void
    public let onRowSelected: (String) -> Void
    
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
            
            List(stateStore.listViewModel.rows) { row in
                Button(action: { onRowSelected(row.symbol) }) {
                    StockRowView(viewModel: row)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(PlainButtonStyle())
            }
            .listStyle(PlainListStyle())
            .overlay(Group {
                if stateStore.isLoading && stateStore.listViewModel.rows.isEmpty {
                    ProgressView()
                }
            })
        }
        .navigationTitle(StockPresenter.title)
        .onAppear(perform: onStart)
        .onDisappear(perform: onStop)
    }
    
    private var toolbarView: some View {
        HStack {
            ConnectionStatusView(viewModel: stateStore.connectionViewModel)
            
            Spacer()
            
            Picker("Sort", selection: Binding(
                get: { stateStore.currentSort },
                set: { newSort in
                    stateStore.currentSort = newSort
                    onSort(newSort)
                }
            )) {
                Text("Price").tag(SortOption.byPrice)
                Text("Change").tag(SortOption.byPriceChange)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 150)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)
    }
}

// To bridge SwiftUI to Presenter without retaining SwiftUI views directly,
// we introduce a strictly Observable Object State Store.
@MainActor
public final class StockListStateStore: ObservableObject {
    @Published public var listViewModel = StockListViewModel(rows: [])
    @Published public var connectionViewModel = ConnectionStatusViewModel.disconnected
    @Published public var isLoading = false
    @Published public var errorMessage: String?
    @Published public var currentSort: SortOption = .byPrice
    public var rawStocks: [Stock] = []

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
