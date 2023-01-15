//
//  Created by Антон Лобанов on 06.12.2022.
//

import SwiftUI

@main
struct BudgetioApp: App {
    var accountRepository: IAccountRepository {
        AccountRepository(managedObjectContext: PersistenceController.shared.container.viewContext)
    }

    var body: some Scene {
        WindowGroup {
            RootFlow(accountRepository: accountRepository)
        }
    }
}
