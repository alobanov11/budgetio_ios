//
//  Created by Антон Лобанов on 15.01.2023.
//

import StoreSwift
import SwiftUI

struct AccountEditFlow: View {
    let contentType: AccountEditFeature.ContentType
    let dependencies: Dependencies

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            switch contentType {
            case .new:
                accountEditView(with: nil)
            case let .edit(account):
                accountEditView(with: account)
            }
        }
    }
}

private extension AccountEditFlow {
    @MainActor
    func accountEditView(with account: AccountEntity?) -> AccountEditView {
        let store = AccountEditFeature.store(
            with: account.map { .edit($0) } ?? .new,
            router: .init(onDismiss: { dismiss() }),
            dependencies: self.dependencies
        )
        return AccountEditView(store: store)
    }
}
