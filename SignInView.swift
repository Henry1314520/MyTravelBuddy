import SwiftUI

struct SignInView: View {
    // 1. 引入 ViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    @State var email: String = ""
    @State var password: String = ""
    @State var isPasswordVisible: Bool = false
    
    // 控制跳轉到主頁面
    @State private var isLoggedIn = false
    // 控制錯誤訊息
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            
            VStack {
                // 1. 標題
                Text("Log In")
                    .bold()
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, 24)
                
                // 2. 輸入框
                TextInput(value: $email, isPasswordVisible: .constant(true), isPasswordField: false, placeholder: "Enter Email")
                    .autocapitalization(.none)
                    .keyboardType(.emailAddress)
                
                TextInput(value: $password, isPasswordVisible: $isPasswordVisible, isPasswordField: true, placeholder: "Password")
                
                // 3. 忘記密碼
                NavigationLink {
                    // ForgotPasswordView() // 暫時註解，若有做這個 View 可以打開
                    Text("忘記密碼功能開發中...")
                } label: {
                    Text("Forgot Password?")
                        .foregroundColor(Color("green"))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .bold()
                }
                .padding(.bottom, 18)
                
                // 4. Login 按鈕 (修改為 Button + Task)
                Button {
                    Task {
                        await handleSignIn()
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color("green"))
                            .cornerRadius(12)
                    } else {
                        ButtonLabel(isDisabled: false, label: "Login")
                    }
                }
                .padding(.vertical, 18)
                .disabled(authViewModel.isLoading)
                
                // 5. OR 分隔線
                Text("OR")
                    .tracking(4)
                    .foregroundColor(Color("darkgrey"))
                    .padding(.vertical, 24)
                
                // 6. Social Buttons (暫不實作)
                HStack {
                    Button { print("Google Login") } label: {
                        SocialButton(imageName: "google", color: Color("darkgray"))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    }
                    Spacer()
                    Button { print("Facebook Login") } label: {
                        SocialButton(imageName: "facebook", color: Color("blue"))
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.gray.opacity(0.3), lineWidth: 1))
                    }
                }
                .frame(maxWidth: .infinity)
                
                // 7. 註冊連結
                Text("Don't have an account?").padding(.vertical, 18)
                
                NavigationLink(destination: SignUpView()) {
                    VStack {
                        Text("REGISTER")
                            .tracking(4)
                            .foregroundColor(Color("green"))
                            .padding(.bottom, 2)
                        
                        Rectangle()
                            .frame(width: 26, height: 1)
                            .foregroundColor(Color("green"))
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.top, 200)
            
        }
        .ignoresSafeArea()
        .navigationBarBackButtonHidden()
        .navigationBarHidden(true)
        .background(Color(.secondarySystemBackground))
        // 登入成功後跳轉到主頁面
        .navigationDestination(isPresented: $isLoggedIn) {
            HomeView() // 假設這是你的主頁面
                .navigationBarBackButtonHidden(true) // 登入後不讓使用者按返回鍵回到登入頁
        }
        // 錯誤提示
        .alert("登入失敗", isPresented: $showAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - 處理登入邏輯
    func handleSignIn() async {
        // 基本驗證
        guard !email.isEmpty, !password.isEmpty else {
            alertMessage = "請輸入 Email 和密碼"
            showAlert = true
            return
        }
        
        // 呼叫 ViewModel
        await authViewModel.signIn(email: email, password: password) { success in
            if success {
                print("登入成功！準備跳轉...")
                isLoggedIn = true
            } else {
                alertMessage = authViewModel.errorMessage ?? "帳號或密碼錯誤"
                showAlert = true
            }
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .environmentObject(AuthenticationViewModel()) // 記得注入
    }
}

// MARK: - SocialButton 元件定義
struct SocialButton: View {
    let imageName: String
    let color: Color
    
    var body: some View {
        HStack {
            // ⚠️ 注意：這需要你的 Assets.xcassets 裡有 "google" 和 "facebook" 的圖片
            // 如果沒有圖片，畫面會是空的。暫時可以用 systemName 替代測試：
            // Image(systemName: imageName == "google" ? "globe" : "network")
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(color)
        .cornerRadius(10)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
