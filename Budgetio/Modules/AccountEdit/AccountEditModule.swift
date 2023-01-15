//
//  Created by Антон Лобанов on 15.01.2023.
//

import Foundation
import StoreSwift

enum AccountEditModule: Module {
	enum ContentType {
		case new
		case edit(AccountEntity)
	}

	struct Router {
		let onDismiss: () -> Void
	}

	enum Action: Equatable {
		case didEditTitle
		case didEditValue
		case didEditProportion
		case didTapOnDone
		case didTapOnDelete
		case didTapOnCancel
	}

	enum Effect: Equatable {
		case setAccount(AccountEntity)
		case setTitle(String)
		case setProportion(String)
	}

	struct State: Equatable {
		var title = ""
		var proportion = ""
		var value = ""
		let isNewAccount: Bool
	}
}

extension AccountEditModule.ContentType {
	var account: AccountEntity? {
		switch self {
		case .new:
			return nil
		case let .edit(account):
			return account
		}
	}
}
