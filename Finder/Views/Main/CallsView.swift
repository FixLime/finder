import SwiftUI

struct CallsView: View {
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var chatService: ChatService

    @State private var appear = false

    var body: some View {
        NavigationStack {
            VStack {
                if chatService.callHistory.isEmpty {
                    Spacer()

                    Image(systemName: "phone.arrow.up.right")
                        .font(.system(size: 50))
                        .foregroundStyle(.secondary.opacity(0.5))

                    Text(localization.localized("Нет вызовов", "No calls"))
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .padding(.top, 12)

                    Text(localization.localized(
                        "Здесь будет история ваших звонков",
                        "Your call history will appear here"
                    ))
                    .font(.subheadline)
                    .foregroundStyle(.secondary.opacity(0.7))
                    .multilineTextAlignment(.center)

                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(Array(chatService.callHistory.enumerated()), id: \.element.id) { index, call in
                                CallRow(call: call)
                                    .opacity(appear ? 1 : 0)
                                    .offset(y: appear ? 0 : 20)
                                    .animation(
                                        .spring(response: 0.4).delay(Double(index) * 0.04),
                                        value: appear
                                    )

                                if index < chatService.callHistory.count - 1 {
                                    Divider().padding(.leading, 76)
                                }
                            }
                        }
                        .padding(.bottom, 100)
                    }
                }
            }
            .navigationTitle(localization.localized("Вызовы", "Calls"))
        }
        .onAppear {
            withAnimation { appear = true }
        }
    }
}

// MARK: - Call Row
struct CallRow: View {
    let call: CallRecord
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [call.user.avatarColor.color, call.user.avatarColor.color.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Image(systemName: call.user.avatarIcon)
                    .font(.system(size: 22))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 4) {
                    Text(call.user.displayName)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(call.isMissed ? .red : .primary)

                    if call.user.isVerified {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.blue)
                    }
                    if call.user.isUntrusted || AdminService.shared.isUntrusted(call.user.username) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(.orange)
                    }
                }

                HStack(spacing: 4) {
                    Image(systemName: call.isOutgoing ? "phone.arrow.up.right" : "phone.arrow.down.left")
                        .font(.system(size: 11))
                        .foregroundStyle(call.isMissed ? .red : .secondary)

                    Text(call.isVideo
                         ? localization.localized("Видеозвонок", "Video call")
                         : localization.localized("Аудиозвонок", "Voice call"))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                    if !call.isMissed, let duration = call.duration {
                        Text("(\(formatDuration(duration)))")
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(formatTime(call.timestamp))
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Button {
                    // Call back
                } label: {
                    Image(systemName: call.isVideo ? "video.fill" : "phone.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(.blue)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .contentShape(Rectangle())
    }

    private func formatTime(_ date: Date) -> String {
        let calendar = Calendar.current
        if calendar.isDateInToday(date) {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        } else if calendar.isDateInYesterday(date) {
            return localization.localized("Вчера", "Yesterday")
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd.MM"
            return formatter.string(from: date)
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let mins = seconds / 60
        let secs = seconds % 60
        return "\(mins):\(String(format: "%02d", secs))"
    }
}
