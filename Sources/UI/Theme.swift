import SwiftUI

/// Premium Design System for "LED Glow Control"
struct Theme {
    // Primary Brand Colors
    static let primaryNeon = Color(red: 0.0, green: 1.0, blue: 1.0) // Cyan
    static let secondaryNeon = Color(red: 0.7, green: 0.0, blue: 1.0) // Purple
    static let dangerNeon = Color(red: 1.0, green: 0.2, blue: 0.3) // Red/Pink
    
    static let accentColor = primaryNeon
    static let secondaryAccent = secondaryNeon
    
    // Backgrounds
    static let backgroundColor = Color(red: 0.02, green: 0.02, blue: 0.05)
    static let cardBackground = Color.white.opacity(0.05)
    
    static let mainGradient = LinearGradient(
        colors: [secondaryNeon.opacity(0.3), primaryNeon.opacity(0.3)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // UI Components
    static func background() -> some View {
        ZStack {
            backgroundColor.ignoresSafeArea()
            
            // Subtle ambient glows
            Circle()
                .fill(secondaryNeon.opacity(0.15))
                .blur(radius: 100)
                .offset(x: -150, y: -200)
            
            Circle()
                .fill(primaryNeon.opacity(0.15))
                .blur(radius: 100)
                .offset(x: 150, y: 200)
            
            AnimatedBackground()
                .opacity(0.4)
                .ignoresSafeArea()
        }
    }
}

// MARK: - Animated Background
struct AnimatedBackground: View {
    @State private var animate = false
    
    var body: some View {
        MeshGradient(width: 3, height: 3, points: [
            .init(0, 0), .init(0.5, 0), .init(1, 0),
            .init(0, 0.5), .init(animate ? 0.2 : 0.8, animate ? 0.8 : 0.2), .init(1, 0.5),
            .init(0, 1), .init(0.5, 1), .init(1, 1)
        ], colors: [
            Theme.backgroundColor, Theme.secondaryNeon.opacity(0.2), Theme.backgroundColor,
            Theme.primaryNeon.opacity(0.2), Theme.backgroundColor, Theme.secondaryNeon.opacity(0.2),
            Theme.backgroundColor, Theme.primaryNeon.opacity(0.2), Theme.backgroundColor
        ])
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

// MARK: - Glassmorphism Components
struct GlassCard<Content: View>: View {
    let content: Content
    var glow: Bool
    
    init(glow: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.glow = glow
        self.content = content()
    }
    
    var body: some View {
        content
            .padding(20)
            .background(.ultraThinMaterial)
            .background(Theme.cardBackground)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(LinearGradient(colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)], startPoint: .topLeading, endPoint: .bottomTrailing), lineWidth: 1)
            )
            .shadow(color: glow ? Theme.accentColor.opacity(0.3) : .clear, radius: 20, x: 0, y: 10)
    }
}

// MARK: - Haptics Helper
struct Haptics {
    static func play(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
    
    static func notify(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

// MARK: - View Modifiers
extension View {
    func neonGlow(color: Color = Theme.accentColor, radius: CGFloat = 10) -> some View {
        self.shadow(color: color.opacity(0.6), radius: radius)
            .shadow(color: color.opacity(0.4), radius: radius / 2)
    }
    
    func premiumTitle() -> some View {
        self.font(.system(size: 34, weight: .black, design: .rounded))
            .foregroundStyle(
                LinearGradient(colors: [.white, .white.opacity(0.7)], startPoint: .top, endPoint: .bottom)
            )
    }
}

// Fallback for older iOS versions if needed (though project target is iOS 17+)
struct MeshGradient: View {
    let width: Int
    let height: Int
    let points: [SIMD2<Float>]
    let colors: [Color]
    
    var body: some View {
        // Simple fallback since SwiftUI.MeshGradient is iOS 18+
        // I will use a Blur + Animating Circles for generic iOS 17 support
        ZStack {
            Theme.backgroundColor
            ForEach(0..<4) { i in
                Circle()
                    .fill(colors[i % colors.count])
                    .frame(width: 400, height: 400)
                    .blur(radius: 100)
                    .offset(x: CGFloat.random(in: -100...100), y: CGFloat.random(in: -100...100))
            }
        }
    }
}

