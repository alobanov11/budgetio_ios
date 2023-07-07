import Foundation
import ComposableArchitecture

struct AccountEdit: ReducerProtocol {
    struct State: Equatable {
        var view = View.State()
        let account: AccountEntity?

        init(account: AccountEntity?) {
            self.view = View.State(isNew: account == nil)
            self.account = account
        }
    }

    enum Action: Equatable {
        case view(View.Action)
    }

    @Dependency(\.accountRepository) var accountRepository
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerProtocolOf<Self> {
        Scope(state: \.view, action: /Action.view) {
            View()
        }
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.viewAppeared):
                if let account = state.account {
                    state.view.title = account.title
                    state.view.value = "\(Int(account.value))"
                    state.view.proportion = "\(Int(account.proportion))"
                }
                return .none

            case .view(.deleteTapped):
                guard let id = state.account?.id else { return .none }
                do {
                    try self.accountRepository.delete(id)
                    return .run { _ in
                        await self.dismiss()
                    }
                }
                catch {
                    state.view.error = error.localizedDescription
                    return .none
                }

            case .view(.saveTapped):
                guard !state.view.title.isEmpty else {
                    state.view.error = "Title must not be empty"
                    return .none
                }
                do {
                    _ = try self.accountRepository.save(AccountEntity(
                        id: state.account?.id,
                        title: state.view.title,
                        value: Double(state.view.value) ?? 0,
                        proportion: Int(state.view.proportion) ?? 0,
                        records: []
                    ))
                    return .run { _ in
                        await self.dismiss()
                    }
                }
                catch {
                    state.view.error = error.localizedDescription
                    return .none
                }

            case .view(.errorDisplayed):
                state.view.error = nil
                return .none

            case .view(.binding):
                return .none
            }
        }
    }

    struct View: ReducerProtocol {
        struct State: Equatable {
            @BindingState var title = ""
            @BindingState var value = "0"
            @BindingState var proportion = "0"
            var error: String?
            var isNew = true
        }

        enum Action: Equatable, BindableAction {
            case viewAppeared
            case deleteTapped
            case saveTapped
            case errorDisplayed
            case binding(BindingAction<State>)
        }

        var body: some ReducerProtocolOf<Self> {
            BindingReducer()
        }
    }
}
