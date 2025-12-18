//
//  MyTravelBuddyApp.swift
//  MyTravelBuddy
//
//  Created by user02 on 2025/12/18.
//

import SwiftUI
import SwiftData
import TipKit

@main
struct MyTravelBuddyApp: App { // 這裡保持你的 App 名稱
    
    // 1. 初始化 SwiftData 資料庫容器
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Trip.self, // 確保 DataModels.swift 裡面的 Trip class 已經寫好了
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    // 2. 初始化 TipKit (操作說明功能)
    init() {
        try? Tips.configure([
            .displayFrequency(.immediate),
            .datastoreLocation(.applicationDefault)
        ])
    }

    var body: some Scene {
        WindowGroup {
            // 3. 這裡不放 ContentView()，改放我們的 TabView
            TabView {
                InputView() // 這是我們主要的輸入畫面
                    .tabItem {
                        Label("規劃", systemImage: "map")
                    }
                
                HistoryView() // 這是歷史紀錄畫面
                    .tabItem {
                        Label("紀錄", systemImage: "clock")
                    }
            }
        }
        .modelContainer(sharedModelContainer) // 4. 記得注入資料庫
    }
}
