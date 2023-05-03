//
//  Created by Антон Лобанов on 15.01.2023.
//

import StoreSwift
import SwiftUI

struct RootFlow: View {
    private enum SheetRoute: Hashable, Identifiable {
        case newAccount
        case editAccount(AccountEntity)

        var id: Int { hashValue }
    }

    let dependencies: Dependencies

    @State private var sheetRoute: SheetRoute?

    var body: some View {
        NavigationView {
            accountListView
        }
        .sheet(item: $sheetRoute) { route in
            switch route {
            case .newAccount:
                AccountEditFlow(contentType: .new, dependencies: dependencies)
            case let .editAccount(account):
                AccountEditFlow(contentType: .edit(account), dependencies: dependencies)
            }
        }
    }
}

private extension RootFlow {
    @MainActor
    var accountListView: AccountListView {
        let router = AccountListFeature.Router(
            onCreateAccount: { self.sheetRoute = .newAccount },
            onEditAccount: { self.sheetRoute = .editAccount($0) }
        )
        let store = AccountListFeature.store(
            with: router,
            dependencies: self.dependencies
        )
        return AccountListView(store: store)
    }
}
