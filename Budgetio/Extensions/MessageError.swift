//
//  Created by Антон Лобанов on 16.12.2022.
//

import CoreData
import Foundation

struct MessageError: Error {
    let message: String
}

extension MessageError {
    init(error: Error) {
        switch error._code {
        case NSManagedObjectConstraintMergeError:
            self.message = "The title is already taken"
        default:
            self.message = "Something went wrong"
        }
    }
}

extension MessageError: LocalizedError {
    var errorDescription: String? {
        self.message
    }
}
