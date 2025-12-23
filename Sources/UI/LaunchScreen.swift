import SwiftUI

struct LaunchScreen: View {
    @State private var pulse = false
    
    var body: some View {
        ZStack {
            Theme.backgroundColor.ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Neon Logo Placeholder
                ZStack {
                    Circle()
                        .stroke(Theme.primaryNeon.opacity(0.3), lineWidth: 4)
                        .frame(width: 120, height: 120)
                        .scaleEffect(pulse ? 1.2 : 1.0)
                        .opacity(pulse ? 0 : 1)
                    
                    Image(systemName: "lightstrip.fill")
                        .font(.system(size: 60))
                        .foregroundColor(Theme.primaryNeon)
                        .neonGlow()
                }
                
                Text("LED Glow")
                    .premiumTitle()
                    .opacity(pulse ? 1 : 0.5)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                pulse = true
            }
        }
    }
}
