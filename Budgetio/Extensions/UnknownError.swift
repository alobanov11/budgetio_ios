//
//  Created by Антон Лобанов on 16.12.2022.
//

import Foundation
import CoreData

struct UnknownError: Error {
    let message: String
}

extension UnknownError {
	init(error: Error) {
		switch error._code {
		case NSManagedObjectConstraintMergeError:
			self.message = "The title is already taken"
		default:
			self.message = "Something went wrong"
		}
	}
}

extension UnknownError: LocalizedError {
    var errorDescription: String? {
        self.message
    }
}
