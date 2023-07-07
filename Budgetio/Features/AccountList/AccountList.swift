import Foundation
import ComposableArchitecture

struct AccountList: ReducerProtocol {
    struct State: Equatable {
        var view = View.State()
        var accounts: [AccountEntity] = []
    }

    enum Action: Equatable {
        enum Effect: Equatable {
            case accountsReceived(TaskResult<[AccountEntity]>)
        }

        enum Route: Equatable {
            case editAccount(AccountEntity)
            case createAccount
        }

        case view(View.Action)
        case effect(Effect)
        case route(Route)
    }

    @Dependency(\.accountRepository) var accountRepository

    var body: some ReducerProtocolOf<Self> {
        Scope(state: \.view, action: /Action.view) {
            EmptyReducer()
        }
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.viewAppeared):
                state.view.isLoading = true
                return .run { send in
                    await send(.effect(.accountsReceived(TaskResult {
                        try await self.accountRepository.fetch()
                    })))
                }

            case let .view(.itemTapped(item)):
                guard let account = state.accounts.first(where: { $0.id == item.id }) else {
                    return .none
                }
                return .send(.route(.editAccount(account)))

            case .view(.errorDisplayed):
                state.view.error = nil
                return .none

            case .view(.addButtonTapped):
                return .send(.route(.createAccount))

            case let .effect(.accountsReceived(.success(accounts))):
                state.view.isLoading = false
                state.view.isItemsLoaded = true
                state.view.items = accounts.map {
                    View.State.Item(
                        id: $0.id,
                        title: $0.title,
                        value: $0.value.formatted(.currency(code: "USD"))
                    )
                }
                state.view.total = accounts.map(\.value).reduce(0, +).formatted(.currency(code: "USD"))
                state.accounts = accounts
                return .none

            case let .effect(.accountsReceived(.failure(error))):
                state.view.isLoading = false
                state.view.error = error.localizedDescription
                return .none

            case .route:
                return .none
            }
        }
    }

    struct View {
        struct State: Equatable {
            struct Item: Identifiable, Hashable {
                let id: AccountID?
                let title: String
                let value: String
            }

            var isLoading = false
            var isItemsLoaded = false
            var items: [Item] = []
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
