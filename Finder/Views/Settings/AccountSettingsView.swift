import SwiftUI

struct AccountSettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var chatService: ChatService

    @State private var showFenix = false
    @State private var showLogoutAlert = false
    @State private var showAccountManager = false
    @State private var showDeleteAccount = false
    @State private var showDeleteConfirm = false
    @State private var showAvatarPicker = false

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                accountInfoSection
                managementSection
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
        .sheet(isPresented: $showAccountManager) {
            accountManagerSheet
        }
        .sheet(isPresented: $showAvatarPicker) {
            AvatarPickerSheet(authService: authService, localization: localization)
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
                // Avatar row
                Button { showAvatarPicker = true } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [authService.currentAvatarColor.color.opacity(0.3), authService.currentAvatarColor.color.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            Image(systemName: authService.currentAvatarIcon)
                                .font(.system(size: 20))
                                .foregroundStyle(authService.currentAvatarColor.color)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.localized("Аватар", "Avatar"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(localization.localized("Нажмите, чтобы изменить", "Tap to change"))
                                .font(.caption)
                                .foregroundStyle(.tertiary)
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

                accountInfoRow(
                    icon: "person.fill",
                    iconColor: .blue,
                    title: localization.localized("Имя", "Name"),
                    value: authService.currentDisplayName
                )
                Divider().padding(.leading, 56)

                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cyan.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: "at")
                            .font(.system(size: 14))
                            .foregroundStyle(.cyan)
                    }
                    Text(localization.username)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        Text(authService.currentUsername)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                            .lineLimit(1)
                        if authService.currentUserIsPremium {
                            PremiumBadge()
                        }
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

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
                Button { showAccountManager = true } label: {
                    HStack(spacing: 12) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.15))
                                .frame(width: 32, height: 32)
                            Image(systemName: "person.2.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(.orange)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text(localization.switchAccount)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                            Text(localization.localized(
                                "\(authService.savedAccounts.count) аккаунтов",
                                "\(authService.savedAccounts.count) accounts"
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

    // MARK: - Account Manager Sheet
    private var accountManagerSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Current account
                    VStack(alignment: .leading, spacing: 6) {
                        Text(localization.localized("Текущий аккаунт", "Current Account"))
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [authService.currentAvatarColor.color.opacity(0.3), authService.currentAvatarColor.color.opacity(0.1)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 44, height: 44)
                                Image(systemName: authService.currentAvatarIcon)
                                    .font(.system(size: 20))
                                    .foregroundStyle(authService.currentAvatarColor.color)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                HStack(spacing: 4) {
                                    Text(authService.currentDisplayName)
                                        .font(.subheadline.bold())
                                    if authService.currentUserIsPremium {
                                        PremiumBadge()
                                    }
                                }
                                Text("@\(authService.currentUsername)")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                        }
                        .padding(12)
                        .liquidGlassCard(cornerRadius: 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                        )
                    }

                    // Saved accounts
                    let otherAccounts = authService.savedAccounts.filter { $0.first?.lowercased() != authService.currentUsername.lowercased() }
                    if !otherAccounts.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(localization.localized("Сохранённые аккаунты", "Saved Accounts"))
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 4)

                            VStack(spacing: 0) {
                                ForEach(Array(otherAccounts.enumerated()), id: \.offset) { idx, account in
                                    let username = account[safe: 0] ?? ""
                                    let displayName = account[safe: 1] ?? username
                                    let finderID = account[safe: 2] ?? ""

                                    if idx > 0 {
                                        Divider().padding(.leading, 56)
                                    }

                                    HStack(spacing: 12) {
                                        let acAvatar = authService.avatarForUser(username)
                                        ZStack {
                                            Circle()
                                                .fill(
                                                    LinearGradient(
                                                        colors: [acAvatar.color.color.opacity(0.3), acAvatar.color.color.opacity(0.1)],
                                                        startPoint: .topLeading,
                                                        endPoint: .bottomTrailing
                                                    )
                                                )
                                                .frame(width: 44, height: 44)
                                            Image(systemName: acAvatar.icon)
                                                .font(.system(size: 20))
                                                .foregroundStyle(acAvatar.color.color)
                                        }
                                        VStack(alignment: .leading, spacing: 2) {
                                            HStack(spacing: 4) {
                                                Text(displayName)
                                                    .font(.subheadline)
                                                if authService.isPremium(username) {
                                                    PremiumBadge()
                                                }
                                            }
                                            Text("@\(username)")
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        Spacer()
                                        Button {
                                            authService.switchToAccount(account)
                                            chatService.loadDemoData()
                                            showAccountManager = false
                                        } label: {
                                            Text(localization.localized("Войти", "Sign In"))
                                                .font(.caption.bold())
                                                .foregroundColor(.white)
                                                .padding(.horizontal, 14)
                                                .padding(.vertical, 6)
                                                .background(Capsule().fill(Color.blue))
                                        }
                                    }
                                    .padding(12)
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            authService.removeAccountFromList(username)
                                        } label: {
                                            Label(localization.localized("Удалить", "Remove"), systemImage: "trash")
                                        }
                                    }
                                }
                            }
                            .liquidGlassCard(cornerRadius: 14)
                        }
                    }

                    // Add account button
                    VStack(alignment: .leading, spacing: 6) {
                        let limitReached = authService.savedAccounts.count >= authService.maxAccounts

                        Button {
                            showAccountManager = false
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                // Logout and go to registration
                                authService.logout()
                            }
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.green.opacity(0.15))
                                        .frame(width: 44, height: 44)
                                    Image(systemName: "plus")
                                        .font(.headline)
                                        .foregroundStyle(.green)
                                }
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(localization.localized("Добавить аккаунт", "Add Account"))
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    Text(localization.localized(
                                        "\(authService.savedAccounts.count)/\(authService.maxAccounts) аккаунтов",
                                        "\(authService.savedAccounts.count)/\(authService.maxAccounts) accounts"
                                    ))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(12)
                            .liquidGlassCard(cornerRadius: 14)
                        }
                        .disabled(limitReached)
                        .opacity(limitReached ? 0.5 : 1)

                        if limitReached && !authService.currentUserIsPremium {
                            HStack(spacing: 6) {
                                Image(systemName: "crown.fill")
                                    .font(.caption)
                                    .foregroundStyle(.yellow)
                                Text(localization.localized(
                                    "Finder Premium — до 15 аккаунтов",
                                    "Finder Premium — up to 15 accounts"
                                ))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(localization.localized("Менеджер аккаунтов", "Account Manager"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localization.localized("Готово", "Done")) { showAccountManager = false }
                }
            }
        }
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
                }
                .padding(16)
                .background(Color.orange.opacity(0.06))
                .cornerRadius(16)
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.orange.opacity(0.2), lineWidth: 1))
                .padding(.horizontal, 24)
                Spacer()
                VStack(alignment: .leading, spacing: 10) {
                    deleteInfoRow(icon: "checkmark.circle", color: .green, text: localization.localized("Данные сохраняются на сервере", "Data preserved on server"))
                    deleteInfoRow(icon: "checkmark.circle", color: .green, text: localization.localized("Восстановление по Finder ID", "Recovery via Finder ID"))
                    deleteInfoRow(icon: "xmark.circle", color: .red, text: localization.localized("Аккаунт станет недоступен", "Account will become inaccessible"))
                }
                .padding(.horizontal, 32)
                Spacer()
                Button { showDeleteConfirm = true } label: {
                    Text(localization.localized("Удалить аккаунт", "Delete Account"))
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.orange))
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
            .alert(localization.localized("Подтвердите удаление", "Confirm Deletion"), isPresented: $showDeleteConfirm) {
                Button(localization.cancel, role: .cancel) {}
                Button(localization.localized("Удалить", "Delete"), role: .destructive) { performSoftDelete() }
            } message: {
                Text(localization.localized(
                    "Аккаунт @\(authService.currentUsername) будет деактивирован. Finder ID: \(authService.currentFinderID)",
                    "Account @\(authService.currentUsername) will be deactivated. Finder ID: \(authService.currentFinderID)"
                ))
            }
        }
    }

    // MARK: - Helpers
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
        authService.softDeleteAccount()
        showDeleteAccount = false
    }
}

// MARK: - Premium Badge
struct PremiumBadge: View {
    @State private var showInfo = false

    var body: some View {
        Button {
            showInfo = true
        } label: {
            Image(systemName: "crown.fill")
                .font(.system(size: 11))
                .foregroundStyle(.yellow)
        }
        .sheet(isPresented: $showInfo) {
            PremiumInfoSheet()
                .presentationDetents([.medium])
        }
    }
}

struct PremiumInfoSheet: View {
    @Environment(\.dismiss) var dismiss
    @State private var showPurchaseError = false

    var body: some View {
        VStack(spacing: 20) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.yellow, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: "crown.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
            }

            Text("Finder Premium")
                .font(.title2.bold())

            Text("Пользователь поддержал проект Finder и получил Finder Premium.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            VStack(alignment: .leading, spacing: 10) {
                premiumFeatureRow(icon: "person.2.fill", text: "До 15 аккаунтов (вместо 5)")
                premiumFeatureRow(icon: "crown.fill", text: "Значок Premium рядом с именем")
                premiumFeatureRow(icon: "heart.fill", text: "Поддержка разработчиков")
            }
            .padding(.horizontal, 32)

            Spacer()

            Button {
                showPurchaseError = true
            } label: {
                HStack {
                    Image(systemName: "crown.fill")
                    Text("Купить Premium")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [.yellow, .orange],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                )
            }
            .padding(.horizontal, 24)

            Button("Закрыть") { dismiss() }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 20)
        }
        .alert("Покупка недоступна", isPresented: $showPurchaseError) {
            Button("OK") {}
        } message: {
            Text("Покупки временно недоступны. Обратитесь к администратору для получения Premium.")
        }
    }

    private func premiumFeatureRow(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.yellow)
                .frame(width: 20)
            Text(text)
                .font(.subheadline)
        }
    }
}

// MARK: - Avatar Picker Sheet
struct AvatarPickerSheet: View {
    @ObservedObject var authService: AuthService
    var localization: LocalizationManager
    @Environment(\.dismiss) var dismiss
    @State private var selectedIcon: String = ""
    @State private var selectedColor: AvatarColor = .blue

    private let avatarIcons = [
        "person.fill", "person.circle.fill", "star.fill", "heart.fill",
        "bolt.fill", "flame.fill", "leaf.fill", "moon.fill",
        "sun.max.fill", "cloud.fill", "snowflake", "drop.fill",
        "pawprint.fill", "hare.fill", "cat.fill", "bird.fill",
        "eye.fill", "hand.raised.fill", "crown.fill", "shield.fill",
        "gamecontroller.fill", "headphones", "music.note", "guitars.fill"
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Preview
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [selectedColor.color.opacity(0.3), selectedColor.color.opacity(0.1)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                        Image(systemName: selectedIcon)
                            .font(.system(size: 44))
                            .foregroundStyle(selectedColor.color)
                    }
                    .padding(.top, 16)

                    // Color picker
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.localized("Цвет", "Color"))
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 10) {
                                ForEach(AvatarColor.allCases, id: \.self) { color in
                                    Circle()
                                        .fill(color.color)
                                        .frame(width: 40, height: 40)
                                        .overlay(
                                            Circle().stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                        )
                                        .overlay(
                                            Circle().stroke(color.color.opacity(0.5), lineWidth: selectedColor == color ? 1 : 0)
                                                .padding(-2)
                                        )
                                        .onTapGesture {
                                            HapticService.selection()
                                            withAnimation(.spring(response: 0.3)) {
                                                selectedColor = color
                                            }
                                        }
                                }
                            }
                        }
                    }

                    // Icon grid
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.localized("Иконка", "Icon"))
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 4)

                        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 6), spacing: 12) {
                            ForEach(avatarIcons, id: \.self) { icon in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(selectedIcon == icon ? selectedColor.color.opacity(0.2) : Color.gray.opacity(0.1))
                                    Image(systemName: icon)
                                        .font(.system(size: 22))
                                        .foregroundStyle(selectedIcon == icon ? selectedColor.color : .secondary)
                                }
                                .frame(height: 52)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(selectedIcon == icon ? selectedColor.color.opacity(0.5) : Color.clear, lineWidth: 1.5)
                                )
                                .onTapGesture {
                                    HapticService.selection()
                                    withAnimation(.spring(response: 0.3)) {
                                        selectedIcon = icon
                                    }
                                }
                            }
                        }
                    }
                }
                .padding()
            }
            .navigationTitle(localization.localized("Аватар", "Avatar"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localization.cancel) { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localization.save) {
                        authService.updateAvatar(icon: selectedIcon, color: selectedColor)
                        dismiss()
                    }
                }
            }
            .onAppear {
                selectedIcon = authService.currentAvatarIcon
                selectedColor = authService.currentAvatarColor
            }
        }
    }
}

// Safe array subscript
extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
