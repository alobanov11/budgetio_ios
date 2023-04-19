//
//  Created by Антон Лобанов on 15.01.2023.
//

import Combine
import Foundation
import StoreSwift

final class AccountEditStore: Store<AccountEditModule> {
    private var contentType: AccountEditModule.ContentType

    private let accountRepository: IAccountRepository
    private let router: AccountEditModule.Router

    init(
        contentType: AccountEditModule.ContentType,
        accountRepository: IAccountRepository,
        router: AccountEditModule.Router
    ) {
        self.contentType = contentType
        self.accountRepository = accountRepository
        self.router = router
        super.init(initialState: .init(isNewAccount: contentType.account == nil))
    }

    override func transform(_ intent: Intent<Action, Feedback>) -> Effect {
        switch intent {
        case .action(.viewAppear):
            switch self.contentType {
            case .new:
                return .none
            case let .edit(account):
                return .mutate(.setAccount(account))
            }

        case .action(.didEditTitle):
            let title = self.state.title
            if title.count > 20 {
                return .mutate(.setTitle(String(title.prefix(20))))
            }
            return .none

        case .action(.didEditProportion):
            let proportion = self.state.proportion
            if let value = Int(proportion), value > 100 {
                return .mutate(.setProportion("100"))
            }
            return .none

        case .action(.didEditValue):
            return .none

        case .action(.didTapOnDone):
            var account = self.contentType.account ?? AccountEntity()
            account.title = self.state.title
            account.value = Double(self.state.value) ?? 0
            account.proportion = Int(self.state.proportion) ?? 0

            do {
                _ = try self.accountRepository.save(account)
            }
            catch {
                print(error)
            }

            self.router.onDismiss()
            return .none

        case .action(.didTapOnDelete):
            guard let id = self.contentType.account?.id else { return .none }

            do {
                try self.accountRepository.delete(with: id)
            }
            catch {
                print(error)
            }

            self.router.onDismiss()
            return .none

        case .action(.didTapOnCancel):
            self.router.onDismiss()
            return .none

        case .feedback:
            return .none
        }
    }

    override class func mutate(_ state: inout State, mutation: Mutation) {
        switch mutation {
        case let .setAccount(account):
            state.title = account.title
            state.value = String(format: "%.2f", account.value)
            state.proportion = String(account.proportion)

        case let .setTitle(value):
            state.title = value

        case let .setProportion(value):
            state.proportion = value
        }
    }
}
