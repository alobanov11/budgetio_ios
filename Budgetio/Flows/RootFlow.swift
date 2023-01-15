//
//  Created by Антон Лобанов on 15.01.2023.
//

import SwiftUI
import StoreSwift

struct RootFlow: View {
	private enum SheetRoute: Hashable, Identifiable {
		case newAccount
		case editAccount(AccountEntity)

		var id: Int { hashValue }
	}

	let accountRepository: IAccountRepository

	@State private var sheetRoute: SheetRoute?

	var body: some View {
		NavigationView {
			accountListView
		}
		.sheet(item: $sheetRoute) { route in
			switch route {
			case .newAccount:
				AccountFlow(contentType: .new, accountRepository: accountRepository)
			case let .editAccount(account):
				AccountFlow(contentType: .edit(account), accountRepository: accountRepository)
			}
		}
	}
}

private extension RootFlow {
	@MainActor
	var accountListView: AccountListView {
		let router = AccountListModule.Router(
			onCreateAccount: { self.sheetRoute = .newAccount },
			onEditAccount: { self.sheetRoute = .editAccount($0) }
		)
		let store = AccountListStore(
			accountRepository: self.accountRepository,
			router: router
		)
		return AccountListView(store: store)
	}
}
