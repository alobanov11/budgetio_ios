//
//  BudgetioApp.swift
//  Budgetio
//
//  Created by Антон Лобанов on 06.12.2022.
//

import SwiftUI

@main
struct BudgetioApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
