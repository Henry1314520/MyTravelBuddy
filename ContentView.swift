import SwiftUI

struct ContentView: View {
    // 1. 引入 Auth ViewModel 來監聽登入狀態
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    var body: some View {
        Group {
            // 2. 判斷邏輯
            if authViewModel.isAuthenticated {
                // A. 如果已登入 -> 顯示主畫面 (包含 TabBar 和 Category)
                MainView()
            } else {
                // B. 如果未登入 -> 顯示歡迎頁 (或是登入頁)
                // 這裡要包 NavigationStack，這樣 WelcomeView 才能跳轉到 SignIn/SignUp
                NavigationStack {
                    WelcomeView()
                }
            }
        }
    }
}
