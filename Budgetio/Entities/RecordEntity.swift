//
//  Created by Антон Лобанов on 15.01.2023.
//

import CoreData
import Foundation

typealias RecordID = NSManagedObjectID

struct RecordEntity: Identifiable, Hashable {
    var id: RecordID?
    var date: Date = .now
    var value: Double = 0
    var amount: Double = 0
}
