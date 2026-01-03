import SwiftUI
import Combine
import MarkdownUI
import FoundationModels // 保留原本的框架引用

// MARK: - 0. 設定檔 (Configuration)

struct GroqConfig {
    
    static let apiKey = ""
    
    static let model = "llama-3.3-70b-versatile"
}

// MARK: - 1. 結構化資料模型 (保留原樣)

@Generable
struct DailyPlan {
    let day: Int
    let title: String
    let activities: [String]
    let tips: String
}

@Generable
struct TravelPlan {
    let destination: String
    let days: Int
    let overview: String
    let budgetBreakdown: String
    let itinerary: [DailyPlan]
    let recommendations: [String]
}

// MARK: - 2. 邏輯層 (Service - 整合版)

@MainActor
class AIService: ObservableObject {
    
    @Published var generatedText: String = ""
    @Published var isGenerating: Bool = false
    @Published var currentPhase: String = "準備中"
    
    
    private func fetchWeather(for city: String) async -> String {
        try? await Task.sleep(nanoseconds: 500_000_000) 
        let weatherData = [
            "台北": "多雲時晴，氣溫 22-28°C，午後偶有陣雨。",
            "東京": "晴朗乾燥，氣溫 15-22°C，適合散步。",
            "京都": "涼爽舒適，氣溫 14-20°C，早晚溫差大。",
            "首爾": "乾冷，氣溫 10-18°C，需穿著保暖。",
            "巴黎": "陰雨綿綿，氣溫 12-16°C，請攜帶雨具。"
        ]
        return weatherData[city] ?? "\(city) 未來一週天氣晴朗，平均氣溫 25°C，適合戶外活動。"
    }
    
    private func calculateBudget(total: Double, people: Int, days: Int) async -> String {
        let perPerson = Int(total) / people
        let daily = Int(total) / days
        return """
        總預算 NT$\(Int(total)) (\(people)人)，平均每人 NT$\(perPerson)。
        平均每日可用全體預算 NT$\(daily)。
        建議分配：住宿35%, 餐飲30%, 交通20%, 門票購物15%。
        """
    }
    
    func generateItinerary(
        destination: String,
        days: Int,
        budget: Double,
        peopleCount: Int,
        outdoor: Bool,
        customQuestion: String
    ) async {
        isGenerating = true
        generatedText = ""
        currentPhase = "🔍 查詢天氣與物價..."
        
        // 1. 執行工具 (Pre-processing)
        let weatherInfo = await fetchWeather(for: destination)
        let budgetInfo = await calculateBudget(total: budget, people: peopleCount, days: days)
        
        currentPhase = "🚀 Groq AI 正在高速規劃..."
        
        // 2. 構建 Prompt
        let systemPrompt = """
        你是一位專業的旅遊規劃 AI 助手。
        
        【已獲取資訊】
        - 天氣預報：\(weatherInfo)
        - 預算分析：\(budgetInfo)
        
        請根據以上資訊與用戶需求，設計一份詳細的旅遊行程。
        請務必用【繁體中文】回答。
        格式請清晰易讀，包含每日上午、下午、晚上的具體景點與美食推薦。
        """
        
        let userPrompt = """
        請規劃行程：
        - 目的地：\(destination)
        - 天數：\(days) 天
        - 人數：\(peopleCount) 人
        - 偏好：\(outdoor ? "戶外自然冒險" : "室內文化與購物")
        - 特殊需求：\(customQuestion)
        """
        
        // 3. 呼叫 Groq API
        guard let url = URL(string: "https://api.groq.com/openai/v1/chat/completions") else { return }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(GroqConfig.apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": GroqConfig.model,
            "stream": true,
            "temperature": 0.6,
            "max_tokens": 4096,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": userPrompt]
            ]
        ]
        
        request.httpBody = try? JSONSerialization.data(withJSONObject: body)
        
        do {
            let (bytes, response) = try await URLSession.shared.bytes(for: request)
            
            // 🔥 錯誤處理核心：檢查 HTTP 狀態碼 (解決 -1011 錯誤)
            guard let httpResponse = response as? HTTPURLResponse else {
                generatedText = "❌ 網路錯誤：無效的回應"
                return
            }
            
            if !(200...299).contains(httpResponse.statusCode) {
                var errorMsg = ""
                for try await line in bytes.lines { errorMsg += line }
                print("❌ API Error: \(errorMsg)")
                generatedText = "❌ 伺服器錯誤 (Code: \(httpResponse.statusCode))\n請檢查 API Key 是否正確。\n詳細錯誤：\(errorMsg)"
                isGenerating = false
                return
            }
            
            // 4. 處理串流回應 (SSE)
            for try await line in bytes.lines {
                let line = line.trimmingCharacters(in: .whitespacesAndNewlines)
                guard line.hasPrefix("data: "), line != "data: [DONE]" else { continue }
                
                let jsonStr = line.replacingOccurrences(of: "data: ", with: "")
                
                if let data = jsonStr.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                   let choices = json["choices"] as? [[String: Any]],
                   let delta = choices.first?["delta"] as? [String: Any],
                   let content = delta["content"] as? String {
                    
                    // 更新 UI
                    self.generatedText += content
                }
            }
            currentPhase = "✅ 完成"
            
        } catch {
            generatedText = "❌ 發生錯誤：\(error.localizedDescription)"
        }
        
        isGenerating = false
    }
}

// MARK: - 3. UI 元件 (保留你的設計)

struct InfoCard: View {
    let icon: String; let title: String; let value: String; let color: Color
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(color.opacity(0.15)).frame(width: 48, height: 48)
                Image(systemName: icon).font(.system(size: 20, weight: .semibold)).foregroundColor(color)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.caption).foregroundColor(.secondary)
                Text(value).font(.system(size: 16, weight: .semibold))
            }
            Spacer()
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

struct GradientButton: View {
    let title: String; let icon: String; let action: () -> Void; let isDisabled: Bool; let isLoading: Bool
    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading { ProgressView().tint(.white) } else { Image(systemName: icon) }
                Text(title).bold()
            }
            .frame(maxWidth: .infinity).padding(.vertical, 16)
            .background(LinearGradient(colors: isDisabled ? [.gray] : [Color.blue, Color.purple], startPoint: .leading, endPoint: .trailing))
            .foregroundColor(.white).cornerRadius(16)
            .shadow(color: isDisabled ? .clear : .blue.opacity(0.4), radius: 8, y: 4)
        }
        .disabled(isDisabled)
    }
}

struct FeatureTag: View {
    let text: String; let color: Color
    var body: some View {
        Text(text).font(.caption2).bold().padding(.horizontal, 8).padding(.vertical, 4)
            .background(color.opacity(0.15)).foregroundColor(color).cornerRadius(6)
    }
}

// MARK: - 4. 結果頁面 (Result View)

struct AIResultView: View {
    @ObservedObject var aiService: AIService
    let destination: String
    let budget: Double
    let peopleCount: Int
    let tripDays: Int
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground).ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header (保持不變)
                HStack {
                    VStack(alignment: .leading) {
                        Text(destination).font(.title).bold()
                        Text("AI 為您規劃的 \(tripDays) 天旅程").font(.caption).foregroundColor(.secondary)
                    }
                    Spacer()
                    Image(systemName: "sparkles.rectangle.stack.fill")
                        .font(.title)
                        .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .top, endPoint: .bottom))
                }
                .padding()
                .background(Color.white)
                
                // Content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        if aiService.isGenerating && aiService.generatedText.isEmpty {
                            VStack(spacing: 20) {
                                Spacer()
                                ProgressView().scaleEffect(1.5)
                                Text(aiService.currentPhase).foregroundColor(.secondary)
                                Spacer()
                            }
                            .frame(height: 300)
                        } else {
                            // --- 修改這裡：使用 Markdown 取代 Text ---
                            Markdown(aiService.generatedText)
                                .markdownTheme(.gitHub) // 選擇風格：gitHub, docC, basic
                                .padding()
                                .background(Color.white)
                                .cornerRadius(12)
                                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
                            // -------------------------------------
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}
// MARK: - 5. 輸入頁面 (Input View)

struct AIInputView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var aiService = AIService()
    
    @State private var destination: String = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 3)
    @State private var budget: Double = 30000
    @State private var peopleCount: Int = 2
    @State private var isOutdoor: Bool = true
    @State private var customQuestion: String = ""
    @State private var showResult = false
    
    private var tripDays: Int {
        let days = Calendar.current.dateComponents([.day], from: startDate, to: endDate).day ?? 0
        return max(1, days + 1)
    }
    
    var body: some View {
        ZStack {
            LinearGradient(colors: [Color(red: 0.95, green: 0.97, blue: 1), .white], startPoint: .topLeading, endPoint: .bottomTrailing)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header
                    VStack(spacing: 8) {
                        Image(systemName: "airplane.departure")
                            .font(.system(size: 50))
                            .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                        Text("AI 旅遊規劃").font(.system(size: 32, weight: .bold))
                        HStack {
                            FeatureTag(text: "Streaming", color: .green)
                        }.padding(.top, 4)
                    }.padding(.top, 20)
                    
                    // Input Fields
                    VStack(alignment: .leading, spacing: 20) {
                        // 1. 目的地
                        VStack(alignment: .leading) {
                            Label("目的地", systemImage: "location.fill").font(.headline).foregroundColor(.blue)
                            TextField("例如：京都、台北、倫敦", text: $destination)
                                .padding().background(Color.white).cornerRadius(10).shadow(color: .black.opacity(0.05), radius: 5)
                        }
                        
                        // 2. 日期
                        VStack(alignment: .leading) {
                            Label("日期 (\(tripDays)天)", systemImage: "calendar").font(.headline).foregroundColor(.orange)
                            HStack {
                                DatePicker("開始", selection: $startDate, displayedComponents: .date).labelsHidden()
                                Text("至")
                                DatePicker("結束", selection: $endDate, displayedComponents: .date).labelsHidden()
                            }
                        }
                        
                        // 3. 預算與人數
                        VStack(alignment: .leading) {
                            Label("預算與人數", systemImage: "dollarsign.circle.fill").font(.headline).foregroundColor(.green)
                            HStack {
                                Text("總預算: \(Int(budget))")
                                Slider(value: $budget, in: 10000...200000, step: 5000)
                            }
                            Stepper("人數: \(peopleCount) 人", value: $peopleCount, in: 1...10)
                        }
                        
                        // 4. 偏好
                        Toggle(isOn: $isOutdoor) {
                            HStack {
                                Image(systemName: isOutdoor ? "figure.hiking" : "building.2.fill")
                                Text(isOutdoor ? "偏好戶外活動" : "偏好室內文化")
                            }
                        }.tint(.pink)
                        
                        // 5. 備註
                        VStack(alignment: .leading) {
                            Label("特殊需求", systemImage: "bubble.left").font(.headline).foregroundColor(.cyan)
                            TextField("例如：想吃燒肉、要有親子設施...", text: $customQuestion)
                                .padding().background(Color.white).cornerRadius(10)
                        }
                    }
                    .padding()
                    
                    // Button
                    GradientButton(
                        title: aiService.isGenerating ? "正在規劃..." : "✨ 開始規劃",
                        icon: "sparkles",
                        action: {
                            Task {
                                await aiService.generateItinerary(
                                    destination: destination,
                                    days: tripDays,
                                    budget: budget,
                                    peopleCount: peopleCount,
                                    outdoor: isOutdoor,
                                    customQuestion: customQuestion
                                )
                                showResult = true
                            }
                        },
                        isDisabled: destination.isEmpty || aiService.isGenerating,
                        isLoading: aiService.isGenerating
                    )
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
        .navigationDestination(isPresented: $showResult) {
            AIResultView(
                aiService: aiService,
                destination: destination,
                budget: budget,
                peopleCount: peopleCount,
                tripDays: tripDays
            )
        }
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - 6. 主入口 (ContentView)

struct AIView: View {
    @State private var isNavigating = false
    
    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                Text("Travel AI")
                    .font(.largeTitle)
                    .fontWeight(.heavy)
                    .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .leading, endPoint: .trailing))
                
                Text("生成您的夢想行程")
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.bottom, 40)
                
                // 你指定的雙線條按鈕樣式
                Button {
                    isNavigating = true
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        Rectangle().frame(width: 22, height: 2.5).foregroundColor(.black)
                        Rectangle().frame(width: 16, height: 2.5).foregroundColor(.black)
                    }
                    .padding(20)
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.black.opacity(0.1), lineWidth: 1))
                }
                .navigationDestination(isPresented: $isNavigating) {
                    // 跳轉到輸入頁面
                    AIInputView()
                }
                
                Spacer()
            }
        }
    }
}

#Preview {
    AIInputView()
}
//“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”
