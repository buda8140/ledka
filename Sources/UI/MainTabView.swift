import SwiftUI

struct MainTabView: View {
    @StateObject var btManager = BluetoothManager()
    
    init() {
        // Настройка внешнего вида TabBar
        UITabBar.appearance().backgroundColor = UIColor.black.withAlphaComponent(0.8)
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
    }
    
    var body: some View {
        TabView {
            SettingsView()
                .tabItem {
                    Label("Настройки", systemImage: "gearshape")
                }
            
            ModesView()
                .tabItem {
                    Label("Режимы", systemImage: "square.grid.2x2")
                }
            
            MusicView()
                .tabItem {
                    Label("Музыка", systemImage: "music.note")
                }
            
            MicrophoneView()
                .tabItem {
                    Label("Микрофон", systemImage: "mic")
                }
            
            TimerView()
                .tabItem {
                    Label("Таймер", systemImage: "clock")
                }
        }
        .environmentObject(btManager)
        .accentColor(Theme.accentColor)
        .preferredColorScheme(.dark)
    }
}
