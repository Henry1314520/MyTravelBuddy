import SwiftUI
import Combine

// MARK: - 1. 資料模型 (Model)
// 定義從 API 接收回來的資料結構，必須遵循 Codable 協議
struct NotificationItem: Identifiable, Codable {
    let id: Int
    let title: String
    let body: String
    // JSONPlaceholder 的 API 欄位是 userId, id, title, body
    // 我們只需要用到 id, title, body
}

// MARK: - 2. 視圖模型 (ViewModel)
// 負責處理網路請求與資料狀態，讓 View 保持乾淨
@MainActor // 確保 UI 更新都在主執行緒
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [NotificationItem] = []
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    func fetchNotifications() async {
        self.isLoading = true
        self.errorMessage = nil
        
        // 這裡使用免費的測試 API
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/posts") else {
            self.isLoading = false
            self.errorMessage = "無效的 URL"
            return
        }
        
        do {
            // 發送網路請求 (Swift 5.5+ async/await 寫法)
            let (data, response) = try await URLSession.shared.data(from: url)
            
            // 檢查 HTTP 回應碼
            guard let httpResponse = response as? HTTPURLResponse,
                  httpResponse.statusCode == 200 else {
                self.isLoading = false
                self.errorMessage = "伺服器回應錯誤"
                return
            }
            
            // 解碼 JSON
            let decodedData = try JSONDecoder().decode([NotificationItem].self, from: data)
            
            // 更新 UI 資料 (只取前 10 筆模擬通知)
            self.notifications = Array(decodedData.prefix(10))
            self.isLoading = false
            
        } catch {
            self.isLoading = false
            self.errorMessage = "發生錯誤：\(error.localizedDescription)"
        }
    }
}

// MARK: - 3. 視圖 (View)
struct NotificationsView: View {
    // 建立 ViewModel 實例
    @StateObject private var viewModel = NotificationsViewModel()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // 情境 A: 載入中
                if viewModel.isLoading {
                    ProgressView("載入通知中...")
                }
                // 情境 B: 發生錯誤
                else if let error = viewModel.errorMessage {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(error)
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                        Button("重試") {
                            Task { await viewModel.fetchNotifications() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                }
                // 情境 C: 顯示資料列表
                else {
                    List(viewModel.notifications) { item in
                        HStack(alignment: .top, spacing: 12) {
                            // 模擬通知圖示
                            Image(systemName: "bell.badge.fill")
                                .foregroundStyle(.white, .red)
                                .font(.system(size: 20))
                                .frame(width: 40, height: 40)
                                .background(Color.blue.opacity(0.1))
                                .clipShape(Circle())
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.title)
                                    .font(.headline)
                                    .lineLimit(1) // 標題只顯示一行
                                
                                Text(item.body)
                                    .font(.subheadline)
                                    .foregroundColor(.gray)
                                    .lineLimit(2) // 內文最多兩行
                                    .fontDesign(.rounded)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                    .listStyle(.plain) // 列表樣式
                    .refreshable {
                        // 支援下拉更新
                        await viewModel.fetchNotifications()
                    }
                }
            }
            .navigationTitle("通知中心")
            // 當畫面出現時，觸發 API
            .task {
                if viewModel.notifications.isEmpty {
                    await viewModel.fetchNotifications()
                }
            }
        }
    }
}

struct NotificationsView_Previews: PreviewProvider {
    static var previews: some View {
        NotificationsView()
    }
}
