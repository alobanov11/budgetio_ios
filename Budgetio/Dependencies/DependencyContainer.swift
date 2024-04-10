import Foundation

struct DependencyContainer {

    let persistanceClient: PersistanceClient
    let assetRepository: AssetRepository
    let localStorage: LocalStorage
    let calendar: Calendar

    init() {
        let persistanceClient = PersistanceClient()
        let calendar = Calendar.current
        self.persistanceClient = persistanceClient
        self.assetRepository = AssetRepository(persistanceClient: persistanceClient, calendar: calendar)
        self.localStorage = LocalStorage()
        self.calendar = calendar
    }
}
