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

        switch self.contentType {
        case .new:
            break
        case let .edit(account):
            self.invoke(effect: .setAccount(account))
        }
    }

    override func dispatch(_ action: Action) {
        switch action {
        case .didEditTitle:
            let title = self.state.title
            if title.count > 20 {
                self.invoke(effect: .setTitle(String(title.prefix(20))))
            }
        case .didEditProportion:
            let proportion = self.state.proportion
            if let value = Int(proportion), value > 100 {
                self.invoke(effect: .setProportion("100"))
            }
        case .didEditValue:
            break
        case .didTapOnDone:
            self.done()
        case .didTapOnDelete:
            self.delete()
        case .didTapOnCancel:
            self.router.onDismiss()
        }
    }

    override class func reduce(_ state: inout State, effect: Effect) {
        switch effect {
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

private extension AccountEditStore {
    func done() {
        var account = self.contentType.account ?? AccountEntity()
        account.title = self.state.title
        account.value = Double(self.state.value) ?? 0
        account.proportion = Int(self.state.proportion) ?? 0

        do {
            _ = try self.accountRepository.save(account)
            self.router.onDismiss()
        }
        catch {
            self.throw(error)
        }
    }

    func delete() {
        guard let id = self.contentType.account?.id else { return }
        do {
            try self.accountRepository.delete(with: id)
            self.router.onDismiss()
        }
        catch {
            self.throw(error)
        }
    }
}
