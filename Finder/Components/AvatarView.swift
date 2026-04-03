import SwiftUI

// MARK: - User Avatar with Censored support
struct AvatarView: View {
    let user: FinderUser?
    let isNotes: Bool
    let isGroup: Bool
    let size: CGFloat

    @State private var showCensoredSheet = false

    init(user: FinderUser? = nil, isNotes: Bool = false, isGroup: Bool = false, size: CGFloat = 56) {
        self.user = user
        self.isNotes = isNotes
        self.isGroup = isGroup
        self.size = size
    }

    var body: some View {
        ZStack {
            if isNotes {
                notesAvatar
            } else if isGroup {
                groupAvatar
            } else if let user = user {
                if user.isCensored {
                    censoredAvatar(user: user)
                        .onTapGesture {
                            showCensoredSheet = true
                        }
                } else {
                    userAvatar(user: user)
                }
            } else {
                unknownAvatar
            }
        }
        .sheet(isPresented: $showCensoredSheet) {
            if let user = user {
                CensoredInfoSheet(user: user)
            }
        }
    }

    // MARK: - Normal user avatar
    private func userAvatar(user: FinderUser) -> some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [user.avatarColor.color, user.avatarColor.color.opacity(0.6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Image(systemName: user.avatarIcon)
                .font(.system(size: size * 0.4))
                .foregroundColor(.white)
        }
    }

    // MARK: - Censored avatar (banned/deleted)
    private func censoredAvatar(user: FinderUser) -> some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: size, height: size)

            // Pixelated/blurred person icon
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.4))
                .foregroundColor(.gray.opacity(0.5))
                .blur(radius: 2)

            // CENSORED banner
            Text("CENSORED")
                .font(.system(size: size * 0.14, weight: .heavy, design: .default))
                .tracking(0.5)
                .foregroundColor(.white)
                .padding(.horizontal, size * 0.06)
                .padding(.vertical, size * 0.03)
                .background(
                    Rectangle()
                        .fill(Color.black)
                )
                .rotationEffect(.degrees(-20))
        }
        .clipShape(Circle())
    }

    // MARK: - Notes avatar
    private var notesAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Image(systemName: "bookmark.fill")
                .font(.system(size: size * 0.4))
                .foregroundColor(.white)
        }
    }

    // MARK: - Group avatar
    private var groupAvatar: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.indigo, .purple],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: size, height: size)

            Image(systemName: "person.3.fill")
                .font(.system(size: size * 0.35))
                .foregroundColor(.white)
        }
    }

    // MARK: - Unknown avatar
    private var unknownAvatar: some View {
        ZStack {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: size, height: size)

            Image(systemName: "person.fill")
                .font(.system(size: size * 0.4))
                .foregroundColor(.gray)
        }
    }
}

// MARK: - Censored Info Sheet
struct CensoredInfoSheet: View {
    let user: FinderUser
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        VStack(spacing: 0) {
            // Handle
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.gray.opacity(0.4))
                .frame(width: 40, height: 5)
                .padding(.top, 10)

            // Header
            HStack {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Circle().fill(Color.white.opacity(0.15)))
                }

                Spacer()

                Text(localization.localized("Информация", "Information"))
                    .font(.headline)

                Spacer()

                // Invisible spacer for centering
                Circle()
                    .fill(Color.clear)
                    .frame(width: 36, height: 36)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)

            ScrollView {
                VStack(spacing: 20) {
                    // Censored avatar large
                    ZStack {
                        Circle()
                            .fill(Color.gray.opacity(0.2))
                            .frame(width: 100, height: 100)

                        Image(systemName: "person.fill")
                            .font(.system(size: 44))
                            .foregroundColor(.gray.opacity(0.4))
                            .blur(radius: 3)

                        Text("CENSORED")
                            .font(.system(size: 13, weight: .heavy))
                            .tracking(0.5)
                            .foregroundColor(.white)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Rectangle().fill(Color.black))
                            .rotationEffect(.degrees(-20))
                    }
                    .clipShape(Circle())

                    // Status
                    VStack(spacing: 8) {
                        HStack(spacing: 6) {
                            Image(systemName: user.isBanned ? "nosign" : "person.crop.circle.badge.xmark")
                                .foregroundColor(.red)
                            Text(user.isBanned
                                 ? localization.localized("Заблокирован", "Banned")
                                 : localization.localized("Аккаунт удалён", "Account deleted"))
                            .font(.title3.bold())
                        }

                        Text("@\(user.username)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }

                    // Info card
                    VStack(alignment: .leading, spacing: 16) {
                        HStack(spacing: 12) {
                            Image(systemName: "shield.checkered")
                                .font(.system(size: 24))
                                .foregroundColor(.blue)
                                .frame(width: 36)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(localization.localized("Политика конфиденциальности", "Privacy Policy"))
                                    .font(.subheadline.bold())

                                Text(localization.localized(
                                    "Согласно политике конфиденциальности Finder, личность данного пользователя была скрыта.",
                                    "In accordance with Finder's privacy policy, this user's identity has been hidden."
                                ))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Divider()

                        HStack(spacing: 12) {
                            Image(systemName: user.isBanned ? "exclamationmark.triangle.fill" : "trash.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.red)
                                .frame(width: 36)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(user.isBanned
                                     ? localization.localized("Причина блокировки", "Ban Reason")
                                     : localization.localized("Удаление аккаунта", "Account Deletion"))
                                .font(.subheadline.bold())

                                Text(user.isBanned
                                     ? localization.localized(
                                        "Аккаунт заблокирован за нарушение правил сообщества. Все сообщения зашифрованы и недоступны.",
                                        "Account banned for violating community guidelines. All messages are encrypted and inaccessible.")
                                     : localization.localized(
                                        "Пользователь удалил свой аккаунт. Все данные были уничтожены с серверов Finder.",
                                        "User deleted their account. All data has been destroyed from Finder servers."))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Divider()

                        HStack(spacing: 12) {
                            Image(systemName: "eye.slash.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.orange)
                                .frame(width: 36)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(localization.localized("Защита личности", "Identity Protection"))
                                    .font(.subheadline.bold())

                                Text(localization.localized(
                                    "Мы скрыли профиль и аватар этого пользователя для защиты его личных данных.",
                                    "We have hidden this user's profile and avatar to protect their personal data."
                                ))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }
                    .padding(16)
                    .background {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(Color(.secondarySystemBackground))
                    }
                    .padding(.horizontal, 16)

                    // OK button
                    Button {
                        dismiss()
                    } label: {
                        Text("OK")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                            .background(
                                RoundedRectangle(cornerRadius: 14, style: .continuous)
                                    .fill(Color.blue)
                            )
                    }
                    .padding(.horizontal, 16)
                    .padding(.bottom, 30)
                }
                .padding(.top, 20)
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.hidden)
    }
}
