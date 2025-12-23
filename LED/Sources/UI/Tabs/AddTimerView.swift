import SwiftUI

struct AddTimerView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var timerManager: TimerManager
    
    @State private var date = Date()
    @State private var isOn = true
    @State private var selectedDays: Set<Int> = [2, 3, 4, 5, 6] // ПН-ПТ
    
    let days = [
        (2, "ПН"), (3, "ВТ"), (4, "СР"), (5, "ЧТ"), (6, "ПТ"), (7, "СБ"), (1, "ВС")
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Заголовок
                VStack(spacing: 8) {
                    Text("Новое событие")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Выберите время и дни недели")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.5))
                }
                .padding(.top, 20)
                
                // Селектор времени
                GlassCard(glow: true) {
                    DatePicker("", selection: $date, displayedComponents: .hourAndMinute)
                        .datePickerStyle(WheelDatePickerStyle())
                        .labelsHidden()
                        .colorInvert()
                        .colorMultiply(.white)
                        .scaleEffect(1.2)
                        .padding()
                }
                .padding(.horizontal)
                
                // Переключатель действия
                GlassCard {
                    HStack(spacing: 20) {
                        actionButton(title: "Включить", tag: true, icon: "power")
                        actionButton(title: "Выключить", tag: false, icon: "power.off")
                    }
                }
                .padding(.horizontal)
                
                // Дни недели
                VStack(alignment: .leading, spacing: 15) {
                    Text("ПОВТОРЯТЬ")
                        .font(.caption2.bold())
                        .foregroundColor(.white.opacity(0.4))
                        .padding(.leading, 10)
                    
                    HStack(spacing: 10) {
                        ForEach(days, id: \.0) { id, name in
                            dayButton(id: id, name: name)
                        }
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Кнопки Сохранить/Отмена
                HStack(spacing: 15) {
                    Button(action: { dismiss() }) {
                        Text("Отмена")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.6))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.white.opacity(0.05))
                            .cornerRadius(15)
                    }
                    
                    Button(action: {
                        let schedule = Schedule(time: date, isOn: isOn, days: Array(selectedDays))
                        timerManager.addSchedule(schedule)
                        dismiss()
                    }) {
                        Text("Сохранить")
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Theme.accentColor)
                            .cornerRadius(15)
                            .neonGlow()
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 20)
            }
        }
    }
    
    private func actionButton(title: String, tag: Bool, icon: String) -> some View {
        Button(action: { isOn = tag }) {
            VStack {
                Image(systemName: icon)
                    .font(.title2)
                Text(title)
                    .font(.caption.bold())
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isOn == tag ? Theme.accentColor.opacity(0.2) : Color.white.opacity(0.05))
            .foregroundColor(isOn == tag ? Theme.accentColor : .white.opacity(0.5))
            .cornerRadius(15)
            .overlay(
                RoundedRectangle(cornerRadius: 15)
                    .stroke(isOn == tag ? Theme.accentColor : Color.clear, lineWidth: 1)
            )
        }
    }
    
    private func dayButton(id: Int, name: String) -> some View {
        Button(action: {
            if selectedDays.contains(id) {
                selectedDays.remove(id)
            } else {
                selectedDays.insert(id)
            }
        }) {
            Text(name)
                .font(.system(size: 12, weight: .bold))
                .frame(width: 40, height: 40)
                .background(selectedDays.contains(id) ? Theme.accentColor : Color.white.opacity(0.05))
                .foregroundColor(selectedDays.contains(id) ? .black : .white)
                .clipShape(Circle())
                .overlay(
                    Circle().stroke(selectedDays.contains(id) ? Color.white.opacity(0.2) : Color.clear, lineWidth: 1)
                )
        }
    }
}
