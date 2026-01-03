

import SwiftUI

@main
struct TravelAppApp: App {
    @StateObject var viewModel: TravelAppViewModel = TravelAppViewModel()
    @StateObject private var authViewModel = AuthenticationViewModel()
    
    var body: some Scene {
        WindowGroup {
            ContentView().environmentObject(viewModel)
                .environmentObject(authViewModel)
        }
    }
}
