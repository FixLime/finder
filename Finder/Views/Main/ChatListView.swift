import SwiftUI

struct ChatListView: View {
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localization: LocalizationManager

    @State private var searchText = ""
    @State private var appear = false
    @State private var showCreateChat = false

    var supportChats: [Chat] {
        chatService.chats.filter { $0.isSupport }
    }

    var regularChats: [Chat] {
        let filtered = chatService.chats.filter { !$0.isSupport && !$0.isNotes && !$0.isArchived }
        let sorted = filtered.sorted { a, b in
            if a.isPinned != b.isPinned { return a.isPinned }
            let aTime = a.lastMessage?.timestamp ?? .distantPast
            let bTime = b.lastMessage?.timestamp ?? .distantPast
            return aTime > bTime
        }
        if searchText.isEmpty { return sorted }
        return sorted.filter {
            $0.displayName.localizedCaseInsensitiveContains(searchText) ||
            $0.participants.contains(where: { $0.username.localizedCaseInsensitiveContains(searchText) })
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemBackground).ignoresSafeArea()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        // Support section
                        if !supportChats.isEmpty && searchText.isEmpty {
                            supportSection
                        }

                        // Regular chats
                        ForEach(Array(regularChats.enumerated()), id: \.element.id) { index, chat in
                            NavigationLink(destination: ChatDetailView(chat: binding(for: chat))) {
                                ChatRow(chat: chat)
                                    .opacity(appear ? 1 : 0)
                                    .offset(y: appear ? 0 : 20)
                                    .animation(
                                        .spring(response: 0.4).delay(Double(index) * 0.04),
                                        value: appear
                                    )
                            }
                            .buttonStyle(.plain)
                            .contextMenu {
                                Button {
                                    togglePin(chat)
                                } label: {
                                    Label(
                                        chat.isPinned
                                            ? localization.localized("Открепить", "Unpin")
                                            : localization.localized("Закрепить", "Pin"),
                                        systemImage: chat.isPinned ? "pin.slash" : "pin"
                                    )
                                }

                                Button {
                                    toggleMute(chat)
                                } label: {
                                    Label(
                                        chat.isMuted
                                            ? localization.localized("Включить звук", "Unmute")
                                            : localization.localized("Без звука", "Mute"),
                                        systemImage: chat.isMuted ? "speaker.wave.2" : "speaker.slash"
                                    )
                                }

                                if chat.unreadCount > 0 {
                                    Button {
                                        markAsRead(chat)
                                    } label: {
                                        Label(
                                            localization.localized("Прочитать", "Mark as Read"),
                                            systemImage: "checkmark.message"
                                        )
                                    }
                                }

                                Button {
                                    archiveChat(chat)
                                } label: {
                                    Label(
                                        localization.localized("Архивировать", "Archive"),
                                        systemImage: "archivebox"
                                    )
                                }

                                Divider()

                                if !chat.isNotes {
                                    Button(role: .destructive) {
                                        withAnimation(.spring(response: 0.3)) {
                                            chatService.deleteChat(chat.id)
                                        }
                                    } label: {
                                        Label(localization.delete, systemImage: "trash")
                                    }
                                }
                            } preview: {
                                ChatPreview(chat: chat)
                                    .environmentObject(localization)
                            }

                            if index < regularChats.count - 1 {
                                Divider()
                                    .padding(.leading, 76)
                            }
                        }
                    }
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle(localization.chats)
            .searchable(text: $searchText, prompt: localization.searchByUsername)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showCreateChat = true
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showCreateChat) {
                CreateChatView()
                    .environmentObject(chatService)
                    .environmentObject(localization)
            }
        }
        .onAppear {
            withAnimation { appear = true }
        }
    }

    // MARK: - Support Section
    private var supportSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "headphones")
                    .font(.system(size: 13))
                    .foregroundStyle(.blue)
                Text(localization.supportRequests)
                    .font(.caption.bold())
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.vertical, 8)

            ForEach(supportChats) { chat in
                NavigationLink(destination: ChatDetailView(chat: binding(for: chat))) {
                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        colors: [.blue, .cyan],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)
                            Image(systemName: "headphones")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text("Finder Support")
                                    .font(.system(size: 15, weight: .semibold))
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.blue)
                            }
                            if let lastMsg = chat.lastMessage {
                                Text(lastMsg.text)
                                    .font(.system(size: 13))
                                    .foregroundStyle(.secondary)
                                    .lineLimit(1)
                            }
                        }

                        Spacer()

                        if chat.unreadCount > 0 {
                            Text("\(chat.unreadCount)")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Capsule().fill(Color.blue))
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
            }
            .liquidGlassCard(cornerRadius: 14)
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
    }

    private func binding(for chat: Chat) -> Binding<Chat> {
        guard let index = chatService.chats.firstIndex(where: { $0.id == chat.id }) else {
            return .constant(chat)
        }
        return $chatService.chats[index]
    }

    private func togglePin(_ chat: Chat) {
        guard let index = chatService.chats.firstIndex(where: { $0.id == chat.id }) else { return }
        withAnimation(.spring(response: 0.3)) {
            chatService.chats[index].isPinned.toggle()
        }
    }

    private func toggleMute(_ chat: Chat) {
        guard let index = chatService.chats.firstIndex(where: { $0.id == chat.id }) else { return }
        chatService.chats[index].isMuted.toggle()
    }

    private func markAsRead(_ chat: Chat) {
        guard let index = chatService.chats.firstIndex(where: { $0.id == chat.id }) else { return }
        chatService.chats[index].unreadCount = 0
    }

    private func archiveChat(_ chat: Chat) {
        guard let index = chatService.chats.firstIndex(where: { $0.id == chat.id }) else { return }
        withAnimation(.spring(response: 0.3)) {
            chatService.chats[index].isArchived = true
        }
    }
}

// MARK: - Chat Preview (for context menu)
struct ChatPreview: View {
    let chat: Chat
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 10) {
                AvatarView(
                    user: chat.otherUser,
                    isNotes: chat.isNotes,
                    isGroup: chat.isGroup,
                    size: 36
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(chat.isNotes ? localization.notes : chat.displayName)
                        .font(.subheadline.bold())
                    if let user = chat.otherUser, user.isOnline {
                        Text(localization.online)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }

                Spacer()
            }
            .padding(12)

            Divider()

            // Last messages preview
            ScrollView {
                LazyVStack(spacing: 4) {
                    ForEach(chat.messages.sorted(by: { $0.timestamp < $1.timestamp }).suffix(5)) { message in
                        HStack {
                            if message.isFromCurrentUser { Spacer(minLength: 40) }

                            Text(message.text)
                                .font(.caption)
                                .foregroundColor(message.isFromCurrentUser ? .white : .primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                                        .fill(message.isFromCurrentUser ? Color.blue : Color(.secondarySystemBackground))
                                )

                            if !message.isFromCurrentUser { Spacer(minLength: 40) }
                        }
                        .padding(.horizontal, 12)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(width: 300, height: 280)
    }
}

// MARK: - Chat Row
struct ChatRow: View {
    let chat: Chat
    @EnvironmentObject var localization: LocalizationManager

    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                if chat.isChannel {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .indigo],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        Image(systemName: "megaphone.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                } else if chat.isSupport {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.blue, .cyan],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 56, height: 56)
                        Image(systemName: "headphones")
                            .font(.system(size: 24))
                            .foregroundColor(.white)
                    }
                } else {
                    AvatarView(
                        user: chat.otherUser,
                        isNotes: chat.isNotes,
                        isGroup: chat.isGroup,
                        size: 56
                    )
                }

                // Online indicator
                if let user = chat.otherUser, user.isOnline, !chat.isNotes, !user.isCensored {
                    Circle()
                        .fill(Color.green)
                        .frame(width: 14, height: 14)
                        .overlay(
                            Circle().stroke(Color(.systemBackground), lineWidth: 2)
                        )
                        .offset(x: 20, y: 20)
                }

                // Verified badge
                if chat.isVerifiedChat {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.blue)
                        .offset(x: -20, y: 20)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.isNotes
                         ? localization.notes
                         : chat.displayName)
                    .font(.system(size: 16, weight: .semibold))
                    .lineLimit(1)

                    if chat.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    if let lastMsg = chat.lastMessage {
                        Text(formatTime(lastMsg.timestamp))
                            .font(.system(size: 13))
                            .foregroundStyle(chat.unreadCount > 0 ? .blue : .secondary)
                    }
                }

                HStack {
                    if let lastMsg = chat.lastMessage {
                        Text(lastMsg.text)
                            .font(.system(size: 14))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }

                    Spacer()

                    if chat.unreadCount > 0 {
                        Text("\(chat.unreadCount)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(Capsule().fill(Color.blue))
                    }

                    if chat.isMuted {
                        Image(systemName: "speaker.slash.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(.secondary)
                    }
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
}
