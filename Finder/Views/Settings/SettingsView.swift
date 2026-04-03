import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var chatService: ChatService

    @State private var showFenix = false
    @State private var showPrivacy = false
    @State private var showLogoutAlert = false
    @State private var appear = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Profile card
                    profileCard
                        .opacity(appear ? 1 : 0)
                        .offset(y: appear ? 0 : 20)

                    // Appearance section
                    settingsSection(
                        title: localization.appearance,
                        icon: "paintbrush.fill",
                        iconColor: .purple
                    ) {
                        // Theme toggle
                        SettingsToggleRow(
                            icon: "moon.fill",
                            iconColor: .indigo,
                            title: localization.darkMode,
                            isOn: Binding(
                                get: { themeManager.isDarkMode },
                                set: { _ in
                                    withAnimation(.spring(response: 0.4)) {
                                        themeManager.toggleTheme()
                                    }
                                }
                            )
                        )

                        Divider().padding(.leading, 52)

                        // Language
                        SettingsButtonRow(
                            icon: "globe",
                            iconColor: .blue,
                            title: localization.language,
                            value: localization.isRussian ? "Русский" : "English"
                        ) {
                            withAnimation(.spring(response: 0.4)) {
                                localization.toggleLanguage()
                            }
                        }
                    }
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.spring(response: 0.4).delay(0.1), value: appear)

                    // Privacy section
                    settingsSection(
                        title: localization.privacy,
                        icon: "lock.shield.fill",
                        iconColor: .green
                    ) {
                        NavigationLink {
                            PrivacySettingsView()
                                .environmentObject(authService)
                                .environmentObject(localization)
                                .environmentObject(themeManager)
                        } label: {
                            SettingsNavigationRow(
                                icon: "hand.raised.fill",
                                iconColor: .green,
                                title: localization.privacy
                            )
                        }
                    }
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.spring(response: 0.4).delay(0.15), value: appear)

                    // Fenix Protocol
                    Button {
                        showFenix = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.red.opacity(0.15))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 16))
                                    .foregroundStyle(.red)
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text(localization.fenixProtocol)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.red)
                                Text(localization.localized(
                                    "Удалить все данные безвозвратно",
                                    "Delete all data permanently"
                                ))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(14)
                    }
                    .liquidGlassCard(cornerRadius: 16)
                    .padding(.horizontal)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.spring(response: 0.4).delay(0.2), value: appear)

                    // Logout
                    Button {
                        showLogoutAlert = true
                    } label: {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .foregroundStyle(.red)
                            Text(localization.logout)
                                .foregroundStyle(.red)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .liquidGlassCard(cornerRadius: 16)
                    }
                    .padding(.horizontal)
                    .opacity(appear ? 1 : 0)
                    .offset(y: appear ? 0 : 20)
                    .animation(.spring(response: 0.4).delay(0.25), value: appear)

                    // Version
                    Text("Finder v1.0.0")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)

                    Spacer(minLength: 100)
                }
                .padding(.top, 8)
            }
            .navigationTitle(localization.settings)
            .fullScreenCover(isPresented: $showFenix) {
                FenixProtocolView()
                    .environmentObject(authService)
                    .environmentObject(chatService)
                    .environmentObject(themeManager)
                    .environmentObject(localization)
            }
            .alert(localization.localized("Выйти из аккаунта?", "Log out?"), isPresented: $showLogoutAlert) {
                Button(localization.cancel, role: .cancel) {}
                Button(localization.logout, role: .destructive) {
                    authService.logout()
                }
            }
        }
        .onAppear {
            withAnimation { appear = true }
        }
    }

    // MARK: - Profile Card
    private var profileCard: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.blue, .cyan],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 60, height: 60)

                Image(systemName: "person.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(authService.currentDisplayName)
                    .font(.headline)
                Text("@\(authService.currentUsername)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(authService.currentFinderID)
                    .font(.system(size: 11, design: .monospaced))
                    .foregroundStyle(.cyan)
            }

            Spacer()
        }
        .padding(14)
        .liquidGlassCard(cornerRadius: 16)
        .padding(.horizontal)
    }

    // MARK: - Section Builder
    private func settingsSection(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 13))
                    .foregroundStyle(iconColor)
                Text(title)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)

            VStack(spacing: 0) {
                content()
            }
            .liquidGlassCard(cornerRadius: 16)
            .padding(.horizontal)
        }
    }
}

// MARK: - Settings Row Components
struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.subheadline)

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.blue)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

struct SettingsButtonRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let value: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.system(size: 14))
                        .foregroundStyle(iconColor)
                }

                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)

                Spacer()

                Text(value)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
    }
}

struct SettingsNavigationRow: View {
    let icon: String
    let iconColor: Color
    let title: String

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundStyle(iconColor)
            }

            Text(title)
                .font(.subheadline)
                .foregroundStyle(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}
