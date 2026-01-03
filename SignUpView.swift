import SwiftUI

struct SignUpView: View {
    // 1. 引入 ViewModel
    @EnvironmentObject var authViewModel: AuthenticationViewModel
    
    @State var email: String = ""
    @State var fullname: String = ""
    @State var password: String = ""
    @State var confirmPassword: String = ""
    @State var isPasswordVisible: Bool = false
    @State var isConfirmPasswordVisible: Bool = false
    
    // 控制跳轉
    @State private var isRegistered = false
    // 控制錯誤 Alert
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            
            VStack {
                // 1. 標題
                Text("Register")
                    .bold()
                    .font(.largeTitle)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 78)
                    .padding(.bottom, 24)
                
                // 2. 輸入框
                TextInput(value: $fullname, isPasswordVisible: .constant(true), isPasswordField: false, placeholder: "Full Name")
                
                TextInput(value: $email, isPasswordVisible: .constant(true), isPasswordField: false, placeholder: "Enter Email")
                    .autocapitalization(.none) // Email 通常不需大寫
                    .keyboardType(.emailAddress)
                
                TextInput(value: $password, isPasswordVisible: $isPasswordVisible, isPasswordField: true, placeholder: "Password")
                
                TextInput(value: $confirmPassword, isPasswordVisible: $isConfirmPasswordVisible, isPasswordField: true, placeholder: "Confirm Password")
                
                // 3. Register 按鈕
                Button {
                    // 使用 Task 來執行非同步的 Supabase 請求
                    Task {
                        await handleSignUp()
                    }
                } label: {
                    if authViewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(Color("green")) // 使用你的主題色
                            .cornerRadius(12)
                    } else {
                        ButtonLabel(isDisabled: false, label: "Register")
                    }
                }
                .padding(.vertical, 18)
                .disabled(authViewModel.isLoading) // 防止重複點擊
                
                // 4. OR 分隔線
                Text("OR")
                    .tracking(4)
                    .foregroundColor(Color("darkgrey"))
                    .padding(.vertical, 24)
                
                // 5. Google & Facebook 按鈕 (保持原樣，暫不實作)
                HStack {
                    Button { print("Google Register") } label: {
                        SocialButton(imageName: "google", color: Color("white"))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                    Spacer()
                    Button { print("Facebook Register") } label: {
                        SocialButton(imageName: "facebook", color: Color("blue"))
                            .shadow(color: .black.opacity(0.15), radius: 4, x: 0, y: 2)
                    }
                }
                .frame(maxWidth: .infinity)
                
                // 6. 登入連結
                Text("Already have an account?").padding(.vertical, 18)
                
                NavigationLink(destination: SignInView()) {
                    VStack {
                        Text("LOGIN")
                            .tracking(4)
                            .foregroundColor(Color("green"))
                            .padding(.bottom, 2)
                        
                        Rectangle()
                            .frame(width: 26, height: 1)
                            .foregroundColor(Color("green"))
                    }
                }
            }
        }
        .ignoresSafeArea()
        .padding(.horizontal, 24)
        .navigationBarBackButtonHidden()
        .navigationBarHidden(true)
        .background(Color(.secondarySystemBackground))
        // 註冊成功後的導航 (跳轉到手機驗證或首頁)
        .navigationDestination(isPresented: $isRegistered) {
            EnterPhoneNumberView() // 或直接跳轉 HomeView()
        }
        // 錯誤提示
        .alert("註冊失敗", isPresented: $showAlert) {
            Button("確定", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
    
    // MARK: - 邏輯處理函數 (移到 body 之外)
    
    func handleSignUp() async {
        // 1. 基本驗證
        guard !fullname.isEmpty, !email.isEmpty, !password.isEmpty, !confirmPassword.isEmpty else {
            alertMessage = "請填寫所有欄位"
            showAlert = true
            return
        }
        
        guard password == confirmPassword else {
            alertMessage = "兩次輸入的密碼不一致"
            showAlert = true
            return
        }
        
        // 2. 呼叫 ViewModel 進行註冊
        await authViewModel.signUp(email: email, fullname: fullname, password: password) { success in
            if success {
                print("註冊成功！準備跳轉...")
                isRegistered = true
            } else {
                alertMessage = authViewModel.errorMessage ?? "發生未知錯誤"
                showAlert = true
            }
        }
    }
}

struct SignUpView_Previews: PreviewProvider {
    static var previews: some View {
        SignUpView()
            .environmentObject(AuthenticationViewModel()) // 記得注入
    }
}
