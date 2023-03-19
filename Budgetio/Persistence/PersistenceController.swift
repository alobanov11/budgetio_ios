//
//  Created by Антон Лобанов on 06.12.2022.
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    private var containerURL: URL {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.ru.alobanov11.budgetio")!
    }

    private init() {
        self.container = NSPersistentContainer(name: "Budgetio")
        let storeURL = self.containerURL.appendingPathComponent("Budgetio.sqlite")
        let description = NSPersistentStoreDescription(url: storeURL)
        self.container.persistentStoreDescriptions = [description]
        self.container.loadPersistentStores(completionHandler: { _, error in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        self.container.viewContext.automaticallyMergesChangesFromParent = true
    }
}
