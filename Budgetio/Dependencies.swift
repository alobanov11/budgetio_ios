//
//  Created by Антон Лобанов on 20.04.2023.
//

import Foundation

final class Dependencies {
    private(set) lazy var accountRepository: IAccountRepository = AccountRepository(
        managedObjectContext: self.persistanceController.container.viewContext
    )

    private(set) lazy var persistanceController = PersistenceController.shared

    private(set) lazy var analyticsService: IAnalyticsService = AnalyticsService()
}
