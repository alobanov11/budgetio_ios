import Charts
import StoreSwift
import SwiftUI

struct AssetListView: View {

    @StateObject var store: Store<AssetListUseCase>

    var body: some View {
        ZStack {
            if store.sections.isEmpty {
                emptyView
            }
            else {
                contentView
            }

            if let error = store.error {
                Text(error)
                    .foregroundColor(.red)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            store.send(.errorDisplayed)
                        }
                    }
            }

            if store.isLoading {
                ProgressView()
            }
        }
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                if !store.sections.isEmpty {
                    Menu {
                        Button(action: store.action(.addButtonTapped)) {
                            Label("Add asset", image: "plus.circle.fill")
                        }
                        Button(action: store.action(.proportionToggled)) {
                            Label(
                                "\(store.isProportionEnabled ? "Disable" : "Enable") proportions",
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
        .navigationTitle(store.total)
        .onAppear {
            store.send(.viewAppeared)
        }
    }

    var emptyView: some View {
        VStack(spacing: 16) {
            Text("Add you first asset")
                .font(.caption)
                .foregroundColor(.gray)

            Button("Create", action: store.action(.addButtonTapped))
                .buttonBorderShape(.capsule)
                .buttonStyle(.borderedProminent)
                .foregroundColor(Color(uiColor: .systemBackground))
        }
    }

    var contentView: some View {
        List {
            if let widget = store.widget {
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

            sectionsView
        }
    }

    var sectionsView: some View {
        ForEach(store.sections, id: \.self) { section in
            Section {
                ForEach(section.items, id: \.self) { item in
                    sectionRowView(item)
                }
            } header: {
                sectionHeaderView(section)
            }
        }
    }

    func sectionHeaderView(_ section: AssetListUseCase.Props.Section) -> some View {
        HStack {
            Text(section.name)

            Spacer()

            if section.items.count > 1 {
                Text(store.isProportionEnabled ? section.info + " (" + section.proportion + ")" : section.info)
            }
        }
    }

    func sectionRowView(_ item: AssetListUseCase.Props.Item) -> some View {
        HStack {
            Text(item.title)
                .font(.body)

            Spacer()

            Text(store.isProportionEnabled ? item.value + " (" + item.proportion + ")" : item.value)
                .font(.body)
        }
        .onTapGesture {
            store.send(.itemTapped(item))
        }
    }
}

struct AssetListPreview: PreviewProvider {
    static var previews: some View {
        NavigationView {
            AssetListView(store: Store(
                .init(
                    isLoading: false,
                    isItemsLoaded: true,
                    sections: [
                        .init(name: "Assets", info: "100$", proportion: "10%", items: [
                            .init(id: nil, title: "Bank", value: "$100.00", proportion: "10%"),
                            .init(id: nil, title: "Bank #2", value: "$200.00", proportion: "20%"),
                        ]),
                    ],
                    widget: .init(
                        data: [],
                        period: .month
                    ),
                    total: "$100.00",
                    error: nil
                )
            ))
        }
    }
}

