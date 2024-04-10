//
//  Created by Антон Лобанов on 15.01.2023.
//

import CoreData
import Foundation

typealias AssetID = NSManagedObjectID

struct AssetEntity: Identifiable, Hashable {
    var id: AssetID?
    var title: String = ""
    var value: Double = 0
    var records: [RecordEntity] = []
    var isArchived = false
}
