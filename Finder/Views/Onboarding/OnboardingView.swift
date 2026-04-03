import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var chatService: ChatService

    @State private var currentPage = 0
    @State private var showRegistration = false

    private let totalPages = 6

    var body: some View {
        ZStack {
            // Animated background
            FloatingOrbsBackground()
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar: Language + Theme toggles
                HStack {
                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            localization.toggleLanguage()
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "globe")
                            Text(localization.isRussian ? "EN" : "RU")
                                .fontWeight(.medium)
                        }
                        .font(.subheadline)
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .liquidGlassCard(cornerRadius: 12)
                    }

                    Spacer()

                    Button {
                        withAnimation(.spring(response: 0.4)) {
                            themeManager.toggleTheme()
                        }
                    } label: {
                        Image(systemName: themeManager.isDarkMode ? "sun.max.fill" : "moon.fill")
                            .font(.title3)
                            .foregroundStyle(.primary)
                            .padding(10)
                            .liquidGlassCard(cornerRadius: 12)
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Spacer()

                // Page content
                TabView(selection: $currentPage) {
                    OnboardingPage(
                        icon: "shield.checkered",
                        iconColor: .blue,
                        title: localization.onboardingTitle1,
                        description: localization.onboardingDesc1,
                        showLogo: true
                    ).tag(0)

                    OnboardingPage(
                        icon: "lock.shield.fill",
                        iconColor: .green,
                        title: localization.onboardingTitle2,
                        description: localization.onboardingDesc2
                    ).tag(1)

                    OnboardingPage(
                        icon: "eye.slash.fill",
                        iconColor: .purple,
                        title: localization.onboardingTitle3,
                        description: localization.onboardingDesc3
                    ).tag(2)

                    OnboardingPage(
                        icon: "message.fill",
                        iconColor: .orange,
                        title: localization.onboardingTitle4,
                        description: localization.onboardingDesc4
                    ).tag(3)

                    OnboardingPage(
                        icon: "flame.fill",
                        iconColor: .red,
                        title: localization.onboardingTitle5,
                        description: localization.onboardingDesc5
                    ).tag(4)

                    OnboardingPage(
                        icon: "person.badge.key.fill",
                        iconColor: .cyan,
                        title: localization.onboardingTitle6,
                        description: localization.onboardingDesc6,
                        showFingerprint: true
                    ).tag(5)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))

                Spacer()

                // Page indicators
                HStack(spacing: 8) {
                    ForEach(0..<totalPages, id: \.self) { index in
                        Capsule()
                            .fill(index == currentPage ? Color.blue : Color.gray.opacity(0.3))
                            .frame(width: index == currentPage ? 24 : 8, height: 8)
                            .animation(.spring(response: 0.3), value: currentPage)
                    }
                }
                .padding(.bottom, 24)

                // Buttons
                VStack(spacing: 12) {
                    if currentPage < totalPages - 1 {
                        Button {
                            withAnimation(.spring(response: 0.4)) {
                                currentPage += 1
                            }
                        } label: {
                            Text(localization.next)
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .liquidGlassButton()
                        }
                    } else {
                        Button {
                            withAnimation(.spring(response: 0.5)) {
                                showRegistration = true
                            }
                        } label: {
                            Text(localization.start)
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .liquidGlassButton()
                        }
                    }

                    if currentPage > 0 && currentPage < totalPages - 1 {
                        Button {
                            withAnimation(.spring(response: 0.5)) {
                                showRegistration = true
                            }
                        } label: {
                            Text(localization.localized("Пропустить", "Skip"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 40)
            }
        }
        .fullScreenCover(isPresented: $showRegistration) {
            FinderIDSetupView()
                .environmentObject(authService)
                .environmentObject(themeManager)
                .environmentObject(localization)
                .environmentObject(chatService)
        }
    }
}

// MARK: - Onboarding Page
struct OnboardingPage: View {
    let icon: String
    let iconColor: Color
    let title: String
    let description: String
    var showLogo: Bool = false
    var showFingerprint: Bool = false

    @State private var appear = false

    var body: some View {
        VStack(spacing: 24) {
            if showLogo {
                // App Logo
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [.blue, .cyan, .blue.opacity(0.6)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 100, height: 100)
                        .shadow(color: .blue.opacity(0.3), radius: 20)

                    Text("F")
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .scaleEffect(appear ? 1 : 0.5)
                .opacity(appear ? 1 : 0)
            } else if showFingerprint {
                FingerprintView(color: iconColor)
                    .frame(width: 100, height: 100)
                    .scaleEffect(appear ? 1 : 0.5)
                    .opacity(appear ? 1 : 0)
            } else {
                ZStack {
                    Circle()
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 100, height: 100)

                    Image(systemName: icon)
                        .font(.system(size: 44))
                        .foregroundStyle(iconColor)
                }
                .scaleEffect(appear ? 1 : 0.5)
                .opacity(appear ? 1 : 0)
            }

            Text(title)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .offset(y: appear ? 0 : 20)
                .opacity(appear ? 1 : 0)

            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .lineSpacing(4)
                .offset(y: appear ? 0 : 20)
                .opacity(appear ? 1 : 0)
        }
        .padding(.horizontal, 32)
        .onAppear {
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1)) {
                appear = true
            }
        }
        .onDisappear {
            appear = false
        }
    }
}
