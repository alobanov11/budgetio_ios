import Foundation
import StoreSwift

struct AssetListUseCase: UseCase {

    struct Props: Equatable {

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

    class Context {

        var assets: [AssetEntity] = []
    }

    let calendar: Calendar
    let isProportionEnabled: () -> Bool
    let setIsProportionEnabled: (Bool) -> Void
    let fetchAssets: () async throws -> [AssetEntity]
    let onSelectAsset: (AssetEntity) -> Void
    let onCreateAsset: () -> Void
    let context = Context()
}

extension Action where U == AssetListUseCase {

    static let viewAppeared = Self { props, useCase in
        await props {
            $0.isLoading = true
            $0.isProportionEnabled = useCase.isProportionEnabled()
        }
        do {
            let assets = try await useCase.fetchAssets()
            useCase.context.assets = assets
            await props {
                $0.isLoading = false
                $0.isItemsLoaded = true
                $0.widget = .init(with: assets, calendar: useCase.calendar, for: .month)
                let total = assets.map(\.value).reduce(0, +)
                $0.total = total.formatted(.currency(code: "USD"))
                $0.sections = assets.filter { !$0.isArchived }.reduce(into: [String: [AssetEntity]]()) { result, asset in
                    let nameComponents = asset.title.components(separatedBy: "/")
                    let category = nameComponents.count == 2 ? nameComponents.first : nil
                    result[category ?? "Assets", default: []].append(asset)
                }.map { key, value in
                    let categoryTotal = value.map(\.value).reduce(0, +)
                    let proportion = Int((categoryTotal / total) * 100)
                    return U.Props.Section(
                        name: key,
                        info: categoryTotal.formatted(.currency(code: "USD")),
                        proportion: "\(proportion)%",
                        items: value.map {
                            U.Props.Item(
                                id: $0.id,
                                title: $0.title.components(separatedBy: "/").last ?? $0.title,
                                value: $0.value.formatted(.currency(code: "USD")),
                                proportion: total > 0 && $0.value > 0 ? "\(Int($0.value * 100 / total))%" : "0%"
                            )
                        }
                    )
                }.sorted { $0.name < $1.name }
            }
        }
        catch {
            await props {
                $0.isLoading = false
                $0.error = error.localizedDescription
            }
        }
    }

    static func itemTapped(_ item: U.Props.Item) -> Self {
        return Self { props, useCase in
            guard let asset = useCase.context.assets.first(where: { $0.id == item.id }) else {
                return
            }
            useCase.onSelectAsset(asset)
        }
    }

    static var errorDisplayed = Self { props, _ in
        await props {
            $0.error = nil
        }
    }

    static var addButtonTapped = Self { _, useCase in
        useCase.onCreateAsset()
    }

    static var proportionToggled = Self { props, useCase in
        let newValue = !useCase.isProportionEnabled()
        useCase.setIsProportionEnabled(newValue)
        await props {
            $0.isProportionEnabled = newValue
        }
    }
}

private extension AssetListUseCase.Props.Widget {

    init?(
        with assets: [AssetEntity],
        calendar: Calendar,
        for period: AssetListUseCase.Props.Period
    ) {
        guard let firstDate = Set(assets.flatMap { $0.records }.map { $0.date }).min() else { return nil }

        let fromDate = calendar.startOfDay(for: firstDate)
        let toDate = calendar.startOfDay(for: .now)
        let numberOfDays = calendar.dateComponents([.day], from: fromDate, to: toDate)

        guard let daysInPeriod = numberOfDays.day else { return nil }

        let dates: [Date] = Array(-1 ..< daysInPeriod).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: .now)
                .flatMap { calendar.startOfDay(for: $0) }
        }.reversed()

        guard
            let startDate = dates.first,
            let startOfMonthDate: Date = {
                let components = calendar.dateComponents([.year, .month], from: .now)
                return calendar.date(from: components)
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
                        calendar.startOfDay(for: $0.date) == date
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
            Row(
                date: $0.key,
                value: $0.value
            )
        }.sorted {
            $0.date < $1.date
        }.reduce(into: [Row]()) { result, row in
            if result.isEmpty || row.value > 0 {
                result.append(row)
            }
            else if let lastRow = result.last {
                result.append(Row(
                    date: row.date,
                    value: lastRow.value
                ))
            }
        }

        self.data = data
        self.period = period
    }
}
