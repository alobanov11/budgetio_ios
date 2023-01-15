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
        self.becomeObserver()
        self.obtainInitial()
    }

    override func dispatch(_ action: Action) {
        switch action {
        case let .didTapOnAccount(account):
            if let model = self.accounts.first(where: { $0.id == account.id }) {
                self.router.onEditAccount(model)
            }
        case .didTapOnCreateAccount:
            self.router.onCreateAccount()
        }
    }

    override class func reduce(_ state: inout State, effect: Effect) {
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

private extension AccountListStore {
    func obtainInitial() {
        self.invoke(effect: .setLoading(true))
        Task(priority: .userInitiated) {
            do {
                let accounts = try await self.accountRepository.fetch()
                self.accounts = accounts
                self.invoke(effect: .setAccounts(accounts))
                    .invoke(effect: .setLoading(false))
            }
            catch {
                self.throw(error)
                    .invoke(effect: .setLoading(false))
            }
        }
    }

    func becomeObserver() {
        self.cancelables.append(
            self.accountRepository.onUpdate
                .receive(on: DispatchQueue.main)
                .sink { [weak self] in
                    self?.obtainInitial()
                }
        )
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
            proportion: String(format: "%.1f", proportion) + "%",
            originalProportion: account.proportion == 0 ? nil : String(account.proportion) + "%",
            value: account.value.formatted(.currency(code: "USD")),
            diff: diff == 0 ? nil : (diff > 0 ? "+" : "-") + String(format: "%.1f", abs(diff)),
            isPositive: diff > 0
        )
    }
}
