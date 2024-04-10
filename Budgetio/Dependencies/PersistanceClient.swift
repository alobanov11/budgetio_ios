import CoreData
import UIKit

struct PersistanceClient {
    var context: () -> NSManagedObjectContext
}

extension PersistanceClient {
    init(inMemory: Bool = false, fileManager: FileManager = .default) {
        let container = NSPersistentContainer(name: "Budgetio")
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
        }
        else if let containerURL = fileManager.containerURL(
            forSecurityApplicationGroupIdentifier: "group.ru.alobanov11.budgetio"
        ) {
            let storeURL = containerURL.appendingPathComponent("Budgetio.sqlite")
            let description = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [description]
            container.loadPersistentStores(completionHandler: { _, error in
                if let error = error as NSError? {
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                }
            })
            container.viewContext.automaticallyMergesChangesFromParent = true
        }
        self.context = { container.viewContext }
    }
}
