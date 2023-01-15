//
//  Created by Антон Лобанов on 15.01.2023.
//

import SwiftUI
import StoreSwift

struct AccountFlow: View {
	let contentType: AccountEditModule.ContentType
	let accountRepository: IAccountRepository

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

private extension AccountFlow {
	@MainActor
	func accountEditView(with account: AccountEntity?) -> AccountEditView {
		let store = AccountEditStore(
			contentType: account.map { .edit($0) } ?? .new,
			accountRepository: self.accountRepository,
			router: .init(onDismiss: { dismiss() })
		)
		return AccountEditView(store: store)
	}
}
