import SwiftUI
import TipKit // 1. 引入 TipKit

// MARK: - 2. 定義提示內容 (Tip)
struct AIPlanTip: Tip {
    var title: Text {
        Text("AI 旅遊助手")
    }
    
    var message: Text? {
        Text("點擊這裡開啟 AI 自動規劃功能，快速安排您的夢想行程！")
    }
    
    var image: Image? {
        Image(systemName: "sparkles")
    }
    
    // 設定規則 (可選)：例如只有在使用者還沒建立過行程時才顯示
    // 這裡先保持簡單，預設會顯示
}

struct Category: Identifiable {
    var id = UUID()
    var label: String
    var value: Int
    var image: String
}

struct HomeView: View {
    @State var selectedTab: Int = 0
    @Environment(\.colorScheme) var colorScheme
    @State var isVisible: Bool = false
    @EnvironmentObject var viewModel: TravelAppViewModel
    @Namespace var animation
    
    // 控制導航的變數
    @State private var isNavigating = false
    
    // 3. 實例化 Tip
    let aiTip = AIPlanTip()
    
    var categories: [Category] = [
        .init(label: "Trips", value: 0, image: "category_trips"),
        .init(label: "Hotel", value: 1, image: "category_hotel"),
        .init(label: "Transport", value: 2, image: "category_transport"),
        .init(label: "Events", value: 3, image: "category_events"),
    ]
    
    var categorySize: CGFloat = ((UIScreen.main.bounds.width - 48) / 4) * 0.55
    var slideSize: CGFloat = (UIScreen.main.bounds.width - 48) * 0.6
    
    var body: some View {
        // 1. 最外層包 NavigationStack
        NavigationStack {
            VStack {
                ScrollView(.vertical, showsIndicators: false) {
                    HStack {
                        // 左上角按鈕：點擊後觸發跳轉
                        Button {
                            // 4. 當使用者點擊後，標記提示為已完成 (不再顯示)
                            aiTip.invalidate(reason: .actionPerformed)
                            
                            isNavigating = true
                        } label: {
                            VStack(alignment: .leading) {
                                Rectangle()
                                    .frame(width: 22, height: 2.5)
                                    .foregroundColor(Color("black"))
                                
                                Rectangle()
                                    .frame(width: 16, height: 2.5)
                                    .foregroundColor(Color("black"))
                            }
                        }
                        // 5. 綁定 Tip 到按鈕上
                        .popoverTip(aiTip, arrowEdge: .top)
                        
                        Spacer()
                        
                        Button {
                            print("")
                        } label: {
                            Image(systemName: "bell")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 26, height: 26)
                                .foregroundColor(Color("black"))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                    
                    Text("Where Do You\nWant To Go?")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .font(.largeTitle)
                        .foregroundColor(Color("black"))
                        .padding(.top, 32)
                        .padding(.bottom, 12)
                        .lineSpacing(10)
                        .padding(.horizontal, 24)
                    
                    HStack(spacing: 0) {
                        NavigationLink {
                            SearchView()
                        } label: {
                            HStack(spacing: 0) {
                                Text("Search your trip")
                                    .padding(.leading, 24)
                                    .foregroundColor(colorScheme == .dark ? .white.opacity(0.5) : .black.opacity(0.5))
                                Spacer()
                                Image(systemName: "magnifyingglass")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 18, height: 18)
                                    .foregroundColor(.white)
                                    .padding(12)
                                    .background(Color("green"))
                                    .cornerRadius(30)
                            }
                            .frame(width: UIScreen.main.bounds.width - 48)
                            .padding(8)
                            .background(Color(.secondarySystemBackground))
                            .cornerRadius(60)
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 14)
                    
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(viewModel.tabs, id: \.id) {item in
                                Button {
                                    selectedTab = item.value
                                } label: {
                                    VStack(spacing: 0) {
                                        Text(item.label)
                                            .foregroundColor(item.value == selectedTab ? Color("green") : Color("darkgrey"))
                                        Circle()
                                            .frame(width: 6, height: 6)
                                            .padding(.top, 6)
                                            .foregroundColor(item.value == selectedTab ? Color("green") : Color("darkgrey").opacity(0.0))
                                    }
                                    .padding(.trailing, 42)
                                    .padding(.leading, 12)
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                    }
                    
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 0) {
                            ForEach(viewModel.locationData) {location in
                                NavigationLink {
                                    LocationView(animation: animation)
                                } label: {
                                    VStack(spacing: 0) {
                                        ZStack {
                                            Image(location.image)
                                                .resizable()
                                                .scaledToFill()
                                                .frame(width: slideSize, height: slideSize * 1.3)
                                            
                                            VStack {
                                                Spacer()
                                                HStack(spacing: 0) {
                                                    VStack(alignment: .leading, spacing: 0) {
                                                        Text(location.name)
                                                            .foregroundColor(.white)
                                                            .font(.body)
                                                            .bold()
                                                            .padding(.bottom, 2)
                                                        
                                                        Text("Starting at $\(location.startPrice)")
                                                            .foregroundColor(.white)
                                                            .font(.footnote)
                                                    }
                                                    .frame(maxWidth: .infinity, alignment: .leading)
                                                    
                                                    Spacer()
                                                    Button {
                                                        print("add")
                                                    } label: {
                                                        Image(systemName: "heart")
                                                            .resizable()
                                                            .frame(width: 18, height: 18)
                                                            .padding(9)
                                                            .background(.white)
                                                            .cornerRadius(100)
                                                            .foregroundColor(Color("green"))
                                                    }
                                                }
                                                .padding(.horizontal, 16)
                                            }
                                            .padding(.bottom, 16)
                                            .frame(maxHeight: .infinity)
                                            .background(.black.opacity(0.2))
                                        }
                                    }
                                    .frame(width: slideSize, height: slideSize * 1.3)
                                    .background(Color(.secondarySystemBackground))
                                    .cornerRadius(24)
                                    .padding(.trailing, 24)
                                }
                            }
                        }
                        .padding(.leading, 32)
                    }
                    
                    Text("Popular Categories")
                        .bold()
                        .foregroundColor(Color("black"))
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 12)
                        .padding(.top, 32)
                    
                    HStack(spacing: categorySize * 0.5) {
                        ForEach(categories) { category in
                            Button {
                                print("")
                            } label: {
                                VStack {
                                    Image(category.image)
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: categorySize, height: categorySize)
                                    Text(category.label)
                                        .font(.subheadline)
                                        .foregroundColor(Color("darkgrey"))
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 120)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                // 2. 將 .navigationDestination 放在這裡
                .navigationDestination(isPresented: $isNavigating) {
                    AIInputView()
                }
            }
            
        }
        // 6. 配置 TipKit (正式版可放在 App.swift)
        .task {
            // 1. 重置資料 (先清空舊紀錄)
            try? Tips.resetDatastore()
            
            // 2. 配置
            try? Tips.configure([
                .displayFrequency(.immediate),
                .datastoreLocation(.applicationDefault)
            ])
            
            // 3. 🔥🔥🔥 加入這行！強制顯示所有 Tip (測試完記得刪除) 🔥🔥🔥
            Tips.showAllTipsForTesting()
        }
    }
}

struct HomeView_Previews: PreviewProvider {
    static var previews: some View {
        HomeView()
            .environmentObject(TravelAppViewModel())
            .task {
                // 在 Preview 裡重置狀態，確保每次預覽都看得到 Tip
                try? Tips.resetDatastore()
                try? Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
            }
    }
}
