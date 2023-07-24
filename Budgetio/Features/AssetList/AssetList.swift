import ComposableArchitecture
import Foundation

struct AssetList: ReducerProtocol {
    struct State: Equatable {
        var view = View.State()
        var assets: [AssetEntity] = []
    }

    enum Action: Equatable {
        enum Effect: Equatable {
            case assetsReceived(TaskResult<[AssetEntity]>)
        }

        enum Route: Equatable {
            case editAsset(AssetEntity)
            case createAsset
        }

        case view(View.Action)
        case effect(Effect)
        case route(Route)
    }

    @Dependency(\.assetRepository) var assetRepository
    @Dependency(\.calendar) var calendar

    var body: some ReducerProtocolOf<Self> {
        Scope(state: \.view, action: /Action.view) {
            EmptyReducer()
        }
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.viewAppeared):
                state.view.isLoading = true
                return .run { send in
                    await send(.effect(.assetsReceived(TaskResult {
                        try await self.assetRepository.fetch()
                    })))
                }

            case let .view(.itemTapped(item)):
                guard let asset = state.assets.first(where: { $0.id == item.id }) else {
                    return .none
                }
                return .send(.route(.editAsset(asset)))

            case .view(.errorDisplayed):
                state.view.error = nil
                return .none

            case .view(.addButtonTapped):
                return .send(.route(.createAsset))

            case let .effect(.assetsReceived(.success(assets))):
                state.view.isLoading = false
                state.view.isItemsLoaded = true
                state.view.widget = self.widget(with: assets, for: .month)
                state.view.sections = assets.reduce(into: [View.State.Section(name: "Assets", items: [])]) { result, asset in
                    let nameComponents = asset.title.components(separatedBy: "/")
                    let item = View.State.Item(
                        id: asset.id,
                        title: nameComponents.last ?? asset.title,
                        value: asset.value.formatted(.currency(code: "USD"))
                    )

                    guard nameComponents.count == 2, let category = nameComponents.first else {
                        result[0].items.append(item)
                        result[0].items.sort { $0.title < $1.title }
                        return
                    }

                    if let categoryIndex = result.firstIndex(where: { $0.name == category }) {
                        result[categoryIndex].items.append(item)
                        result[categoryIndex].items.sort { $0.title < $1.title }
                    }
                    else {
                        result.append(View.State.Section(name: category, items: [item]))
                    }
                }.sorted { $0.name < $1.name }
                state.view.total = assets.map(\.value).reduce(0, +).formatted(.currency(code: "USD"))
                state.assets = assets
                return .none

            case let .effect(.assetsReceived(.failure(error))):
                state.view.isLoading = false
                state.view.error = error.localizedDescription
                return .none

            case .route:
                return .none
            }
        }
    }

    enum View {
        struct State: Equatable {
            enum Period: Equatable {
                case month
            }

            struct Section: Identifiable, Hashable {
                var id: String { self.name }
                let name: String
                var items: [Item]
            }

            struct Item: Identifiable, Hashable {
                let id: AssetID?
                let title: String
                let value: String
            }

            struct Widget: Equatable {
                struct Row: Equatable, Identifiable {
                    var id: Date { self.date }
                    let date: Date
                    let value: Double
                }

                let data: [Row]
                let saved: String
                let lost: String
                let period: Period
            }

            var isLoading = false
            var isItemsLoaded = false
            var sections: [Section] = []
            var widget: Widget?
            var total = "$000"
            var error: String?
        }

        enum Action: Equatable {
            case viewAppeared
            case itemTapped(State.Item)
            case errorDisplayed
            case addButtonTapped
        }
    }
}

private extension AssetList {
    func widget(with assets: [AssetEntity], for period: View.State.Period) -> View.State.Widget? {
        let period = self.calendar.weekdaySymbols.count * {
            switch period {
            case .month: return 4
            }
        }()

        let dates: [Date] = Array(-1 ..< period).compactMap {
            self.calendar.date(byAdding: .day, value: -$0, to: .now)
                .flatMap { self.calendar.startOfDay(for: $0) }
        }.reversed()

        guard
            let startDate = dates.first,
            let startOfMonthDate: Date = {
                let components = self.calendar.dateComponents([.year, .month], from: .now)
                return self.calendar.date(from: components)
            }()
        else { return nil }

        let records = assets.flatMap { $0.records }.filter { $0.date >= startOfMonthDate }
        let amountByDay = records.reduce(into: [Date: Double]()) { result, record in
            let date = self.calendar.startOfDay(for: record.date)
            result[date, default: 0] += record.amount
        }

        let lost = amountByDay.values.filter { $0 < 0 }.reduce(0, +)
        let saved = amountByDay.values.filter { $0 > 0 }.reduce(0, +) - lost

        let recordValues = assets
            .reduce(into: Dictionary(
                uniqueKeysWithValues: zip(dates, Array(repeating: Double(0), count: dates.count))
            )) { result, asset in
                let records = asset.records
                    .filter { $0.date >= startDate }
                    .sorted { $0.date < $1.date }

                guard let firstRecord = records.first else { return }

                var currentValue = firstRecord.value

                for date in result.keys.sorted(by: <) {
                    if let value = records.first(where: {
                        self.calendar.startOfDay(for: $0.date) == date
                    })?.value {
                        result[date, default: 0] += value
                        currentValue = value
                    }
                    else if date >= firstRecord.date {
                        result[date, default: 0] += currentValue
                    }
                }
            }

        guard recordValues.values.reduce(0, +) > 0 else { return nil }

        let data = recordValues.map {
            View.State.Widget.Row(
                date: $0.key,
                value: $0.value
            )
        }.sorted {
            $0.date < $1.date
        }.reduce(into: [View.State.Widget.Row]()) { result, row in
            if result.isEmpty || row.value > 0 {
                result.append(row)
            }
            else if let lastRow = result.last {
                result.append(View.State.Widget.Row(
                    date: row.date,
                    value: lastRow.value
                ))
            }
        }

        return View.State.Widget(
            data: data,
            saved: saved.formatted(.currency(code: "USD")),
            lost: lost.formatted(.currency(code: "USD")),
            period: .month
        )
    }
}
