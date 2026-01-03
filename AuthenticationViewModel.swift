import Foundation
import Combine
import Supabase // 1. 引入 Supabase

@MainActor
class AuthenticationViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var isLoading = false
    @Published var errorMessage: String? = nil
    
    // 取得 Supabase 客戶端
    private let supabase = SupabaseManager.shared.client
    
    // 註冊方法
    func signUp(email: String, fullname: String, password: String, completion: @escaping (Bool) -> Void) async {
        self.isLoading = true
        self.errorMessage = nil
        
        do {
            // 呼叫 Supabase 註冊，將 fullname 放在 user_metadata
            let response = try await supabase.auth.signUp(
                email: email,
                password: password,
                data: ["full_name": .string(fullname)]
            )
            
            print("註冊成功，User ID: \(response.user.id)")
            
            // Supabase 預設需要 Email 驗證，這裡假設這一步就先當作成功
            self.isLoading = false
            completion(true)
            
        } catch {
            print("註冊失敗: \(error)")
            self.errorMessage = error.localizedDescription
            self.isLoading = false
            completion(false)
        }
    }
    func signIn(email: String, password: String, completion: @escaping (Bool) -> Void) async {
            self.isLoading = true
            self.errorMessage = nil
            
            do {
                let response = try await supabase.auth.signIn(email: email, password: password)
                print("登入成功，User ID: \(response.user.id)")
                
                self.isAuthenticated = true
                self.isLoading = false
                completion(true)
                
            } catch {
                print("登入失敗: \(error)")
                self.errorMessage = error.localizedDescription
                self.isLoading = false
                completion(false)
            }
        }
        
        // MARK: - 登出方法 (順便加一下)
        func signOut() async {
            try? await supabase.auth.signOut()
            self.isAuthenticated = false
        }
    }

