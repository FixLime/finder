import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var chatService: ChatService

    @State private var showFenix = false
    @State private var showLogoutAlert = false
    @State private var showSwitchAccount = false
    @State private var showDeleteAccount = false
    @State private var showDeleteConfirm = false
    @State private var switchUsername = ""
    @State private var switchDisplayName = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Account info
                accountInfoSection

                // Account management
                managementSection

                // Danger zone
                dangerSection

                Spacer(minLength: 100)
            }
            .padding(.top, 8)
        }
        .navigationTitle(localization.localized("Аккаунт", "Account"))
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $showFenix) {
            FenixProtocolView()
                .environmentObject(authService)
                .environmentObject(chatService)
                .environmentObject(themeManager)
                .environmentObject(localization)
        }
        .alert(localization.localized("Выйти из аккаунта?", "Log out?"), isPresented: $showLogoutAlert) {
            Button(localization.cancel, role: .cancel) {}
            Button(localization.logout, role: .destructive) { authService.logout() }
        }
        .sheet(isPresented: $showSwitchAccount) {
            switchAccountSheet
        }
        .sheet(isPresented: $showDeleteAccount) {
            deleteAccountSheet
        }
    }

    // MARK: - Account Info
    private var accountInfoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "person.circle")
                    .font(.system(size: 13))
                    .foregroundStyle(.blue)
                Text(localization.localized("Информация", "Information"))
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)

            VStack(spacing: 0) {
                accountInfoRow(
                    icon: "person.fill",
                    iconColor: .blue,
                    title: localization.localized("Имя", "Name"),
                    value: authService.currentDisplayName
                )
                Divider().padding(.leading, 56)

                accountInfoRow(
                    icon: "at",
                    iconColor: .cyan,
                    title: localization.username,
                    value: authService.currentUsername
                )
                Divider().padding(.leading, 56)

                accountInfoRow(
                    icon: "person.badge.key",
                    iconColor: .indigo,
                    title: "Finder ID",
                    value: authService.currentFinderID
                )
            }
            .liquidGlassCard(cornerRadius: 16)
            .padding(.horizontal)
        }
    }

    // MARK: - Management Section
    private var managementSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "gearshape")
                    .font(.system(size: 13))
                    .foregroundStyle(.gray)
                Text(localization.localized("Управление", "Management"))
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)

            VStack(spacing: 0) {
                // Switch Account
                Button { showSwitchAccount = true } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.orange)
                        }
                        Text(localization.switchAccount)
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

                Divider().padding(.leading, 56)

                // Logout
                Button { showLogoutAlert = true } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.gray.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 14))
                                .foregroundStyle(.gray)
                        }
                        Text(localization.logout)
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
            .liquidGlassCard(cornerRadius: 16)
            .padding(.horizontal)
        }
    }

    // MARK: - Danger Zone
    private var dangerSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 13))
                    .foregroundStyle(.red)
                Text(localization.localized("Опасная зона", "Danger Zone"))
                    .font(.caption.bold())
                    .foregroundStyle(.red)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 6)

            VStack(spacing: 0) {
                // Delete Account (recoverable)
                Button { showDeleteAccount = true } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "person.crop.circle.badge.minus")
                                .font(.system(size: 14))
                                .foregroundStyle(.orange)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.localized("Удалить аккаунт", "Delete Account"))
                                .font(.subheadline)
                                .foregroundStyle(.orange)
                            Text(localization.localized(
                                "Можно восстановить по Finder ID",
                                "Can be recovered via Finder ID"
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }

                Divider().padding(.leading, 56)

                // Fenix Protocol (irreversible)
                Button { showFenix = true } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.red.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "flame.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.red)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.fenixProtocol)
                                .font(.subheadline.bold())
                                .foregroundStyle(.red)
                            Text(localization.localized(
                                "Безвозвратное удаление всех данных",
                                "Irreversible deletion of all data"
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
            }
            .liquidGlassCard(cornerRadius: 16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.red.opacity(0.15), lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }

    // MARK: - Account Info Row
    private func accountInfoRow(icon: String, iconColor: Color, title: String, value: String) -> some View {
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
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: title == "Finder ID" ? .monospaced : .default))
                .foregroundStyle(.primary)
                .lineLimit(1)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }

    // MARK: - Delete Account Sheet
    private var deleteAccountSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 100, height: 100)
                    Image(systemName: "person.crop.circle.badge.minus")
                        .font(.system(size: 44))
                        .foregroundStyle(.orange)
                }

                VStack(spacing: 10) {
                    Text(localization.localized("Удалить аккаунт", "Delete Account"))
                        .font(.title2.bold())

                    Text(localization.localized(
                        "Ваш аккаунт будет деактивирован, но данные сохранятся. Вы сможете восстановить аккаунт по Finder ID.",
                        "Your account will be deactivated but data will be preserved. You can restore your account using your Finder ID."
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
                }

                // Finder ID reminder
                VStack(spacing: 8) {
                    Text(localization.localized("Запомните ваш Finder ID", "Remember your Finder ID"))
                        .font(.caption.bold())
                        .foregroundStyle(.orange)

                    Text(authService.currentFinderID)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundStyle(.cyan)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .liquidGlassCard(cornerRadius: 12)

                    Text(localization.localized(
                        "Этот ID понадобится для восстановления аккаунта",
                        "This ID will be needed to restore your account"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .padding(16)
                .background(Color.orange.opacity(0.06))
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal, 24)

                Spacer()

                // Info items
                VStack(alignment: .leading, spacing: 10) {
                    deleteInfoRow(
                        icon: "checkmark.circle",
                        color: .green,
                        text: localization.localized("Данные сохраняются на сервере", "Data preserved on server")
                    )
                    deleteInfoRow(
                        icon: "checkmark.circle",
                        color: .green,
                        text: localization.localized("Восстановление по Finder ID", "Recovery via Finder ID")
                    )
                    deleteInfoRow(
                        icon: "xmark.circle",
                        color: .red,
                        text: localization.localized("Аккаунт станет недоступен", "Account will become inaccessible")
                    )
                }
                .padding(.horizontal, 32)

                Spacer()

                Button {
                    showDeleteConfirm = true
                } label: {
                    Text(localization.localized("Удалить аккаунт", "Delete Account"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(Color.orange)
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 30)
            }
            .navigationTitle(localization.localized("Удаление аккаунта", "Delete Account"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localization.cancel) { showDeleteAccount = false }
                }
            }
            .alert(
                localization.localized("Подтвердите удаление", "Confirm Deletion"),
                isPresented: $showDeleteConfirm
            ) {
                Button(localization.cancel, role: .cancel) {}
                Button(localization.localized("Удалить", "Delete"), role: .destructive) {
                    performSoftDelete()
                }
            } message: {
                Text(localization.localized(
                    "Аккаунт @\(authService.currentUsername) будет деактивирован. Для восстановления используйте Finder ID: \(authService.currentFinderID)",
                    "Account @\(authService.currentUsername) will be deactivated. Use Finder ID to restore: \(authService.currentFinderID)"
                ))
            }
        }
    }

    // MARK: - Switch Account Sheet
    private var switchAccountSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(.orange)
                }

                Text(localization.switchAccount)
                    .font(.title2.bold())

                Text(localization.localized(
                    "Введите юзернейм для входа в другой аккаунт",
                    "Enter username to switch to another account"
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "at")
                            .foregroundStyle(.secondary)
                        TextField(localization.username, text: $switchUsername)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(14)
                    .liquidGlassCard(cornerRadius: 12)

                    HStack {
                        Image(systemName: "person.fill")
                            .foregroundStyle(.secondary)
                        TextField(localization.localized("Имя", "Display Name"), text: $switchDisplayName)
                    }
                    .padding(14)
                    .liquidGlassCard(cornerRadius: 12)
                }
                .padding(.horizontal)

                Button {
                    guard !switchUsername.isEmpty else { return }
                    let name = switchDisplayName.isEmpty ? switchUsername : switchDisplayName
                    authService.switchAccount(username: switchUsername, displayName: name)
                    chatService.loadDemoData()
                    showSwitchAccount = false
                    switchUsername = ""
                    switchDisplayName = ""
                } label: {
                    Text(localization.localized("Войти", "Sign In"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .fill(switchUsername.isEmpty ? Color.gray : Color.blue)
                        )
                }
                .disabled(switchUsername.isEmpty)
                .padding(.horizontal)

                Spacer()
                Spacer()
            }
            .navigationTitle(localization.switchAccount)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localization.cancel) { showSwitchAccount = false }
                }
            }
        }
    }

    // MARK: - Helpers
    private func deleteInfoRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }

    private func performSoftDelete() {
        // Soft delete — mark account as deleted, keep data for recovery
        authService.softDeleteAccount()
        showDeleteAccount = false
    }
}
