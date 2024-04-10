import StoreSwift
import SwiftUI

@MainActor
struct RootFlow: View {

    enum Path: Hashable {

        case editAsset(AssetEntity?)
    }

    @State var path: [Path] = []

    let container: DependencyContainer

    var body: some View {
        NavigationStack(path: $path) {
            assetListView
                .navigationDestination(for: Path.self) { path in
                    switch path {
                    case let .editAsset(asset):
                        editAssetView(asset)
                    }
                }
        }
    }

    var assetListView: some View {
        AssetListView(store: Store(.init(), useCase: AssetListUseCase(
            calendar: container.calendar,
            isProportionEnabled: { container.localStorage.isProportionEnabled },
            setIsProportionEnabled: { container.localStorage.isProportionEnabled = $0 },
            fetchAssets: { try await container.assetRepository.fetch() },
            onSelectAsset: { path = [.editAsset($0)] },
            onCreateAsset: { path = [.editAsset(nil)] }
        )))
    }

    func editAssetView(_ asset: AssetEntity?) -> some View {
        AssetEditView(store: Store(.init(isNew: asset == nil), useCase: AssetEditUseCase(
            asset: asset,
            deleteAsset: { try await container.assetRepository.delete($0) },
            saveAsset: { _ = try await container.assetRepository.save($0) },
            onDismiss: { path = [] }
        )))
    }
}
