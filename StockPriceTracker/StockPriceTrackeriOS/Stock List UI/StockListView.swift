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
        HStack {
            ConnectionStatusView(viewModel: stateStore.connectionViewModel)
            
            Spacer()
            
            Button(action: {
                if stateStore.connectionViewModel.isConnected {
                    onStop()
                } else {
                    onStart()
                }
            }) {
                Text(stateStore.connectionViewModel.controlTitle)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 6)
                    .background(stateStore.connectionViewModel.isConnected ? Color.red.opacity(0.15) : Color.green.opacity(0.15))
                    .foregroundColor(stateStore.connectionViewModel.isConnected ? .red : .green)
                    .cornerRadius(8)
            }
            
            Spacer()
            
            Picker(StockPresenter.sortTitle, selection: Binding(
                get: { stateStore.currentSort },
                set: { newSort in
                    stateStore.currentSort = newSort
                    onSort(newSort)
                }
            )) {
                Text(StockPresenter.sortByPriceTitle).tag(SortOption.byPrice)
                Text(StockPresenter.sortByChangeTitle).tag(SortOption.byPriceChange)
            }
            .pickerStyle(SegmentedPickerStyle())
            .frame(width: 150)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 2)
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

private struct StockListShimmerView: View {
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                ForEach(0..<6, id: \.self) { _ in
                    StockRowPlaceholderView()
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)

                    Divider()
                        .padding(.leading, 16)
                }
            }
        }
        .background(Color(UIColor.systemBackground))
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
        }
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
