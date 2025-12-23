import SwiftUI

@main
struct LEDControlApp: App {
    @StateObject private var btManager = BluetoothManager()
    @StateObject private var timerManager = TimerManager()
    
    init() {
        // App-wide appearance updates if needed
        UIView.appearance(whenContainedInInstancesOf: [UIAlertController.self]).tintColor = .systemCyan
    }
    
    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(btManager)
                .environmentObject(timerManager)
                .onAppear {
                    // Inject dependency
                    timerManager.btManager = btManager
                    
                    // Start BG Refresh cycle
                    timerManager.scheduleBackgroundTask()
                }
        }
    }
}

