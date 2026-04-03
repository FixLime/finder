import SwiftUI

struct ProfileTabView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var chatService: ChatService
    @ObservedObject var ratingService = RatingService.shared


    @State private var appear = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Avatar & Info
                    VStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .cyan, .blue.opacity(0.6)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 90, height: 90)
                                .shadow(color: .blue.opacity(0.3), radius: 15)

                            Image(systemName: "person.fill")
                                .font(.system(size: 40))
                                .foregroundColor(.white)

                            if authService.isAdmin {
                                Image(systemName: "shield.checkered")
                                    .font(.system(size: 16))
                                    .foregroundColor(.white)
                                    .padding(4)
                                    .background(Circle().fill(Color.red))
                                    .offset(x: 32, y: -32)
                            }
                        }

                        HStack(spacing: 4) {
                            Text(authService.currentDisplayName)
                                .font(.title2.bold())
                            if AdminService.shared.isVerified(authService.currentUsername) {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.blue)
                            }
                        }

                        Text("@\(authService.currentUsername)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text(authService.currentFinderID)
                            .font(.system(size: 13, design: .monospaced))
                            .foregroundStyle(.cyan)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 6)
                            .liquidGlassCard(cornerRadius: 12)
                    }
                    .padding(.top, 8)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)

                    // Rating card
                    ratingCard
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.spring(response: 0.4).delay(0.05), value: appear)

                    // Settings sections
                    VStack(spacing: 0) {
                        SettingsButtonRow(icon: "paintbrush.fill", iconColor: .purple, title: localization.appearance, value: themeManager.isDarkMode ? localization.localized("Тёмная", "Dark") : localization.localized("Светлая", "Light")) {
                            withAnimation { themeManager.toggleTheme() }
                        }
                        Divider().padding(.leading, 52)
                        SettingsButtonRow(icon: "globe", iconColor: .blue, title: localization.language, value: localization.isRussian ? "RU" : "EN") {
                            withAnimation { localization.toggleLanguage() }
                        }
                    }
                    .liquidGlassCard(cornerRadius: 16)
                    .padding(.horizontal)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.spring(response: 0.4).delay(0.1), value: appear)

                    // Privacy
                    NavigationLink {
                        PrivacySettingsView()
                            .environmentObject(authService)
                            .environmentObject(localization)
                            .environmentObject(themeManager)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "lock.shield.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.green)
                            }
                            Text(localization.privacy)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                    }
                    .liquidGlassCard(cornerRadius: 16)
                    .padding(.horizontal)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.spring(response: 0.4).delay(0.15), value: appear)

                    // Admin Panel (only for admins)
                    if authService.isAdmin {
                        NavigationLink {
                            AdminPanelView()
                                .environmentObject(localization)
                                .environmentObject(chatService)
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "shield.checkered")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.red)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(localization.adminPanel)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)
                                    Text("ADMIN")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundColor(.white)
                                        .padding(.horizontal, 6)
                                        .padding(.vertical, 1)
                                        .background(Capsule().fill(Color.red))
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(14)
                        }
                        .liquidGlassCard(cornerRadius: 16)
                        .padding(.horizontal)
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)
                        .animation(.spring(response: 0.4).delay(0.17), value: appear)
                    }

                    // Account Settings
                    NavigationLink {
                        AccountSettingsView()
                            .environmentObject(authService)
                            .environmentObject(localization)
                            .environmentObject(themeManager)
                            .environmentObject(chatService)
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.15))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "person.circle.fill")
                                    .font(.system(size: 14))
                                    .foregroundStyle(.orange)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text(localization.localized("Аккаунт", "Account"))
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)
                                Text(localization.localized("Управление, удаление, выход", "Management, deletion, logout"))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                    }
                    .liquidGlassCard(cornerRadius: 16)
                    .padding(.horizontal)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.spring(response: 0.4).delay(0.18), value: appear)

                    Text("Finder v1.0.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)

                    Spacer(minLength: 100)
                }
            }
            .navigationTitle(localization.profile)
        }
        .onAppear {
            withAnimation { appear = true }
        }
    }

    // MARK: - Rating Card
    private var ratingCard: some View {
        VStack(spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Image(systemName: "star.fill")
                            .foregroundStyle(.yellow)
                        Text(localization.rating)
                            .font(.subheadline.bold())
                    }

                    Text("\(ratingService.points) \(localization.ratingPoints)")
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                }

                Spacer()

                VStack(spacing: 2) {
                    Text(localization.tier)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(ratingService.tier)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundStyle(ratingService.isTier2 ? .blue : .secondary)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .liquidGlassCard(cornerRadius: 12)
            }

            if !ratingService.isTier2 {
                VStack(spacing: 4) {
                    ProgressView(value: ratingService.progressToTier2)
                        .tint(.blue)

                    Text(localization.localized(
                        "До 2 уровня: \(ratingService.pointsToNextTier) очков",
                        "To tier 2: \(ratingService.pointsToNextTier) points"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            } else {
                HStack(spacing: 4) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.green)
                    Text(localization.localized("Все функции разблокированы", "All features unlocked"))
                        .font(.caption)
                        .foregroundStyle(.green)
                }
            }
        }
        .padding(14)
        .liquidGlassCard(cornerRadius: 16)
        .padding(.horizontal)
    }

}
