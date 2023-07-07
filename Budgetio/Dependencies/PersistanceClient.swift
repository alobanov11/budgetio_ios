import Foundation
import CoreData
import ComposableArchitecture

struct PersistanceClient {
    var context: () -> NSManagedObjectContext
}

extension PersistanceClient: DependencyKey {
    static let liveValue = PersistanceClient()
}

extension DependencyValues {
    var persistanceClient: PersistanceClient {
        get { self[PersistanceClient.self] }
        set { self[PersistanceClient.self] = newValue }
    }
}

private extension PersistanceClient {
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
