import SwiftUI

// MARK: - Liquid Glass Card
struct LiquidGlassCard: ViewModifier {
    let cornerRadius: CGFloat
    let opacity: Double
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(themeManager.isDarkMode ? 0.08 : 0.25),
                                        Color.white.opacity(themeManager.isDarkMode ? 0.02 : 0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(themeManager.isDarkMode ? 0.15 : 0.4),
                                        Color.white.opacity(themeManager.isDarkMode ? 0.05 : 0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
            }
    }
}

// MARK: - Liquid Glass Button
struct LiquidGlassButton: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 24)
            .padding(.vertical, 14)
            .background {
                Capsule()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.3),
                                        Color.blue.opacity(0.15)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .overlay {
                        Capsule()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.4),
                                        Color.white.opacity(0.1)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(color: Color.blue.opacity(0.2), radius: 8, x: 0, y: 4)
            }
    }
}

// MARK: - Liquid Glass Navigation Bar
struct LiquidGlassNavBar: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .background {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .overlay {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(themeManager.isDarkMode ? 0.06 : 0.2),
                                        Color.white.opacity(0)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .ignoresSafeArea()
            }
    }
}

// MARK: - Liquid Glass Input Field
struct LiquidGlassTextField: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 16)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(themeManager.isDarkMode ? 0.05 : 0.15))
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(themeManager.isDarkMode ? 0.1 : 0.3), lineWidth: 0.5)
                    }
            }
    }
}

// MARK: - Liquid Glass Tab Bar
struct LiquidGlassTabBar: ViewModifier {
    @EnvironmentObject var themeManager: ThemeManager

    func body(content: Content) -> some View {
        content
            .background {
                RoundedRectangle(cornerRadius: 25)
                    .fill(.ultraThinMaterial)
                    .overlay {
                        RoundedRectangle(cornerRadius: 25)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(themeManager.isDarkMode ? 0.08 : 0.3),
                                        Color.white.opacity(themeManager.isDarkMode ? 0.03 : 0.1)
                                    ],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 25)
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.3),
                                        Color.white.opacity(0.05)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 0.5
                            )
                    }
                    .shadow(color: Color.black.opacity(0.12), radius: 20, x: 0, y: -5)
            }
    }
}

// MARK: - Floating Glass Orbs Background
struct FloatingOrbsBackground: View {
    @State private var animate = false
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.blue.opacity(0.15), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 150
                    )
                )
                .frame(width: 300, height: 300)
                .offset(x: animate ? 50 : -50, y: animate ? -100 : 100)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.purple.opacity(0.12), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 120
                    )
                )
                .frame(width: 250, height: 250)
                .offset(x: animate ? -80 : 80, y: animate ? 50 : -50)

            Circle()
                .fill(
                    RadialGradient(
                        colors: [Color.cyan.opacity(0.1), Color.clear],
                        center: .center,
                        startRadius: 0,
                        endRadius: 100
                    )
                )
                .frame(width: 200, height: 200)
                .offset(x: animate ? 30 : -30, y: animate ? 80 : -80)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 8).repeatForever(autoreverses: true)) {
                animate.toggle()
            }
        }
    }
}

// MARK: - View Extensions
extension View {
    func liquidGlassCard(cornerRadius: CGFloat = 20, opacity: Double = 0.15) -> some View {
        modifier(LiquidGlassCard(cornerRadius: cornerRadius, opacity: opacity))
    }

    func liquidGlassButton() -> some View {
        modifier(LiquidGlassButton())
    }

    func liquidGlassNavBar() -> some View {
        modifier(LiquidGlassNavBar())
    }

    func liquidGlassTextField() -> some View {
        modifier(LiquidGlassTextField())
    }

    func liquidGlassTabBar() -> some View {
        modifier(LiquidGlassTabBar())
    }
}
