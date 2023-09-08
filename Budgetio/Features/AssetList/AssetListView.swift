import Charts
import ComposableArchitecture
import SwiftUI

typealias AssetListViewStore = ViewStore<AssetList.View.State, AssetList.View.Action>

struct AssetListView: View {
    let store: StoreOf<AssetList>

    var body: some View {
        WithViewStore(store.scope(state: \.view, action: { .view($0) })) { (viewStore: AssetListViewStore) in
            ZStack {
                if viewStore.sections.isEmpty {
                    emptyView(viewStore)
                }
                else {
                    contentView(viewStore)
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
                    if !viewStore.sections.isEmpty {
                        Menu {
                            Button(action: { viewStore.send(.addButtonTapped) }) {
                                Label("Add asset", image: "plus.circle.fill")
                            }
                            Button(action: { viewStore.send(.proportionToggle) }) {
                                Label(
                                    "\(viewStore.isProportionEnabled ? "Disable" : "Enable") proportions",
                                    image: "arrow.up.arrow.down"
                                )
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 18))
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

    func emptyView(_ viewStore: AssetListViewStore) -> some View {
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

    func contentView(_ viewStore: AssetListViewStore) -> some View {
        List {
            if let widget = viewStore.widget {
                Section {
                    Chart(widget.data) {
                        LineMark(
                            x: .value("Date", $0.date),
                            y: .value("Value", $0.value)
                        )
                        .interpolationMethod(.catmullRom)
                    }
                    .chartYScale(domain: (widget.data.map { $0.value }.min() ?? 0) ... (widget.data.map { $0.value }.max() ?? 0))
                    .frame(height: 200)
                }
            }

            sectionsView(viewStore)
        }
    }

    func sectionsView(_ viewStore: AssetListViewStore) -> some View {
        ForEach(viewStore.sections, id: \.self) { section in
            Section {
                ForEach(section.items, id: \.self) { item in
                    sectionRowView(item, viewStore: viewStore)
                }
            } header: {
                sectionHeaderView(section, viewStore: viewStore)
            }
        }
    }

    func sectionHeaderView(_ section: AssetList.View.State.Section, viewStore: AssetListViewStore) -> some View {
        HStack {
            Text(section.name)

            Spacer()

            if section.items.count > 1 {
                Text(viewStore.isProportionEnabled ? section.info + " (" + section.proportion + ")" : section.info)
            }
        }
    }

    func sectionRowView(_ item: AssetList.View.State.Item, viewStore: AssetListViewStore) -> some View {
        HStack {
            Text(item.title)
                .font(.body)

            Spacer()

            Text(viewStore.state.isProportionEnabled ? item.value + " (" + item.proportion + ")" : item.value)
                .font(.body)
        }
        .onTapGesture {
            viewStore.send(.itemTapped(item))
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
                        sections: [
                            AssetList.View.State.Section(name: "Assets", info: "100$", proportion: "10%", items: [
                                AssetList.View.State.Item(id: nil, title: "Bank", value: "$100.00", proportion: "10%"),
                                AssetList.View.State.Item(id: nil, title: "Bank #2", value: "$200.00", proportion: "20%"),
                            ]),
                        ],
                        widget: AssetList.View.State.Widget(
                            data: [],
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
