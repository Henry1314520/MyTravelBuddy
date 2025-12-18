//
//  HistoryView.swift
//  MyTravelBuddy
//
//  Created by user02 on 2025/12/18.
//


import SwiftUI
import SwiftData

struct HistoryView: View {
    // 新技術：@Query 自動從資料庫抓取資料並即時更新 UI
    @Query(sort: \Trip.createdAt, order: .reverse) private var trips: [Trip]
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(trips) { trip in
                    VStack(alignment: .leading) {
                        Text(trip.destination)
                            .font(.headline)
                        Text(trip.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: deleteItems)
            }
            .navigationTitle("歷史行程")
            .overlay {
                if trips.isEmpty {
                    ContentUnavailableView("尚無行程", systemImage: "airplane", description: Text("快去規劃你的第一個 AI 旅程吧！"))
                }
            }
        }
    }
    
    func deleteItems(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(trips[index])
            }
        }
    }
}