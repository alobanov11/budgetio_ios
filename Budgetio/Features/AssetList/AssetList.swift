import ComposableArchitecture
import Foundation
import SwiftUI

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
    @AppStorage("isProportionEnabled") var isProportionEnabled = false

    var body: some ReducerProtocolOf<Self> {
        Scope(state: \.view, action: /Action.view) {
            EmptyReducer()
        }
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.viewAppeared):
                state.view.isLoading = true
                state.view.isProportionEnabled = self.isProportionEnabled
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

            case .view(.proportionToggle):
                state.view.isProportionEnabled.toggle()
                self.isProportionEnabled = state.view.isProportionEnabled
                return .none

            case let .effect(.assetsReceived(.success(assets))):
                state.view.isLoading = false
                state.view.isItemsLoaded = true
                state.view.widget = self.widget(with: assets, for: .month)
                let total = assets.map(\.value).reduce(0, +)
                state.view.sections = assets.reduce(into: [String: [AssetEntity]]()) { result, asset in
                    let nameComponents = asset.title.components(separatedBy: "/")
                    let category = nameComponents.count == 2 ? nameComponents.first : nil
                    result[category ?? "Assets", default: []].append(asset)
                }.map { key, value in
                    let categoryTotal = value.map(\.value).reduce(0, +)
                    let proportion = Int((categoryTotal / total) * 100)
                    return View.State.Section(
                        name: key,
                        info: categoryTotal.formatted(.currency(code: "USD")),
                        proportion: "\(proportion)%",
                        items: value.map {
                            View.State.Item(
                                id: $0.id,
                                title: $0.title.components(separatedBy: "/").last ?? $0.title,
                                value: $0.value.formatted(.currency(code: "USD")),
                                proportion: total > 0 && $0.value > 0 ? "\(Int($0.value * 100 / total))%" : "0%"
                            )
                        }
                    )
                }.sorted { $0.name < $1.name }
                state.view.total = total.formatted(.currency(code: "USD"))
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
                let info: String
                let proportion: String
                var items: [Item]
            }

            struct Item: Identifiable, Hashable {
                let id: AssetID?
                let title: String
                let value: String
                let proportion: String
            }

            struct Widget: Equatable {
                struct Row: Equatable, Identifiable {
                    var id: Date { self.date }
                    let date: Date
                    let value: Double
                }

                let data: [Row]
                let period: Period
            }

            var isLoading = false
            var isItemsLoaded = false
            var isProportionEnabled = false
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
            case proportionToggle
        }
    }
}

private extension AssetList {
    func widget(with assets: [AssetEntity], for _: View.State.Period) -> View.State.Widget? {
        guard let firstDate = Set(assets.flatMap { $0.records }.map { $0.date }).min() else { return nil }

        let fromDate = self.calendar.startOfDay(for: firstDate)
        let toDate = self.calendar.startOfDay(for: .now)
        let numberOfDays = self.calendar.dateComponents([.day], from: fromDate, to: toDate)

        guard let period = numberOfDays.day else { return nil }

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
            period: .month
        )
    }
}
