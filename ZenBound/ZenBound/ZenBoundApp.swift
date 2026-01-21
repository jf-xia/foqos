//
//  ZenBoundApp.swift
//  ZenBound
//
//  Created by Jack on 21/1/2026.
//

import SwiftUI
import SwiftData

@main
struct ZenBoundApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            //todo
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            // todo
        }
        .modelContainer(sharedModelContainer)
    }
}
