//
//  Trip.swift
//  MyTravelBuddy
//
//  Created by user02 on 2025/12/18.
//


import SwiftUI
import SwiftData

// 定義旅遊行程的資料模型
@Model
class Trip: Identifiable {
    var id: UUID
    var destination: String
    var startDate: Date
    var endDate: Date
    var budget: Double
    var peopleCount: Int
    var isOutdoor: Bool
    var transportation: String
    var itineraryContent: String // AI 生成的文字內容
    var createdAt: Date

    init(destination: String, startDate: Date, endDate: Date, budget: Double, peopleCount: Int, isOutdoor: Bool, transportation: String, itineraryContent: String = "") {
        self.id = UUID()
        self.destination = destination
        self.startDate = startDate
        self.endDate = endDate
        self.budget = budget
        self.peopleCount = peopleCount
        self.isOutdoor = isOutdoor
        self.transportation = transportation
        self.itineraryContent = itineraryContent
        self.createdAt = Date()
    }
}

// 用於 Swift Charts 的預算分析資料結構
struct BudgetDistribution: Identifiable {
    let id = UUID()
    let category: String
    let amount: Double
}