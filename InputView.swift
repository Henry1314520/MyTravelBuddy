//
//  InputView.swift
//  MyTravelBuddy
//
//  Created by user02 on 2025/12/18.
//


import SwiftUI
import TipKit

struct InputView: View {
    // Binding 資料變數
    @State private var destination: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 3)
    @State private var budget: Double = 30000
    @State private var peopleCount: Int = 2
    @State private var isOutdoor: Bool = true
    @State private var transportation: String = "大眾運輸"
    @State private var selectedColor: Color = .blue // ColorPicker 用
    
    // AI 與 Navigation
    @StateObject private var aiService = AIService()
    @State private var showResult = false
    
    // TipKit
    let planTip = PlanTripTip()
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本資訊")) {
                    // 1. TextField
                    TextField("輸入目的地 (例如：東京)", text: $destination)
                        .padding(.vertical, 5)
                    
                    // 2. DatePicker (MultiDatePicker 較複雜，這裡示範 Range)
                    DatePicker("出發日期", selection: $startDate, displayedComponents: .date)
                    DatePicker("結束日期", selection: $endDate, displayedComponents: .date)
                }
                
                Section(header: Text("偏好設定")) {
                    // 3. Slider
                    VStack(alignment: .leading) {
                        Text("預算: \(Int(budget)) 元")
                        Slider(value: $budget, in: 10000...100000, step: 1000)
                    }
                    
                    // 4. Stepper
                    Stepper("人數: \(peopleCount) 人", value: $peopleCount, in: 1...10)
                    
                    // 5. Toggle
                    Toggle("包含戶外行程", isOn: $isOutdoor)
                    
                    // 6. Picker
                    Picker("交通方式", selection: $transportation) {
                        Text("大眾運輸").tag("大眾運輸")
                        Text("租車自駕").tag("租車自駕")
                        Text("包車接送").tag("包車接送")
                    }
                    
                    // 7. ColorPicker (裝飾用，設定主題色)
                    ColorPicker("主題顏色", selection: $selectedColor)
                }
                
                Section {
                    Button(action: {
                        Task {
                            await aiService.generateItinerary(
                                destination: destination,
                                days: 3, // 簡化計算
                                budget: budget,
                                outdoor: isOutdoor
                            )
                            showResult = true
                        }
                    }) {
                        HStack {
                            Spacer()
                            if aiService.isGenerating {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Text("✨ AI 生成行程")
                                    .bold()
                            }
                            Spacer()
                        }
                    }
                    .padding()
                    .background(destination.isEmpty ? Color.gray : selectedColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .disabled(destination.isEmpty || aiService.isGenerating)
                    .popoverTip(planTip) // 顯示 Tip
                }
            }
            .navigationTitle("AI 旅遊規劃師")
            .navigationDestination(isPresented: $showResult) {
                ResultView(
                    aiService: aiService,
                    destination: destination,
                    budget: budget,
                    isOutdoor: isOutdoor
                )
            }
        }
    }
}