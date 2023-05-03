//
//  Created by Антон Лобанов on 06.12.2022.
//

import SwiftUI

@main
struct BudgetioApp: App {
    let dependencies = Dependencies()

    var body: some Scene {
        WindowGroup {
            RootFlow(dependencies: dependencies)
        }
    }
}
