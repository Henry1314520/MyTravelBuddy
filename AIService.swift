//
//  AIService.swift
//  MyTravelBuddy
//

import Foundation
import Combine

@MainActor
class AIService: ObservableObject {

    @Published var generatedText: String = ""
    @Published var isGenerating: Bool = false
    
    // 1️⃣ 修改：換成你的 Groq API Key (gsk_...開頭)
    private let apiKey = " "

    // MARK: - Tool (Weather)
    func fetchWeather(for city: String) async -> String {
        try? await Task.sleep(nanoseconds: 1_000_000_000)
        return "\(city) 未來一週天氣晴朗，平均氣溫 25°C，適合戶外活動。"
    }

    // MARK: - Generate Itinerary
    func generateItinerary(
        destination: String,
        days: Int,
        budget: Double,
        outdoor: Bool
    ) async {

        isGenerating = true
        generatedText = ""

        let weatherInfo = await fetchWeather(for: destination)

        let prompt = """
        你是一位專業的旅遊規劃 AI，請用繁體中文回答。
        
        目的地：\(destination)
        天數：\(days)
        預算：\(Int(budget)) 元
        偏好：\(outdoor ? "戶外活動" : "室內文化")
        
        天氣資訊：
        \(weatherInfo)
        
        請條列每日行程，並給出實用建議。
        """

        // 2️⃣ 修改：網址換成 Groq 的 endpoint
        // 注意：Groq 為了相容 OpenAI，網址路徑也是 /v1/chat/completions，但前面是 api.groq.com
        let url = URL(string: "https://api.groq.com/openai/v1/chat/completions")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        // 3️⃣ 修改：模型換成 Llama 3 (目前 Groq 上最強且穩定的模型)
        // 推薦使用 "llama-3.3-70b-versatile" 或 "llama3-70b-8192"
        let body: [String: Any] = [
            "model": "llama-3.3-70b-versatile",
            "stream": true, // 你的程式碼已經支援 stream，這裡保持 true
            "messages": [
                ["role": "system", "content": "你是專業的旅遊規劃助手"],
                ["role": "user", "content": prompt]
            ]
        ]

        request.httpBody = try? JSONSerialization.data(withJSONObject: body)

        do {
            // 這裡保留我們剛剛修好的錯誤處理邏輯
            let (bytes, response) = try await URLSession.shared.bytes(for: request)

            guard let httpResponse = response as? HTTPURLResponse else {
                generatedText = "❌ 無法連接伺服器"
                isGenerating = false
                return
            }

            guard httpResponse.statusCode == 200 else {
                let errorData = try await bytes.reduce(into: Data()) { $0.append($1) }
                let errorStr = String(data: errorData, encoding: .utf8) ?? "未知錯誤"
                generatedText = "❌ API 錯誤 (\(httpResponse.statusCode))：\(errorStr)"
                isGenerating = false
                return
            }

            for try await line in bytes.lines {
                let line = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !line.isEmpty, line.hasPrefix("data: ") else { continue }

                let jsonString = line.replacingOccurrences(of: "data: ", with: "")
                if jsonString == "[DONE]" { break }

                if let data = jsonString.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   // Groq 的回傳格式跟 OpenAI 一樣，這裡不用改
                   let choices = json["choices"] as? [[String: Any]] {

                    for choice in choices {
                        if let delta = choice["delta"] as? [String: Any],
                           let content = delta["content"] as? String {
                            
                            // 更新 UI
                            self.generatedText += content
                        }
                    }
                }
            }

        } catch {
            generatedText = "❌ 產生失敗：\(error.localizedDescription)"
        }

        isGenerating = false
    }
}
