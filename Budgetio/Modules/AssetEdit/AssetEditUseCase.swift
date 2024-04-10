import Foundation
import StoreSwift

struct AssetEditUseCase: UseCase {

    struct Props: Equatable {

        var isLoading = false
        var title = ""
        var value = "0"
        var error: String?
        var isNew: Bool
    }

    let asset: AssetEntity?
    let deleteAsset: (AssetID) async throws -> Void
    let saveAsset: (AssetEntity) async throws -> Void
    let onDismiss: () -> Void
}

extension Action where U == AssetEditUseCase {

    static let viewAppeared = Self { props, useCase in
        guard let asset = useCase.asset else { return }
        await props {
            $0.title = asset.title
            $0.value = "\(Int(asset.value))"
        }
    }

    static let deleteTapped = Self { props, useCase in
        guard let id = useCase.asset?.id else { return }
        await props {
            $0.isLoading = true
        }
        do {
            try await useCase.deleteAsset(id)
            useCase.onDismiss()
        }
        catch {
            await props {
                $0.isLoading = false
                $0.error = error.localizedDescription
            }
        }
    }

    static let saveTapped = Self { props, useCase in
        let currentProps = await props.get()
        guard !currentProps.title.isEmpty else {
            await props {
                $0.error = "Title must not be empty"
            }
            return
        }
        await props {
            $0.isLoading = true
        }
        do {
            try await useCase.saveAsset(
                AssetEntity(
                    id: useCase.asset?.id,
                    title: currentProps.title,
                    value: Double(currentProps.value) ?? 0
                )
            )
            useCase.onDismiss()
        }
        catch {
            await props {
                $0.isLoading = false
                $0.error = error.localizedDescription
            }
        }
    }

    static let titleEdited = Self { _, _ in }

    static let valueEdited = Self { _, _ in }
}
