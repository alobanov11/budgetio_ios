//
//  Created by Антон Лобанов on 15.01.2023.
//

import Foundation
import StoreSwift

enum AccountListModule: Module {
    struct Router {
        let onCreateAccount: () -> Void
        let onEditAccount: (AccountEntity) -> Void
    }

    enum Action {
        case viewAppear
        case didTapOnAccount(State.Account)
        case didTapOnCreateAccount
    }

    enum Mutation {
        case setLoading(Bool)
        case setAccounts([AccountEntity])
    }

    enum Feedback {
        case accountsWasUpdated
        case didLoadAccounts(Result<[AccountEntity], Error>)
    }

    struct State: Equatable {
        var isDataLoaded = false
        var isLoading = false
        var data: [Account] = []
        var total = "0"
    }
}

extension AccountListModule.State {
    struct Account: Identifiable, Hashable {
        let id: AccountID?
        let title: String
        let proportion: String
        let originalProportion: String?
        let value: String
        let diff: String?
        let isPositive: Bool
    }
}
