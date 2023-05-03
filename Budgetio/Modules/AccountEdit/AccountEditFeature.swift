//
//  Created by Антон Лобанов on 15.01.2023.
//

import Foundation
import StoreSwift

enum AccountEditFeature: Feature {

    enum ContentType {
        case new
        case edit(AccountEntity)

        var account: AccountEntity? {
            switch self {
            case .new:
                return nil
            case let .edit(account):
                return account
            }
        }
    }

    struct Router {

        let onDismiss: () -> Void
    }

    enum Action: Equatable {

        case viewAppear
        case didEditTitle
        case didEditValue
        case didEditProportion
        case didTapOnDone
        case didTapOnDelete
        case didTapOnCancel
    }

    enum Effect: Equatable {

        case setAccount(AccountEntity)
        case setTitle(String)
        case setProportion(String)
    }

    struct Enviroment {

        let saveAccount: (_: AccountEntity) async throws -> AccountEntity
        let deleteAccount: (_:AccountID) async throws -> Void
        let contentType: ContentType
        let router: Router
    }

    struct State: Equatable {

        var title = ""
        var proportion = ""
        var value = ""
        let isNewAccount: Bool
    }

    @MainActor
    static func store(
        with contentType: ContentType,
        router: Router,
        dependencies: Dependencies
    ) -> Store<AccountEditFeature> {
        Store<AccountEditFeature>(
            initialState: State(isNewAccount: contentType.account == nil),
            enviroment: Enviroment(
                saveAccount: { try dependencies.accountRepository.save($0) },
                deleteAccount: { try dependencies.accountRepository.delete(with: $0) },
                contentType: contentType,
                router: router
            ),
            middleware: self.middleware,
            reducer: self.reducer
        )
    }
}

extension AccountEditFeature {

    static var middleware: Store<AccountEditFeature>.Middleware {
        { state, env, intent in
            switch intent {
            case .action(.viewAppear):
                switch env.contentType {
                case .new:
                    return .none
                case let .edit(account):
                    return .effect(.setAccount(account))
                }

            case .action(.didEditTitle):
                let title = state.title
                if title.count > 20 {
                    return .effect(.setTitle(String(title.prefix(20))))
                }
                return .none

            case .action(.didEditProportion):
                let proportion = state.proportion
                if let value = Int(proportion), value > 100 {
                    return .effect(.setProportion("100"))
                }
                return .none

            case .action(.didEditValue):
                return .none

            case .action(.didTapOnDone):
                var account = env.contentType.account ?? AccountEntity()
                account.title = state.title
                account.value = Double(state.value) ?? 0
                account.proportion = Int(state.proportion) ?? 0
                return .run { env in
                    do {
                        _ = try await env.saveAccount(account)
                    }
                    catch {
                        print(error)
                    }
                    env.router.onDismiss()
                    return .none
                }

            case .action(.didTapOnDelete):
                guard let id = env.contentType.account?.id else { return .none }
                return .run { env in
                    do {
                        _ = try await env.deleteAccount(id)
                    }
                    catch {
                        print(error)
                    }
                    env.router.onDismiss()
                    return .none
                }

            case .action(.didTapOnCancel):
                env.router.onDismiss()
                return .none

            }
        }
    }
}

extension AccountEditFeature {

    static var reducer: Store<AccountEditFeature>.Reducer {
        { state, effect in
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
}
