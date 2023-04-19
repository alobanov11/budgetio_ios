//
//  Created by Антон Лобанов on 15.01.2023.
//

import Combine
import Foundation
import StoreSwift

final class AccountListStore: Store<AccountListModule> {

    private var accounts: [AccountEntity] = []
    private var cancelables: [AnyCancellable] = []

    private let accountRepository: IAccountRepository
    private let router: AccountListModule.Router

    init(
        accountRepository: IAccountRepository,
        router: AccountListModule.Router
    ) {
        self.accountRepository = accountRepository
        self.router = router

        super.init(initialState: .init())

        self.accountRepository.onUpdate
            .receive(on: DispatchQueue.main)
            .sink { [weak self] in
                self?.send(.accountsWasUpdated)
            }
            .store(in: &self.cancelables)
    }

    override func transform(_ intent: Intent<Action, Feedback>) -> Effect {
        switch intent {
        case .action(.viewAppear), .feedback(.accountsWasUpdated):
            return .combine(
                .mutate(.setLoading(true)),
                .run { [weak self] send in
                    guard let self else { return }
                    do {
                        let accounts = try await self.accountRepository.fetch()
                        await send(.didLoadAccounts(.success(accounts)))
                    }
                    catch {
                        await send(.didLoadAccounts(.failure(error)))
                    }
                }
            )

        case let .action(.didTapOnAccount(account)):
            if let model = self.accounts.first(where: { $0.id == account.id }) {
                self.router.onEditAccount(model)
            }
            return .none

        case .action(.didTapOnCreateAccount):
            self.router.onCreateAccount()
            return .none

        case let .feedback(.didLoadAccounts(result)):
            var effects: [Effect] = []
            switch result {
            case let .success(accounts):
                self.accounts = accounts
                effects.append(.mutate(.setAccounts(accounts)))

            case let .failure(error):
                print(error)
            }
            return .combine(effects + [.mutate(.setLoading(false))])
        }
    }

    override class func mutate(_ state: inout State, mutation: Mutation) {
        switch mutation {
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

private extension AccountListStore {

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

        return State.Account(
            id: account.id,
            title: account.title,
            proportion: String(format: "%.0f", proportion) + "%",
            originalProportion: account.proportion == 0 ? nil : String(account.proportion) + "%",
            value: account.value.formatted(.currency(code: "USD")),
            diff: diff == 0 ? nil : (diff > 0 ? "+" : "-") + String(format: "%.1f", abs(diff)),
            isPositive: diff > 0
        )
    }
}
