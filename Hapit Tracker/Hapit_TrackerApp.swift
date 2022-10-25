//
//  Hapit_TrackerApp.swift
//  Hapit Tracker
//
//  Created by Omar Abdulrahman on 25/10/2022.
//

import SwiftUI

@main
struct Hapit_TrackerApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
