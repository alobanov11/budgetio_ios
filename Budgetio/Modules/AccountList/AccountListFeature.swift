//
//  Created by Антон Лобанов on 15.01.2023.
//

import Foundation
import StoreSwift

enum AccountListFeature: Feature {
    struct Router {
        let onCreateAccount: () -> Void
        let onEditAccount: (AccountEntity) -> Void
    }

    enum Action {
        case viewAppear
        case didTapOnAccount(State.Account)
        case didTapOnCreateAccount
    }

    enum Feedback {
        case accountsWasUpdated
    }

    enum Effect: Equatable {
        case setLoading(Bool)
        case setAccounts([AccountEntity])
    }

    enum Output: Equatable {
        case errorFetchingAccounts
    }

    struct State: Equatable {
        struct Account: Identifiable, Hashable {
            let id: AccountID?
            let title: String
            let proportion: String
            let originalProportion: String?
            let value: String
            let diff: String?
            let isPositive: Bool
            let records: [Record]
        }

        struct Record: Identifiable, Hashable {
            let id: RecordID?
            let date: Date
            let value: Double
        }

        var isDataLoaded = false
        var isLoading = false
        var data: [Account] = []
        var total = "0"
    }

    struct Enviroment {
        var accounts: [AccountEntity] = []

        let fetchAccounts: () async throws -> [AccountEntity]
        let sendAnalytics: (AnalyticsEvent) -> Void
        let router: Router
    }

    @MainActor
    static func store(
        with router: Router,
        dependencies: Dependencies
    ) -> Store<AccountListFeature> {
        Store<AccountListFeature>(
            initialState: State(),
            enviroment: Enviroment(
                fetchAccounts: { try await dependencies.accountRepository.fetch() },
                sendAnalytics: { dependencies.analyticsService.send($0) },
                router: router
            ),
            feedbacks: [
                dependencies.accountRepository.onUpdate
                    .map { .accountsWasUpdated }
                    .eraseToAnyPublisher(),
            ],
            middleware: self.middleware,
            reducer: self.reducer
        )
    }
}

extension AccountListFeature {
    static var middleware: Store<AccountListFeature>.Middleware {
        { _, env, intent in
            switch intent {
            case .action(.viewAppear), .feedback(.accountsWasUpdated):
                return .combine(
                    .effect(.setLoading(true)),
                    .run { env in
                        do {
                            let accounts = try await env.fetchAccounts()
                            env.accounts = accounts
                            return .combine(
                                .effect(.setAccounts(accounts)),
                                .effect(.setLoading(false))
                            )
                        }
                        catch {
                            return .combine(
                                .effect(.setLoading(false)),
                                .output(.errorFetchingAccounts)
                            )
                        }
                    }
                )

            case let .action(.didTapOnAccount(account)):
                guard let model = env.accounts.first(where: { $0.id == account.id }) else { return .none }
                env.router.onEditAccount(model)
                env.sendAnalytics(.tapOnAccount(
                    account.title,
                    position: env.accounts.firstIndex(of: model) ?? 0
                ))
                return .none

            case .action(.didTapOnCreateAccount):
                env.router.onCreateAccount()
                return .none
            }
        }
    }
}

extension AccountListFeature {
    static var reducer: Store<AccountListFeature>.Reducer {
        { state, effect in
            switch effect {
            case let .setLoading(value):
                state.isLoading = value

            case let .setAccounts(accounts):
                state.isDataLoaded = true

                let total = accounts.map { $0.value }.reduce(0, +)
                state.total = total.formatted(.currency(code: "USD"))
                state.data = accounts.map { self.mapAccount(with: $0, total: total) }
            }
        }
    }
}

extension AccountListFeature {
    static func mapAccount(with account: AccountEntity, total: Double) -> State.Account {
        let proportion: Double = {
            if total > 0, account.value > 0 {
                return (account.value / total) * 100
            }
            return 0
        }()

        let diff: Double = {
            guard account.proportion != 0 else { return 0 }
            let originalValue = total * (Double(account.proportion) / 100)
            return originalValue - account.value
        }()

        var records = account.records.map {
            State.Record(id: $0.id, date: $0.date, value: $0.value)
        }

        if records.count == 1 {
            let record = records[0]
            records = [
                .init(
                    id: nil,
                    date: record.date.addingTimeInterval(86400 * -1),
                    value: 0
                ),
            ] + records
        }

        return State.Account(
            id: account.id,
            title: account.title,
            proportion: String(format: "%.0f", proportion) + "%",
            originalProportion: account.proportion == 0 ? nil : String(account.proportion) + "%",
            value: account.value.formatted(.currency(code: "USD")),
            diff: diff == 0 ? nil : (diff > 0 ? "+" : "-") + String(format: "%.1f", abs(diff)),
            isPositive: diff > 0,
            records: records
        )
    }
}
