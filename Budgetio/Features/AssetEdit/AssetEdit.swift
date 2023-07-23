import ComposableArchitecture
import Foundation

struct AssetEdit: ReducerProtocol {
    struct State: Equatable {
        var view = View.State()
        let asset: AssetEntity?

        init(asset: AssetEntity?) {
            self.view = View.State(isNew: asset == nil)
            self.asset = asset
        }
    }

    enum Action: Equatable {
        case view(View.Action)
    }

    @Dependency(\.assetRepository) var assetRepository
    @Dependency(\.dismiss) var dismiss

    var body: some ReducerProtocolOf<Self> {
        Scope(state: \.view, action: /Action.view) {
            View()
        }
        Reduce<State, Action> { state, action in
            switch action {
            case .view(.viewAppeared):
                if let asset = state.asset {
                    state.view.title = asset.title
                    state.view.value = "\(Int(asset.value))"
                }
                return .none

            case .view(.deleteTapped):
                guard let id = state.asset?.id else { return .none }
                do {
                    try self.assetRepository.delete(id)
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
                    _ = try self.assetRepository.save(AssetEntity(
                        id: state.asset?.id,
                        title: state.view.title,
                        value: Double(state.view.value) ?? 0,
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
