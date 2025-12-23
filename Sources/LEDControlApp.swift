import SwiftUI

@main
struct LEDControlApp: App {
    @StateObject private var btManager = BluetoothManager()
    @StateObject private var timerManager = TimerManager()
    @StateObject private var presetService = PresetService()
    
    @State private var showLaunch = true
    
    var body: some Scene {
        WindowGroup {
            ZStack {
                if showLaunch {
                    LaunchScreen()
                        .transition(.opacity)
                } else {
                    MainTabView()
                        .environmentObject(btManager)
                        .environmentObject(timerManager)
                        .environmentObject(presetService)
                }
            }
            .onAppear {
                timerManager.btManager = btManager
                timerManager.scheduleBackgroundTask()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showLaunch = false }
                }
            }
        }
    }
}


