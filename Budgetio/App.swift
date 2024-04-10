import SwiftUI

@main
struct BudgetioApp: App {
    let container = DependencyContainer()

    var body: some Scene {
        WindowGroup {
            RootFlow(container: container)
        }
    }
}
