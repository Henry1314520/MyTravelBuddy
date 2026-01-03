import SwiftUI
import PhotosUI
import TipKit // 1. 引入 TipKit

// MARK: - 2. 定義提示內容 (Tip)
struct ChangeAvatarTip: Tip {
    var title: Text {
        Text("更換您的頭像")
    }
    
    var message: Text? {
        Text("點擊這裡可以從相簿選擇照片，或是設定您喜歡的背景顏色。")
    }
    
    var image: Image? {
        Image(systemName: "person.crop.circle.badge.plus")
    }
}

struct ProfileView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    
    // --- TipKit 實體 ---
    // 3. 實例化 Tip
    let avatarTip = ChangeAvatarTip()
    
    // --- 狀態變數 ---
    @State private var selectedItem: PhotosPickerItem? = nil
    @State private var showPhotosPicker = false
    
    @State private var selectedImage: Image? = Image("location_1")
    @State private var selectedColor: Color = Color.blue
    @State private var isImageMode: Bool = true
    
    @State private var showColorPicker = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            
            VStack {
                headerView
                
                ScrollView(.vertical, showsIndicators: false) {
                    VStack {
                        profileSection
                        settingsList
                        VStack {}.frame(height: 100)
                    }
                }
            }
            .padding(.horizontal, 24)
            
            floatingMessageButton
        }
        // --- 邏輯處理 ---
        .onChange(of: selectedItem) { newItem in
            Task {
                if let data = try? await newItem?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = Image(uiImage: uiImage)
                    isImageMode = true
                    // 當用戶成功更換照片後，讓提示失效(不再顯示)
                    avatarTip.invalidate(reason: .actionPerformed)
                }
            }
        }
        .sheet(isPresented: $showColorPicker) {
            VStack(spacing: 20) {
                Capsule().fill(Color.gray.opacity(0.3)).frame(width: 40, height: 5).padding(.top)
                Text("選擇頭像背景色").font(.headline)
                
                ColorPicker("顏色", selection: $selectedColor, supportsOpacity: false)
                    .labelsHidden()
                    .scaleEffect(1.5)
                    .padding()
                
                HStack {
                    Text("預覽：")
                    Circle().fill(selectedColor).frame(width: 50, height: 50)
                        .overlay(Text("H").foregroundColor(.white).bold())
                }
                
                Button("設定") {
                    isImageMode = false
                    showColorPicker = false
                    // 當用戶設定顏色後，讓提示失效
                    avatarTip.invalidate(reason: .actionPerformed)
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .padding()
            }
            .presentationDetents([.height(350)])
        }
        // MARK: - TipKit 配置 (僅用於測試/預覽)
        // 在正式 App 中，通常放在 App.swift 的 init 或 onAppear 中
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

// MARK: - 視圖拆解 (Extensions)
extension ProfileView {
    
    private var headerView: some View {
        HStack(spacing: 0) {
            Button {
                self.presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "arrow.left")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 18, height: 18)
                    .foregroundColor(.primary)
                    .frame(width: 40, height: 40)
                    .background(colorScheme == .dark ? Color(.secondarySystemBackground) : .white)
                    .cornerRadius(50)
                    .shadow(color: .gray.opacity(0.2), radius: 5, x: 0, y: 0)
            }
            Text("Account")
                .bold()
                .font(.title3)
                .padding(.leading, 18)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var profileSection: some View {
        VStack {
            Menu {
                Button {
                    showPhotosPicker = true
                } label: {
                    Label("從相簿選擇", systemImage: "photo")
                }
                
                Button {
                    showColorPicker = true
                } label: {
                    Label("選擇顏色", systemImage: "paintpalette")
                }
            } label: {
                ZStack {
                    if isImageMode {
                        if let image = selectedImage {
                            image
                                .resizable()
                                .scaledToFill()
                        } else {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .foregroundColor(.gray)
                        }
                    } else {
                        Circle()
                            .fill(selectedColor)
                            .overlay(
                                Text("H")
                                    .font(.system(size: 50, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .frame(width: 120, height: 120)
                .clipShape(Circle())
                .overlay(
                    Image(systemName: "camera.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Circle())
                        .offset(y: 40)
                )
            }
            // MARK: - 4. 綁定 TipView
            // 使用 .popoverTip 將提示指向這個元件
            .popoverTip(avatarTip, arrowEdge: .bottom) // arrowEdge 控制箭頭方向
            
            .photosPicker(isPresented: $showPhotosPicker, selection: $selectedItem, matching: .images)
            
            .overlay(alignment: .topTrailing) {
                Circle()
                    .frame(width: 18, height: 18)
                    .foregroundColor(Color.green)
                    .overlay {
                        Circle()
                            .stroke(Color(.secondarySystemBackground), lineWidth: 4)
                    }
                    .offset(x: 5, y: 5)
            }
            .padding(.top, 32)
            
            Text("harry potter")
                .font(.title)
                .bold()
                .padding(.top, 16)
            
            Text("ID : 1234567890")
                .font(.title3)
                .bold()
                .foregroundColor(.gray.opacity(0.8))
                .padding(.bottom, 36)
        }
    }
    
    private var settingsList: some View {
        VStack(spacing: 0) {
            Button { print("Preferences") } label: {
                SettingItem(iconName: "gearshape", label: "Preferences", hasChevronIcon: true, isSecurity: false)
            }
            
            Button { print("Security") } label: {
                SettingItem(iconName: "lock.shield", label: "Account Security", hasChevronIcon: true, isSecurity: true)
            }
            
            Button { print("Help") } label: {
                SettingItem(iconName: "questionmark.circle", label: "Help", hasChevronIcon: true, isSecurity: false)
            }
            
            Button { print("Logout") } label: {
                SettingItem(iconName: "arrow.right.square", label: "Logout", hasChevronIcon: false, isSecurity: false)
            }
        }
    }
    
    private var floatingMessageButton: some View {
        Button {
            print("Message tapped")
        } label: {
            Image(systemName: "message.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 20, height: 20)
                .padding(12)
                .foregroundColor(.white)
                .background(Color.blue.opacity(0.6))
                .cornerRadius(20)
        }
        .padding(.trailing, 24)
    }
}

// MARK: - SettingItem 組件定義
struct SettingItem: View {
    var iconName: String
    var label: String
    var hasChevronIcon: Bool
    var isSecurity: Bool
    
    var body: some View {
        HStack(alignment: isSecurity ? .top : .center, spacing: 0) {
            Image(systemName: iconName)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(.gray)
                .padding(.top, isSecurity ? 2 : 0)
                .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(label)
                    .font(.title3)
                    .foregroundColor(.primary)
                
                if isSecurity {
                    VStack(alignment: .leading, spacing: 0) {
                        RoundedRectangle(cornerRadius: 10)
                            .frame(maxWidth: .infinity, maxHeight: 10)
                            .padding(.vertical, 20)
                            .foregroundColor(Color.green.opacity(0.3))
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 10)
                                    .foregroundColor(Color.green)
                                    .frame(maxWidth: 65, maxHeight: 10, alignment: .leading)
                            }
                    }
                    .padding(.trailing, 48)
                }
            }
            .padding(.leading, 18)
            .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
            
            if hasChevronIcon {
                Image(systemName: "chevron.right")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 16, height: 16)
                    .foregroundColor(.gray)
                    .padding(.top, isSecurity ? 8 : 0)
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct ProfileView_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            // 在 Preview 中也能看到 Tip 的小技巧：
            .task {
                try? Tips.resetDatastore() // 重置狀態，讓每次 Preview 都看得到
                try? Tips.configure([
                    .displayFrequency(.immediate),
                    .datastoreLocation(.applicationDefault)
                ])
            }
    }
}
