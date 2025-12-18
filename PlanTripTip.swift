//
//  PlanTripTip.swift
//  MyTravelBuddy
//
//  Created by user02 on 2025/12/18.
//


import TipKit

struct PlanTripTip: Tip {
    var title: Text {
        Text("開始規劃")
    }
    
    var message: Text? {
        Text("填寫完資料後，點擊此按鈕讓 AI 為您生成專屬行程！")
    }
    
    var image: Image? {
        Image(systemName: "sparkles")
    }
}