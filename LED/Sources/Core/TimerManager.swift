import Foundation
import UserNotifications
import BackgroundTasks

/// Enhanced Schedule Model
struct Schedule: Codable, Identifiable {
    var id = UUID()
    var time: Date
    var isOn: Bool
    var days: [Int] // 1-7 (Sun-Sat)
    var isEnabled: Bool = true
    var useRamp: Bool = false // Sunset/Sunrise gradual transition
}

class TimerManager: ObservableObject {
    @Published var schedules: [Schedule] = []
    var btManager: BluetoothManager?
    
    private let taskId = "com.ledglow.refresh"
    
    init() {
        loadSchedules()
        requestPermissions()
        registerBackgroundTasks()
    }
    
    private func requestPermissions() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func registerBackgroundTasks() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: taskId, using: nil) { task in
            self.handleBackgroundTask(task: task as! BGAppRefreshTask)
        }
    }
    
    func scheduleBackgroundTask() {
        let request = BGAppRefreshTaskRequest(identifier: taskId)
        request.earliestBeginDate = Date(timeIntervalSinceNow: 15 * 60) // Check every 15 mins
        
        do {
            try BGTaskScheduler.shared.submit(request)
        } catch {
            print("Could not schedule app refresh: \(error)")
        }
    }
    
    private func handleBackgroundTask(task: BGAppRefreshTask) {
        scheduleBackgroundTask() // Schedule next
        
        task.expirationHandler = {
            // Cleanup
        }
        
        checkSchedules()
        task.setTaskCompleted(success: true)
    }
    
    func addSchedule(_ schedule: Schedule) {
        schedules.append(schedule)
        saveSchedules()
        syncNotifications()
    }
    
    func removeSchedule(at offsets: IndexSet) {
        schedules.remove(atOffsets: offsets)
        saveSchedules()
        syncNotifications()
    }
    
    func toggleSchedule(_ schedule: Schedule) {
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index].isEnabled.toggle()
            saveSchedules()
            syncNotifications()
        }
    }
    
    private func saveSchedules() {
        if let encoded = try? JSONEncoder().encode(schedules) {
            UserDefaults.standard.set(encoded, forKey: "saved_schedules")
        }
    }
    
    private func loadSchedules() {
        if let data = UserDefaults.standard.data(forKey: "saved_schedules"),
           let decoded = try? JSONDecoder().decode([Schedule].self, from: data) {
            schedules = decoded
        }
    }
    
    func checkSchedules() {
        let now = Date()
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.hour, .minute, .weekday], from: now)
        
        for schedule in schedules where schedule.isEnabled {
            let scheduleComponents = calendar.dateComponents([.hour, .minute], from: schedule.time)
            
            if scheduleComponents.hour == currentComponents.hour &&
               scheduleComponents.minute == currentComponents.minute &&
               schedule.days.contains(currentComponents.weekday ?? 0) {
                
                if schedule.useRamp {
                    startRamp(targetOn: schedule.isOn)
                } else {
                    btManager?.setPower(on: schedule.isOn)
                }
            }
        }
    }
    
    private func startRamp(targetOn: Bool) {
        // Implementation of gradual brightness increase/decrease
        // This would typically involve a loop or timer over 15-30 mins
        // For simplicity in this block, we'll just set it
        btManager?.setPower(on: targetOn)
        btManager?.setBrightness(targetOn ? 100 : 0)
    }
    
    private func syncNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        for schedule in schedules where schedule.isEnabled {
            let content = UNMutableNotificationContent()
            content.title = "LED Glow Control"
            content.body = "Scheduled event: \(schedule.isOn ? "Turning ON" : "Turning OFF")"
            content.sound = .default
            
            for day in schedule.days {
                var components = Calendar.current.dateComponents([.hour, .minute], from: schedule.time)
                components.weekday = day
                
                let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
                let request = UNNotificationRequest(identifier: "\(schedule.id.uuidString)-\(day)", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request)
            }
        }
    }
}

