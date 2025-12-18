//
//  ResultView.swift
//  MyTravelBuddy
//
//  Created by user02 on 2025/12/18.
//


import SwiftUI
import Charts // 新技術：圖表
import SwiftData // 新技術：資料庫

struct ResultView: View {
    @ObservedObject var aiService: AIService
    var destination: String
    var budget: Double
    var isOutdoor: Bool
    
    @Environment(\.modelContext) private var modelContext // SwiftData Context
    @Environment(\.dismiss) var dismiss
    
    // 假資料用於圖表
    var budgetData: [BudgetDistribution] {
        [
            .init(category: "交通", amount: budget * 0.3),
            .init(category: "住宿", amount: budget * 0.4),
            .init(category: "餐飲", amount: budget * 0.2),
            .init(category: "購物", amount: budget * 0.1)
        ]
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                
                // 1. Lottie 動畫位置 (若有安裝 Lottie，放這裡)
                if aiService.isGenerating {
                   HStack {
                       Spacer()
                       Text("AI 正在思考中...")
                           .font(.headline)
                           .foregroundStyle(.secondary)
                       Spacer()
                   }
                   .padding()
                }
                
                // 2. 顯示 AI 串流文字
                VStack(alignment: .leading) {
                    Text("行程建議")
                        .font(.title2)
                        .bold()
                    
                    Text(aiService.generatedText)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .animation(.default, value: aiService.generatedText)
                }
                .padding(.horizontal)
                
                // 3. Swift Charts (加分項)
                if !aiService.isGenerating && !aiService.generatedText.isEmpty {
                    VStack(alignment: .leading) {
                        Text("預算預估佔比")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        Chart(budgetData) { item in
                            SectorMark(
                                angle: .value("Amount", item.amount),
                                innerRadius: .ratio(0.5),
                                angularInset: 1.5
                            )
                            .foregroundStyle(by: .value("Category", item.category))
                        }
                        .frame(height: 200)
                        .padding()
                    }
                    
                    // 4. 儲存按鈕
                    Button("儲存此行程") {
                        saveTrip()
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity)
                    .padding()
                }
            }
        }
        .navigationTitle(destination)
    }
    
    // SwiftData 儲存邏輯
    func saveTrip() {
        let newTrip = Trip(
            destination: destination,
            startDate: Date(),
            endDate: Date(),
            budget: budget,
            peopleCount: 2,
            isOutdoor: isOutdoor,
            transportation: "大眾運輸",
            itineraryContent: aiService.generatedText
        )
        modelContext.insert(newTrip)
        dismiss()
    }
}