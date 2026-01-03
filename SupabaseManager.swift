import Foundation
import Supabase

class SupabaseManager {
    // 單例模式，確保全 App 只用同一個連線
    static let shared = SupabaseManager()
    
    let client: SupabaseClient
    
    private init() {
        // ⚠️ 請填入您在 Supabase 網站取得的網址與 Key
        let supabaseURL = URL(string: "https://wokvhvxagizzczwjuwez.supabase.co")!
        let supabaseKey = "sb_publishable_AoSmm2MKnE2aiDgBQh1nBw_R5X7Xa3I"
        
        self.client = SupabaseClient(supabaseURL: supabaseURL, supabaseKey: supabaseKey)
    }
}
