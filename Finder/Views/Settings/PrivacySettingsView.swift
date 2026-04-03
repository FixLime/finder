import SwiftUI

struct PrivacySettingsView: View {
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var themeManager: ThemeManager

    @AppStorage("privacyShowOnline") private var showOnline = true
    @AppStorage("privacyShowLastSeen") private var showLastSeen = true
    @AppStorage("privacyReadReceipts") private var readReceipts = true
    @AppStorage("privacyAllowScreenshots") private var allowScreenshots = false
    @AppStorage("privacyHideTyping") private var hideTyping = false
    @AppStorage("privacyGhostMode") private var ghostMode = false
    @AppStorage("privacyPhantomMessages") private var phantomMessages = false
    @AppStorage("privacyAntiForward") private var antiForward = false
    @AppStorage("privacySelfDestruct") private var selfDestruct = false
    @AppStorage("privacyIPMask") private var ipMask = false
    @AppStorage("privacyStealthKeyboard") private var stealthKeyboard = false
    @AppStorage("privacyAutoDelete") private var autoDeleteRaw = "Никогда"

    @State private var showDecoySetup = false
    @State private var decoyPin = ""
    @State private var showLockedSheet = false
    @State private var showBiometricBindingConfirm = false
    @State private var showBiometricDisableAuth = false
    @ObservedObject var ratingService = RatingService.shared
    @ObservedObject var biometricService = BiometricService.shared

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Ghost Mode — главная фича
                if ratingService.isTier2 {
                    ghostModeCard
                } else {
                    lockedFeatureCard(
                        title: localization.ghostMode,
                        icon: "eye.slash.fill",
                        description: localization.localized(
                            "Полная невидимость в сети",
                            "Complete online invisibility"
                        )
                    )
                }

                // Основные настройки
                privacySection(
                    title: localization.localized("Видимость", "Visibility"),
                    icon: "eye",
                    iconColor: .blue
                ) {
                    SettingsToggleRow(
                        icon: "circle.fill",
                        iconColor: .green,
                        title: localization.onlineStatus,
                        isOn: $showOnline
                    )
                    Divider().padding(.leading, 52)
                    SettingsToggleRow(
                        icon: "clock",
                        iconColor: .orange,
                        title: localization.localized("Последний визит", "Last Seen"),
                        isOn: $showLastSeen
                    )
                    Divider().padding(.leading, 52)
                    SettingsToggleRow(
                        icon: "checkmark.message",
                        iconColor: .blue,
                        title: localization.readReceipts,
                        isOn: $readReceipts
                    )
                    Divider().padding(.leading, 52)
                    SettingsToggleRow(
                        icon: "keyboard",
                        iconColor: .purple,
                        title: localization.localized("Скрыть набор текста", "Hide Typing"),
                        isOn: $hideTyping
                    )
                }

                // Защита контента
                privacySection(
                    title: localization.localized("Защита контента", "Content Protection"),
                    icon: "shield.fill",
                    iconColor: .green
                ) {
                    SettingsToggleRow(
                        icon: "camera.viewfinder",
                        iconColor: .red,
                        title: localization.localized("Блокировка скриншотов", "Block Screenshots"),
                        isOn: Binding(
                            get: { !allowScreenshots },
                            set: { allowScreenshots = !$0 }
                        )
                    )
                    Divider().padding(.leading, 52)
                    SettingsToggleRow(
                        icon: "arrowshape.turn.up.right.fill",
                        iconColor: .orange,
                        title: localization.antiForward,
                        isOn: $antiForward
                    )
                    Divider().padding(.leading, 52)
                    SettingsToggleRow(
                        icon: "timer",
                        iconColor: .cyan,
                        title: localization.phantomMessages,
                        isOn: $phantomMessages
                    )

                    if phantomMessages {
                        Text(localization.localized(
                            "Сообщения исчезнут после прочтения получателем",
                            "Messages will disappear after the recipient reads them"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 8)
                    }
                }

                // Привязка биометрии
                if biometricService.isAvailable {
                    biometricBindingSection
                }

                // Автоудаление
                privacySection(
                    title: localization.autoDelete,
                    icon: "trash.fill",
                    iconColor: .red
                ) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.localized(
                            "Сообщения будут автоматически удалены через:",
                            "Messages will be automatically deleted after:"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 14)
                        .padding(.top, 8)

                        Picker("", selection: $autoDeleteRaw) {
                            ForEach(AutoDeleteInterval.allCases, id: \.self) { interval in
                                Text(localization.isRussian
                                     ? interval.localizedName.ru
                                     : interval.localizedName.en)
                                .tag(interval.rawValue)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                    }
                }

                // Продвинутая безопасность
                if ratingService.isTier2 {
                    privacySection(
                        title: localization.localized("Продвинутая безопасность", "Advanced Security"),
                        icon: "lock.trianglebadge.exclamationmark.fill",
                        iconColor: .red
                    ) {
                        SettingsToggleRow(
                            icon: "network",
                            iconColor: .purple,
                            title: localization.ipMask,
                            isOn: $ipMask
                        )

                        if ipMask {
                            Text(localization.localized(
                                "Ваш IP-адрес будет скрыт от серверов",
                                "Your IP address will be hidden from servers"
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 4)
                        }

                        Divider().padding(.leading, 52)

                        SettingsToggleRow(
                            icon: "person.crop.rectangle.badge.xmark",
                            iconColor: .indigo,
                            title: localization.localized("Самоуничтожение профиля", "Self-Destruct Profile"),
                            isOn: $selfDestruct
                        )

                        if selfDestruct {
                            Text(localization.localized(
                                "Ваш профиль будет виден только тем, с кем у вас есть активный чат",
                                "Your profile will only be visible to those you have an active chat with"
                            ))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 14)
                            .padding(.bottom, 4)
                        }

                        Divider().padding(.leading, 52)

                        SettingsToggleRow(
                            icon: "keyboard.badge.eye",
                            iconColor: .teal,
                            title: localization.localized("Стелс клавиатура", "Stealth Keyboard"),
                            isOn: $stealthKeyboard
                        )

                        Divider().padding(.leading, 52)

                        // Decoy PIN
                        Button {
                            showDecoySetup = true
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(Color.red.opacity(0.15))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "lock.open.trianglebadge.exclamationmark")
                                        .font(.system(size: 14))
                                        .foregroundStyle(.red)
                                }

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(localization.decoyPinTitle)
                                        .font(.subheadline)
                                        .foregroundStyle(.primary)
                                    Text(localization.localized(
                                        "Фейковый PIN откроет пустой аккаунт",
                                        "Fake PIN opens an empty account"
                                    ))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if !authService.decoyPIN.isEmpty {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                }

                                Image(systemName: "chevron.right")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }
                    }
                } else {
                    // Locked advanced security
                    lockedFeatureCard(
                        title: localization.localized("Продвинутая безопасность", "Advanced Security"),
                        icon: "lock.trianglebadge.exclamationmark.fill",
                        description: localization.localized(
                            "IP маскировка, стелс клавиатура, Decoy PIN и другое",
                            "IP masking, stealth keyboard, Decoy PIN and more"
                        )
                    )
                }

                Spacer(minLength: 100)
            }
            .padding(.top, 8)
        }
        .navigationTitle(localization.privacy)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showDecoySetup) {
            decoyPinSetup
        }
        .sheet(isPresented: $showLockedSheet) {
            RatingLockedInfoSheet()
                .environmentObject(localization)
        }
        .alert(
            localization.localized("Привязать биометрию?", "Bind Biometrics?"),
            isPresented: $showBiometricBindingConfirm
        ) {
            Button(localization.localized("Привязать", "Bind"), role: .destructive) {
                BiometricService.shared.authenticate { success in
                    if success {
                        withAnimation {
                            authService.biometricBindingEnabled = true
                            authService.hasSetupBiometric = true
                        }
                    }
                }
            }
            Button(localization.cancel, role: .cancel) {}
        } message: {
            Text(localization.localized(
                "После привязки вход в аккаунт будет возможен ТОЛЬКО с вашей биометрией (\(biometricService.biometricName)). Даже при правильном PIN-коде потребуется подтверждение личности. Это нельзя будет обойти.",
                "After binding, account login will ONLY be possible with your biometrics (\(biometricService.biometricName)). Even with the correct PIN, identity verification will be required. This cannot be bypassed."
            ))
        }
        .alert(
            localization.localized("Отключить биометрию?", "Disable Biometrics?"),
            isPresented: $showBiometricDisableAuth
        ) {
            Button(localization.localized("Подтвердить", "Confirm"), role: .destructive) {
                BiometricService.shared.authenticate { success in
                    if success {
                        withAnimation {
                            authService.biometricBindingEnabled = false
                        }
                    }
                }
            }
            Button(localization.cancel, role: .cancel) {}
        } message: {
            Text(localization.localized(
                "Для отключения привязки необходимо подтвердить вашу личность через \(biometricService.biometricName).",
                "To disable binding, you need to verify your identity via \(biometricService.biometricName)."
            ))
        }
    }

    // MARK: - Biometric Binding Section
    private var biometricBindingSection: some View {
        privacySection(
            title: localization.localized("Привязка биометрии", "Biometric Binding"),
            icon: "hand.raised.fingers.spread.fill",
            iconColor: .indigo
        ) {
            VStack(spacing: 0) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.indigo.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: biometricService.biometricIcon)
                            .font(.system(size: 14))
                            .foregroundStyle(.indigo)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(localization.localized(
                            "Привязать \(biometricService.biometricName)",
                            "Bind \(biometricService.biometricName)"
                        ))
                        .font(.subheadline)

                        Text(localization.localized(
                            "Вход только с вашей биометрией",
                            "Login only with your biometrics"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Toggle("", isOn: Binding(
                        get: { authService.biometricBindingEnabled },
                        set: { newValue in
                            if newValue {
                                showBiometricBindingConfirm = true
                            } else {
                                showBiometricDisableAuth = true
                            }
                        }
                    ))
                    .labelsHidden()
                    .tint(.indigo)
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)

                if authService.biometricBindingEnabled {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.shield.fill")
                            .font(.caption)
                        Text(localization.localized(
                            "Аккаунт защищён биометрией. Без \(biometricService.biometricName) вход невозможен.",
                            "Account protected by biometrics. Login without \(biometricService.biometricName) is impossible."
                        ))
                        .font(.caption)
                    }
                    .foregroundStyle(.indigo)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.indigo.opacity(0.08))
                    .cornerRadius(10)
                    .padding(.horizontal, 10)
                    .padding(.bottom, 10)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }
            }
        }
    }

    // MARK: - Ghost Mode Card
    private var ghostModeCard: some View {
        VStack(spacing: 12) {
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.purple.opacity(0.15))
                        .frame(width: 44, height: 44)
                    Image(systemName: "eye.slash.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.purple)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(localization.ghostMode)
                        .font(.headline)
                    Text(localization.localized(
                        "Полная невидимость в сети",
                        "Complete online invisibility"
                    ))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }

                Spacer()

                Toggle("", isOn: $ghostMode)
                    .labelsHidden()
                    .tint(.purple)
            }

            if ghostMode {
                HStack(spacing: 6) {
                    Image(systemName: "info.circle")
                        .font(.caption)
                    Text(localization.localized(
                        "Активировано: онлайн скрыт, набор скрыт, прочтение скрыто, последний визит скрыт",
                        "Active: online hidden, typing hidden, read receipts hidden, last seen hidden"
                    ))
                    .font(.caption)
                }
                .foregroundStyle(.purple)
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.purple.opacity(0.08))
                .cornerRadius(10)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(14)
        .liquidGlassCard(cornerRadius: 16)
        .padding(.horizontal)
        .onChange(of: ghostMode) { _, isOn in
            if isOn {
                withAnimation(.spring(response: 0.3)) {
                    showOnline = false
                    showLastSeen = false
                    readReceipts = false
                    hideTyping = true
                    stealthKeyboard = true
                }
            }
        }
    }

    // MARK: - Section Builder
    private func privacySection(title: String, icon: String, iconColor: Color, @ViewBuilder content: () -> some View) -> some View {
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

    // MARK: - Decoy PIN Setup
    private var decoyPinSetup: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Spacer()

                ZStack {
                    Circle()
                        .fill(Color.red.opacity(0.15))
                        .frame(width: 80, height: 80)
                    Image(systemName: "lock.open.trianglebadge.exclamationmark")
                        .font(.system(size: 36))
                        .foregroundStyle(.red)
                }

                Text(localization.localized("Настроить Decoy PIN", "Set Up Decoy PIN"))
                    .font(.title2.bold())

                Text(localization.localized(
                    "При вводе этого PIN-кода откроется пустой аккаунт без ваших данных",
                    "Entering this PIN will open an empty account without your data"
                ))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

                // PIN input
                HStack(spacing: 20) {
                    ForEach(0..<4, id: \.self) { index in
                        Circle()
                            .fill(index < decoyPin.count ? Color.red : Color.gray.opacity(0.3))
                            .frame(width: 18, height: 18)
                    }
                }

                // Number pad
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                    ForEach(1...9, id: \.self) { number in
                        PinButton(number: "\(number)") {
                            if decoyPin.count < 4 { decoyPin += "\(number)" }
                            if decoyPin.count == 4 { saveDecoyPin() }
                        }
                    }
                    PinButton(number: "", isPlaceholder: true) {}
                    PinButton(number: "0") {
                        if decoyPin.count < 4 { decoyPin += "0" }
                        if decoyPin.count == 4 { saveDecoyPin() }
                    }
                    PinButton(number: "⌫", isDelete: true) {
                        if !decoyPin.isEmpty { decoyPin.removeLast() }
                    }
                }
                .padding(.horizontal, 40)

                Spacer()
            }
            .navigationTitle(localization.decoyPinTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localization.cancel) {
                        showDecoySetup = false
                    }
                }
                if !authService.decoyPIN.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(localization.localized("Сбросить", "Reset")) {
                            authService.decoyPIN = ""
                            showDecoySetup = false
                        }
                        .foregroundStyle(.red)
                    }
                }
            }
        }
    }

    private func saveDecoyPin() {
        authService.decoyPIN = decoyPin
        showDecoySetup = false
        decoyPin = ""
    }

    // MARK: - Locked Feature Card
    private func lockedFeatureCard(title: String, icon: String, description: String) -> some View {
        Button {
            showLockedSheet = true
        } label: {
            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.15))
                        .frame(width: 40, height: 40)
                    Image(systemName: "lock.fill")
                        .font(.system(size: 18))
                        .foregroundStyle(.gray)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 6) {
                        Text(title)
                            .font(.subheadline.bold())
                            .foregroundStyle(.primary)
                        Text(localization.localized("Уровень 2", "Tier 2"))
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Capsule().fill(Color.orange))
                    }
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(14)
            .liquidGlassCard(cornerRadius: 16)
            .padding(.horizontal)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    .padding(.horizontal)
            )
        }
    }
}

// MARK: - Rating Locked Info Sheet
struct RatingLockedInfoSheet: View {
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var ratingService = RatingService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            Capsule()
                .fill(Color.secondary.opacity(0.3))
                .frame(width: 36, height: 5)
                .padding(.top, 8)

            ScrollView {
                VStack(spacing: 20) {
                    // Lock icon
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .yellow],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .shadow(color: .orange.opacity(0.3), radius: 15)

                        Image(systemName: "lock.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 20)

                    Text(localization.featureLocked)
                        .font(.title2.bold())

                    Text(localization.tier2Required)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    // Progress
                    VStack(spacing: 8) {
                        HStack {
                            Text(localization.localized("Ваш рейтинг", "Your rating"))
                                .font(.subheadline)
                            Spacer()
                            Text("\(ratingService.points) / \(RatingService.tier2Threshold)")
                                .font(.subheadline.bold())
                        }

                        ProgressView(value: ratingService.progressToTier2)
                            .tint(.orange)
                            .scaleEffect(y: 2)

                        Text(localization.localized(
                            "Осталось: \(ratingService.pointsToNextTier) очков",
                            "Remaining: \(ratingService.pointsToNextTier) points"
                        ))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .padding(16)
                    .liquidGlassCard(cornerRadius: 14)
                    .padding(.horizontal)

                    // How to earn
                    VStack(alignment: .leading, spacing: 12) {
                        Text(localization.localized("Как заработать очки", "How to earn points"))
                            .font(.headline)

                        infoRow(icon: "bubble.left.fill", color: .blue,
                                text: localization.localized("Отправить сообщение = 1 очко", "Send a message = 1 point"))

                        infoRow(icon: "star.fill", color: .yellow,
                                text: localization.localized("Для 2 уровня нужно 5 000 очков", "Tier 2 requires 5,000 points"))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlassCard(cornerRadius: 14)
                    .padding(.horizontal)

                    // Locked features list
                    VStack(alignment: .leading, spacing: 12) {
                        Text(localization.localized("Будет доступно", "Will be unlocked"))
                            .font(.headline)

                        lockedItem(icon: "eye.slash.fill", text: localization.ghostMode)
                        lockedItem(icon: "network", text: localization.ipMask)
                        lockedItem(icon: "keyboard.badge.eye", text: localization.localized("Стелс клавиатура", "Stealth Keyboard"))
                        lockedItem(icon: "lock.open.trianglebadge.exclamationmark", text: localization.decoyPinTitle)
                        lockedItem(icon: "person.crop.rectangle.badge.xmark", text: localization.localized("Самоуничтожение профиля", "Self-Destruct Profile"))
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlassCard(cornerRadius: 14)
                    .padding(.horizontal)

                    Button {
                        dismiss()
                    } label: {
                        Text(localization.localized("Понятно", "Got it"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.blue)
                            )
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
        }
    }

    private func infoRow(icon: String, color: Color, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(color)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
        }
    }

    private func lockedItem(icon: String, text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "lock.fill")
                .font(.system(size: 10))
                .foregroundStyle(.orange)
                .frame(width: 20)
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundStyle(.secondary)
                .frame(width: 24)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}
