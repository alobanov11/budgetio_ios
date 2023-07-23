import ComposableArchitecture
import SwiftUI

struct RootFlow: View {
    struct State: Equatable {
        var path = StackState<Path.State>()
        var assetList = AssetList.State()
    }

    enum Action: Equatable {
        case assetList(AssetList.Action)
        case path(StackAction<Path.State, Path.Action>)
    }

    struct Path: ReducerProtocol {
        enum State: Equatable {
            case assetEdit(AssetEdit.State)
        }

        enum Action: Equatable {
            case assetEdit(AssetEdit.Action)
        }

        var body: some ReducerProtocolOf<Self> {
            Scope(state: /State.assetEdit, action: /Action.assetEdit) {
                AssetEdit()
            }
        }
    }

    let store: Store<State, Action>

    init() {
        self.store = Store(
            initialState: State(),
            reducer: {
                Scope(state: \.assetList, action: /Action.assetList) {
                    AssetList()
                }
                Reduce<State, Action> { state, action in
                    switch action {
                    case let .assetList(.route(.editAsset(asset))):
                        state.path.append(.assetEdit(AssetEdit.State(asset: asset)))
                        return .none

                    case .assetList(.route(.createAsset)):
                        state.path.append(.assetEdit(AssetEdit.State(asset: nil)))
                        return .none

                    case .assetList:
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
            AssetListView(store: store.scope(state: \.assetList, action: Action.assetList))
        } destination: { state in
            switch state {
            case .assetEdit:
                CaseLet(
                    state: /Path.State.assetEdit,
                    action: Path.Action.assetEdit,
                    then: AssetEditView.init(store:)
                )
            }
        }
    }
}

struct RootFlowPreview: PreviewProvider {
    static var previews: some View {
        withDependencies {
            $0.assetRepository.fetch = {
                [
                    AssetEntity(
                        id: AssetID(),
                        title: "Asset #1",
                        value: 20,
                        records: []
                    ),
                    AssetEntity(
                        id: AssetID(),
                        title: "Asset #2",
                        value: 40,
                        records: []
                    ),
                ]
            }
        } operation: {
            RootFlow()
        }
    }
}
