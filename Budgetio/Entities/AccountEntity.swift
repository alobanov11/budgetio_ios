//
//  Created by Антон Лобанов on 15.01.2023.
//

import CoreData
import Foundation

typealias AccountID = NSManagedObjectID

struct AccountEntity: Identifiable, Hashable {
    var id: AccountID?
    var title: String = ""
    var value: Double = 0
    var proportion: Int = 0
}
