import Charts
import ComposableArchitecture
import SwiftUI

struct AssetListView: View {
    let store: StoreOf<AssetList>

    var body: some View {
        WithViewStore(store.scope(state: \.view, action: { .view($0) })) {
            (viewStore: ViewStore<AssetList.View.State, AssetList.View.Action>) in
            ZStack {
                if viewStore.items.isEmpty {
                    VStack(spacing: 16) {
                        Text("Add you first asset")
                            .font(.caption)
                            .foregroundColor(.gray)

                        Button("Create", action: { viewStore.send(.addButtonTapped) })
                            .buttonBorderShape(.capsule)
                            .buttonStyle(.borderedProminent)
                            .foregroundColor(Color(uiColor: .systemBackground))
                    }
                }
                else {
                    List {
                        if let widget = viewStore.widget {
                            Section {
                                Chart(widget.data) {
                                    LineMark(
                                        x: .value("Date", $0.date),
                                        y: .value("Value", $0.value)
                                    )
                                }
                                .chartLegend(position: .top, alignment: .bottomTrailing)
                                .chartXAxis(.hidden)
                                .frame(height: 150)
                            }

                            Section {
                                HStack {
                                    Text("Saved")

                                    Spacer()

                                    Text(widget.saved)
                                        .foregroundColor(.green)
                                }

                                HStack {
                                    Text("Expense")

                                    Spacer()

                                    Text(widget.expense)
                                        .foregroundColor(.red)
                                }
                            }
                        }
                        Section("Assets") {
                            ForEach(viewStore.items, id: \.self) { item in
                                HStack {
                                    Text(item.title)
                                        .font(.body)

                                    Spacer()

                                    Text(item.value)
                                        .font(.body)
                                }
                                .onTapGesture {
                                    viewStore.send(.itemTapped(item))
                                }
                            }
                        }
                    }
                }

                if let error = viewStore.error {
                    Text(error)
                        .foregroundColor(.red)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                                viewStore.send(.errorDisplayed)
                            }
                        }
                }

                if viewStore.isLoading {
                    ProgressView()
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewStore.items.isEmpty {
                        Button(action: { viewStore.send(.addButtonTapped) }) {
                            Image(systemName: "plus.circle.fill")
                        }
                    }
                }
            }
            .navigationTitle(viewStore.total)
            .onAppear {
                viewStore.send(.viewAppeared)
            }
        }
    }
}

struct AssetListPreview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AssetListView(store: Store(
                initialState: AssetList.State(
                    view: AssetList.View.State(
                        isLoading: false,
                        isItemsLoaded: true,
                        items: [
                            AssetList.View.State.Item(id: nil, title: "Bank", value: "$100.00"),
                            AssetList.View.State.Item(id: nil, title: "Bank #2", value: "$200.00"),
                        ],
                        widget: AssetList.View.State.Widget(
                            data: [],
                            saved: "$5.00",
                            expense: "$100.00",
                            period: .month
                        ),
                        total: "$100.00",
                        error: nil
                    )
                ),
                reducer: EmptyReducer()
            ))
        }
    }
}
