import SwiftUI

struct UserProfileView: View {
    let user: FinderUser
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) var dismiss

    @State private var appear = false
    @State private var showReport = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Avatar with animation
                    ZStack {
                        // Animated rings
                        ForEach(0..<3, id: \.self) { i in
                            Circle()
                                .stroke(
                                    LinearGradient(
                                        colors: [.blue.opacity(0.3), .cyan.opacity(0.1)],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 1
                                )
                                .frame(width: CGFloat(130 + i * 20), height: CGFloat(130 + i * 20))
                                .scaleEffect(appear ? 1 : 0.8)
                                .opacity(appear ? 0.5 : 0)
                                .animation(
                                    .spring(response: 0.6).delay(Double(i) * 0.15),
                                    value: appear
                                )
                        }

                        AvatarView(user: user, size: 110)

                        // Online indicator
                        if user.isOnline {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 18, height: 18)
                                .overlay(Circle().stroke(Color(.systemBackground), lineWidth: 3))
                                .offset(x: 40, y: 40)
                        }

                        // Verified
                        if user.isVerified {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.blue)
                                .offset(x: -40, y: 40)
                        } else if user.isUntrusted || AdminService.shared.isUntrusted(user.username) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 22))
                                .foregroundStyle(.orange)
                                .offset(x: -40, y: 40)
                        }
                    }
                    .scaleEffect(appear ? 1 : 0.5)
                    .opacity(appear ? 1 : 0)
                    .padding(.top, 20)

                    // Name & Username
                    VStack(spacing: 6) {
                        HStack(spacing: 6) {
                            if user.isUntrusted || AdminService.shared.isUntrusted(user.username) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(.orange)
                            }
                            Text(user.displayName)
                                .font(.title.bold())
                        }

                        Text("@\(user.username)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        if user.isUntrusted || AdminService.shared.isUntrusted(user.username) {
                            HStack(spacing: 4) {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .font(.caption2)
                                Text(localization.localized(
                                    "Недоверенный пользователь — может обманывать и вводить в заблуждение",
                                    "Untrusted user — may deceive and mislead"
                                ))
                                .font(.caption2)
                            }
                            .foregroundStyle(.orange)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(Color.orange.opacity(0.1))
                            .cornerRadius(8)
                        }

                        if user.isOnline {
                            Text(localization.online)
                                .font(.caption)
                                .foregroundStyle(.green)
                        } else if let lastSeen = user.lastSeen {
                            Text("\(localization.lastSeenText) \(formatLastSeen(lastSeen))")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .offset(y: appear ? 0 : 20)
                    .opacity(appear ? 1 : 0)

                    // Status
                    if !user.statusText.isEmpty {
                        Text(user.statusText)
                            .font(.body)
                            .foregroundStyle(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .liquidGlassCard(cornerRadius: 16)
                            .padding(.horizontal)
                    }

                    // FinderID
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "person.badge.key")
                                .foregroundStyle(.cyan)
                            Text("FinderID")
                                .font(.subheadline.bold())
                            Spacer()
                        }
                        Text(user.finderID)
                            .font(.system(.body, design: .monospaced))
                            .foregroundStyle(.cyan)
                    }
                    .padding()
                    .liquidGlassCard(cornerRadius: 16)
                    .padding(.horizontal)

                    // Info
                    VStack(spacing: 0) {
                        ProfileInfoRow(
                            icon: "calendar",
                            title: localization.localized("Дата регистрации", "Join Date"),
                            value: formatDate(user.joinDate)
                        )
                    }
                    .liquidGlassCard(cornerRadius: 16)
                    .padding(.horizontal)

                    // Report button
                    Button {
                        showReport = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.system(size: 14))
                            Text(localization.localized("Пожаловаться", "Report"))
                                .font(.subheadline)
                        }
                        .foregroundStyle(.red)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .liquidGlassCard(cornerRadius: 14)
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.red.opacity(0.2), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal)

                    Spacer(minLength: 50)
                }
            }
            .navigationTitle(localization.profile)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(localization.done) { dismiss() }
                }
            }
            .sheet(isPresented: $showReport) {
                ReportUserView(reportedUser: user)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.6).delay(0.1)) {
                appear = true
            }
        }
    }

    private func formatLastSeen(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.locale = Locale(identifier: localization.isRussian ? "ru" : "en")
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }

    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: localization.isRussian ? "ru" : "en")
        formatter.dateStyle = .long
        return formatter.string(from: date)
    }
}

struct ProfileInfoRow: View {
    let icon: String
    let title: String
    let value: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundStyle(.blue)
                .frame(width: 28)
            Text(title)
                .font(.subheadline)
            Spacer()
            Text(value)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
