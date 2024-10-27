//
//  photoPPTApp.swift
//  photoPPT
//
//  Created by Figo on 2024/10/26.
//

import SwiftUI

@main
struct photoPPTApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
