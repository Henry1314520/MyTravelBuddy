//
//  TravelApp.swift
//  MyTravelBuddy
//
//  Created by user02 on 2025/12/18.
//


import SwiftUI
import SwiftData
import TipKit

struct TravelApp: App {
    
    // 初始化 SwiftData Container
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Trip.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    init() {
        // 初始化 TipKit
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }

    var body: some Scene {
        WindowGroup {
            TabView {
                InputView()
                    .tabItem {
                        Label("規劃", systemImage: "map")
                    }
                
                HistoryView()
                    .tabItem {
                        Label("紀錄", systemImage: "clock")
                    }
            }
        }
        .modelContainer(sharedModelContainer) // 注入 SwiftData
    }
}
