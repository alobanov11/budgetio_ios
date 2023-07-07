import SwiftUI
import ComposableArchitecture

struct RootFlow: View {
    struct State: Equatable {
        var path = StackState<Path.State>()
        var accountList = AccountList.State()
    }

    enum Action: Equatable {
        case accountList(AccountList.Action)
        case path(StackAction<Path.State, Path.Action>)
    }

    struct Path: ReducerProtocol {
        enum State: Equatable {
            case accountEdit(AccountEdit.State)
        }

        enum Action: Equatable {
            case accountEdit(AccountEdit.Action)
        }

        var body: some ReducerProtocolOf<Self> {
            Scope(state: /State.accountEdit, action: /Action.accountEdit) {
                AccountEdit()
            }
        }
    }

    let store: Store<State, Action>

    init() {
        self.store = Store(
            initialState: State(),
            reducer: {
                Scope(state: \.accountList, action: /Action.accountList) {
                    AccountList()
                }
                Reduce<State, Action> { state, action in
                    switch action {
                    case let .accountList(.route(.editAccount(account))):
                        state.path.append(.accountEdit(AccountEdit.State(account: account)))
                        return .none

                    case .accountList(.route(.createAccount)):
                        state.path.append(.accountEdit(AccountEdit.State(account: nil)))
                        return .none

                    case .accountList:
                        return .none

                    case .path:
                        return .none
                    }
                }.forEach(\.path, action: /Action.path) {
                    Path()
                }
            }
        )
    }

    var body: some View {
        NavigationStackStore(
            self.store.scope(state: \.path, action: Action.path)
        ) {
            AccountListView(store: store.scope(state: \.accountList, action: Action.accountList))
        } destination: { state in
            switch state {
            case .accountEdit:
                CaseLet(
                    state: /Path.State.accountEdit,
                    action: Path.Action.accountEdit,
                    then: AccountEditView.init(store:)
                )
            }
        }
    }
}

struct RootFlowPreview: PreviewProvider {
    static var previews: some View {
        withDependencies {
            $0.accountRepository.fetch = {
                [
                    AccountEntity(
                        id: AccountID(),
                        title: "Account #1",
                        value: 20,
                        proportion: 20,
                        records: []
                    ),
                    AccountEntity(
                        id: AccountID(),
                        title: "Account #2",
                        value: 40,
                        proportion: 40,
                        records: []
                    )
                ]
            }
        } operation: {
            RootFlow()
        }
    }
}
