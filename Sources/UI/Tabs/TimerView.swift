import SwiftUI

struct TimerView: View {
    @StateObject var timerManager = TimerManager()
    @EnvironmentObject var btManager: BluetoothManager
    @State private var showingAddSheet = false
    
    var body: some View {
        ZStack {
            Theme.background()
            
            VStack(spacing: 0) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Таймер")
                            .font(.system(size: 34, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text("Умное расписание")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    Spacer()
                    
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus")
                            .font(.title2.bold())
                            .foregroundColor(.black)
                            .padding(12)
                            .background(Theme.accentColor)
                            .clipShape(Circle())
                            .neonGlow()
                    }
                }
                .padding(.horizontal)
                .padding(.top, 40)
                .padding(.bottom, 20)
                
                if timerManager.schedules.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "clock.badge.exclamationmark")
                            .font(.system(size: 60))
                            .foregroundColor(.white.opacity(0.2))
                        Text("Нет активных таймеров")
                            .foregroundColor(.white.opacity(0.4))
                        
                        Button("Добавить первый") {
                            showingAddSheet = true
                        }
                        .foregroundColor(Theme.accentColor)
                        .font(.headline)
                    }
                    .frame(maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(spacing: 15) {
                            ForEach(timerManager.schedules) { schedule in
                                timerCard(schedule: schedule)
                            }
                            .onDelete(perform: timerManager.removeSchedule)
                        }
                        .padding()
                    }
                }
            }
        }
        .sheet(isPresented: $showingAddSheet) {
            AddTimerView(timerManager: timerManager)
        }
        .onAppear {
            timerManager.btManager = btManager
        }
    }
    
    private func timerCard(schedule: Schedule) -> some View {
        GlassCard(glow: schedule.isEnabled) {
            HStack(spacing: 15) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(schedule.time, style: .time)
                        .font(.system(size: 32, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                    
                    HStack {
                        Image(systemName: schedule.isOn ? "power" : "power.off")
                            .foregroundColor(schedule.isOn ? .green : .red)
                        Text(schedule.isOn ? "Включить" : "Выключить")
                            .font(.caption.bold())
                            .foregroundColor(schedule.isOn ? .green : .red)
                    }
                    
                    HStack(spacing: 6) {
                        let dayNames = ["ВС", "ПН", "ВТ", "СР", "ЧТ", "ПТ", "СБ"]
                        ForEach(1...7, id: \.self) { day in
                            Text(dayNames[day-1])
                                .font(.system(size: 10, weight: .bold))
                                .padding(4)
                                .frame(width: 28)
                                .background(schedule.days.contains(day) ? Theme.accentColor : Color.white.opacity(0.05))
                                .foregroundColor(schedule.days.contains(day) ? .black : .white.opacity(0.3))
                                .cornerRadius(6)
                        }
                    }
                }
                
                Spacer()
                
                VStack {
                    Toggle("", isOn: Binding(
                        get: { schedule.isEnabled },
                        set: { _ in timerManager.toggleSchedule(schedule) }
                    ))
                    .tint(Theme.accentColor)
                    
                    Spacer()
                    
                    Button(action: {
                        if let index = timerManager.schedules.firstIndex(where: { $0.id == schedule.id }) {
                            timerManager.removeSchedule(at: IndexSet([index]))
                        }
                    }) {
                        Image(systemName: "trash")
                            .foregroundColor(.red.opacity(0.5))
                            .font(.caption)
                    }
                }
            }
        }
    }
}
