import SwiftUI

struct AdminPanelView: View {
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var chatService: ChatService
    @ObservedObject var adminService = AdminService.shared
    @ObservedObject var reportService = ReportService.shared

    @State private var usernameInput = ""
    @State private var actionResult: String?
    @State private var showResult = false
    @State private var selectedAction: AdminAction = .verify
    @State private var selectedReport: UserReport?
    @State private var showReportDetail = false

    enum AdminAction: String, CaseIterable {
        case verify, unverify, ban, unban, deleteAccount, restore, untrust, trust

        var icon: String {
            switch self {
            case .verify: return "checkmark.seal.fill"
            case .unverify: return "checkmark.seal"
            case .ban: return "nosign"
            case .unban: return "arrow.uturn.backward"
            case .deleteAccount: return "person.crop.circle.badge.xmark"
            case .restore: return "person.crop.circle.badge.checkmark"
            case .untrust: return "exclamationmark.triangle.fill"
            case .trust: return "checkmark.shield.fill"
            }
        }

        var color: Color {
            switch self {
            case .verify: return .blue
            case .unverify: return .orange
            case .ban: return .red
            case .unban: return .green
            case .deleteAccount: return .red
            case .restore: return .green
            case .untrust: return .orange
            case .trust: return .green
            }
        }

        func localizedName(_ loc: LocalizationManager) -> String {
            switch self {
            case .verify: return loc.verifyUser
            case .unverify: return loc.localized("Снять верификацию", "Remove Verification")
            case .ban: return loc.banUser
            case .unban: return loc.unbanUser
            case .deleteAccount: return loc.deleteAccount
            case .restore: return loc.localized("Восстановить", "Restore")
            case .untrust: return loc.localized("Недоверенный", "Untrusted")
            case .trust: return loc.localized("Доверенный", "Trusted")
            }
        }
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Admin badge
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.red, .orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 50, height: 50)
                        Image(systemName: "shield.checkered")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(localization.adminPanel)
                            .font(.headline)
                        Text("@\(AuthService.shared.currentUsername)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("ADMIN")
                        .font(.caption.bold())
                        .foregroundColor(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Color.red))
                }
                .padding(14)
                .liquidGlassCard(cornerRadius: 16)
                .padding(.horizontal)

                // Username input
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.username)
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)

                    HStack {
                        Image(systemName: "at")
                            .foregroundStyle(.secondary)
                        TextField(localization.localized("Введите юзернейм", "Enter username"), text: $usernameInput)
                            .textInputAutocapitalization(.never)
                            .autocorrectionDisabled()
                    }
                    .padding(14)
                    .liquidGlassCard(cornerRadius: 12)
                    .padding(.horizontal)
                }

                // Action selector
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.localized("Действие", "Action"))
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 20)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(AdminAction.allCases, id: \.self) { action in
                                Button {
                                    selectedAction = action
                                } label: {
                                    HStack(spacing: 6) {
                                        Image(systemName: action.icon)
                                            .font(.system(size: 12))
                                        Text(action.localizedName(localization))
                                            .font(.caption)
                                    }
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(
                                        Capsule().fill(selectedAction == action ? action.color.opacity(0.2) : Color.gray.opacity(0.1))
                                    )
                                    .foregroundStyle(selectedAction == action ? action.color : .secondary)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }

                // Execute button
                Button {
                    executeAction()
                } label: {
                    HStack {
                        Image(systemName: selectedAction.icon)
                        Text(selectedAction.localizedName(localization))
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(usernameInput.isEmpty ? Color.gray : selectedAction.color)
                    )
                }
                .disabled(usernameInput.isEmpty)
                .padding(.horizontal)

                // Result
                if showResult, let result = actionResult {
                    HStack(spacing: 8) {
                        Image(systemName: "info.circle.fill")
                            .foregroundStyle(.blue)
                        Text(result)
                            .font(.subheadline)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .liquidGlassCard(cornerRadius: 12)
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .top)))
                }

                Divider().padding(.horizontal)

                // Verified users list
                if !adminService.verifiedUsernames.isEmpty {
                    adminListSection(
                        title: localization.localized("Верифицированные", "Verified"),
                        icon: "checkmark.seal.fill",
                        iconColor: .blue,
                        items: Array(adminService.verifiedUsernames).sorted()
                    )
                }

                // Banned users list
                if !adminService.bannedUsernames.isEmpty {
                    adminListSection(
                        title: localization.localized("Забаненные", "Banned"),
                        icon: "nosign",
                        iconColor: .red,
                        items: Array(adminService.bannedUsernames).sorted()
                    )
                }

                // Untrusted users list
                if !adminService.untrustedUsernames.isEmpty {
                    adminListSection(
                        title: localization.localized("Недоверенные", "Untrusted"),
                        icon: "exclamationmark.triangle.fill",
                        iconColor: .orange,
                        items: Array(adminService.untrustedUsernames).sorted()
                    )
                }

                // Deleted users list
                if !adminService.deletedUsernames.isEmpty {
                    adminListSection(
                        title: localization.localized("Удалённые аккаунты", "Deleted Accounts"),
                        icon: "person.crop.circle.badge.xmark",
                        iconColor: .gray,
                        items: Array(adminService.deletedUsernames).sorted()
                    )
                }

                // MARK: - Reports section
                if !reportService.reports.isEmpty {
                    Divider().padding(.horizontal)

                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.bubble.fill")
                                .font(.system(size: 13))
                                .foregroundStyle(.red)
                            Text(localization.localized("Жалобы", "Reports"))
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)

                            Spacer()

                            Text("\(reportService.reports.count)")
                                .font(.caption.bold())
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.red))
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 6)

                        VStack(spacing: 0) {
                            ForEach(reportService.reports) { report in
                                Button {
                                    selectedReport = report
                                    showReportDetail = true
                                } label: {
                                    reportRow(report)
                                }
                                .buttonStyle(.plain)

                                if report.id != reportService.reports.last?.id {
                                    Divider().padding(.leading, 14)
                                }
                            }
                        }
                        .liquidGlassCard(cornerRadius: 16)
                        .padding(.horizontal)
                    }
                }

                Spacer(minLength: 100)
            }
            .padding(.top, 8)
        }
        .navigationTitle(localization.adminPanel)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showReportDetail) {
            if let report = selectedReport {
                ReportDetailSheet(
                    report: report,
                    localization: localization,
                    onBan: {
                        adminService.banUser(report.reportedUsername)
                        updateDemoUser(report.reportedUsername) { $0.isBanned = true }
                        reportService.dismissReport(report.id)
                        showReportDetail = false
                    },
                    onUntrust: {
                        adminService.untrustUser(report.reportedUsername)
                        updateDemoUser(report.reportedUsername) { $0.isUntrusted = true }
                        reportService.dismissReport(report.id)
                        showReportDetail = false
                    },
                    onDismiss: {
                        reportService.dismissReport(report.id)
                        showReportDetail = false
                    }
                )
            }
        }
    }

    private func adminListSection(title: String, icon: String, iconColor: Color, items: [String]) -> some View {
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
                ForEach(items, id: \.self) { username in
                    HStack {
                        Text("@\(username)")
                            .font(.subheadline)
                        Spacer()
                        Image(systemName: icon)
                            .font(.caption)
                            .foregroundStyle(iconColor)
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)

                    if username != items.last {
                        Divider().padding(.leading, 14)
                    }
                }
            }
            .liquidGlassCard(cornerRadius: 16)
            .padding(.horizontal)
        }
    }

    private func executeAction() {
        let u = usernameInput.trimmingCharacters(in: .whitespaces)
        guard !u.isEmpty else { return }

        withAnimation(.spring(response: 0.3)) {
            switch selectedAction {
            case .verify:
                adminService.verifyUser(u)
                actionResult = localization.localized("Пользователь @\(u) верифицирован", "User @\(u) verified")
                // Обновляем в демо-данных
                updateDemoUser(u) { $0.isVerified = true }

            case .unverify:
                adminService.unverifyUser(u)
                actionResult = localization.localized("Верификация @\(u) снята", "Verification removed for @\(u)")
                updateDemoUser(u) { $0.isVerified = false }

            case .ban:
                adminService.banUser(u)
                actionResult = localization.localized("Пользователь @\(u) забанен", "User @\(u) banned")
                updateDemoUser(u) { $0.isBanned = true }

            case .unban:
                adminService.unbanUser(u)
                actionResult = localization.localized("Пользователь @\(u) разбанен", "User @\(u) unbanned")
                updateDemoUser(u) { $0.isBanned = false }

            case .deleteAccount:
                adminService.deleteUserAccount(u)
                actionResult = localization.localized("Аккаунт @\(u) удалён", "Account @\(u) deleted")
                updateDemoUser(u) { $0.isDeleted = true }

            case .restore:
                adminService.restoreUserAccount(u)
                actionResult = localization.localized("Аккаунт @\(u) восстановлен", "Account @\(u) restored")
                updateDemoUser(u) { $0.isDeleted = false }

            case .untrust:
                adminService.untrustUser(u)
                actionResult = localization.localized("Пользователь @\(u) помечен как недоверенный", "User @\(u) marked as untrusted")
                updateDemoUser(u) { $0.isUntrusted = true }

            case .trust:
                adminService.trustUser(u)
                actionResult = localization.localized("Пользователь @\(u) теперь доверенный", "User @\(u) is now trusted")
                updateDemoUser(u) { $0.isUntrusted = false }
            }

            showResult = true
            usernameInput = ""
        }
    }

    private func updateDemoUser(_ username: String, update: (inout FinderUser) -> Void) {
        let u = username.lowercased()
        for chatIndex in chatService.chats.indices {
            for pIndex in chatService.chats[chatIndex].participants.indices {
                if chatService.chats[chatIndex].participants[pIndex].username.lowercased() == u {
                    update(&chatService.chats[chatIndex].participants[pIndex])
                }
            }
        }
    }

    private func reportRow(_ report: UserReport) -> some View {
        HStack(spacing: 10) {
            let category = ReportCategory(rawValue: report.category)
            Image(systemName: category?.icon ?? "questionmark.circle")
                .font(.system(size: 14))
                .foregroundStyle(category?.color ?? .gray)
                .frame(width: 28, height: 28)
                .background((category?.color ?? .gray).opacity(0.12))
                .cornerRadius(6)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text("@\(report.reportedUsername)")
                        .font(.subheadline.bold())
                    Text("←")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("@\(report.reporterUsername)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(category?.localizedName(isRussian: localization.isRussian) ?? report.category)
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

// MARK: - Report Detail Sheet

struct ReportDetailSheet: View {
    let report: UserReport
    let localization: LocalizationManager
    let onBan: () -> Void
    let onUntrust: () -> Void
    let onDismiss: () -> Void

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    // Header
                    let category = ReportCategory(rawValue: report.category)

                    VStack(spacing: 10) {
                        Image(systemName: category?.icon ?? "questionmark.circle")
                            .font(.system(size: 36))
                            .foregroundStyle(category?.color ?? .gray)
                            .frame(width: 70, height: 70)
                            .background((category?.color ?? .gray).opacity(0.12))
                            .cornerRadius(18)

                        Text(category?.localizedName(isRussian: localization.isRussian) ?? report.category)
                            .font(.headline)

                        Text(category?.localizedDescription(isRussian: localization.isRussian) ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top, 8)

                    // Users
                    VStack(spacing: 0) {
                        HStack {
                            Text(localization.localized("На кого", "Reported"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("@\(report.reportedUsername)")
                                .font(.subheadline.bold())
                                .foregroundStyle(.red)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)

                        Divider().padding(.leading, 14)

                        HStack {
                            Text(localization.localized("Кто отправил", "Reporter"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text("@\(report.reporterUsername)")
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)

                        Divider().padding(.leading, 14)

                        HStack {
                            Text(localization.localized("Дата", "Date"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                            Text(report.timestamp, style: .date)
                                .font(.subheadline)
                        }
                        .padding(.horizontal, 14)
                        .padding(.vertical, 10)

                        if report.includeConversation {
                            Divider().padding(.leading, 14)
                            HStack {
                                Image(systemName: "text.bubble.fill")
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                Text(localization.localized("Переписка прикреплена", "Conversation attached"))
                                    .font(.caption)
                                    .foregroundStyle(.blue)
                                Spacer()
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 10)
                        }
                    }
                    .liquidGlassCard(cornerRadius: 16)
                    .padding(.horizontal)

                    // Description
                    if !report.description.isEmpty {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(localization.localized("Описание", "Description"))
                                .font(.caption.bold())
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, 20)

                            Text(report.description)
                                .font(.subheadline)
                                .padding(14)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .liquidGlassCard(cornerRadius: 16)
                                .padding(.horizontal)
                        }
                    }

                    // Actions
                    VStack(spacing: 10) {
                        Button {
                            onBan()
                        } label: {
                            HStack {
                                Image(systemName: "nosign")
                                Text(localization.localized("Забанить @\(report.reportedUsername)", "Ban @\(report.reportedUsername)"))
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.red))
                        }

                        Button {
                            onUntrust()
                        } label: {
                            HStack {
                                Image(systemName: "exclamationmark.triangle.fill")
                                Text(localization.localized("Пометить недоверенным", "Mark as untrusted"))
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(.orange))
                        }

                        Button {
                            onDismiss()
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle.fill")
                                Text(localization.localized("Отклонить жалобу", "Dismiss report"))
                            }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                        }
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 40)
                }
            }
            .navigationTitle(localization.localized("Жалоба", "Report"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
