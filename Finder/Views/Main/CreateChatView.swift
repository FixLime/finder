import SwiftUI
import Combine

struct CreateChatView: View {
    @EnvironmentObject var chatService: ChatService
    @EnvironmentObject var localization: LocalizationManager
    @Environment(\.dismiss) private var dismiss

    @State private var selectedTab = 0
    @State private var searchQuery = ""
    @State private var groupName = ""
    @State private var channelName = ""
    @State private var selectedUsers: Set<UUID> = []
    @State private var createdChat: Chat?
    @State private var searchDebounce: AnyCancellable?

    var searchResults: [FinderUser] {
        chatService.searchUsers(query: searchQuery)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Tab selector
                HStack(spacing: 0) {
                    tabButton(localization.localized("Новый чат", "New Chat"), tag: 0)
                    tabButton(localization.createGroup, tag: 1)
                    tabButton(localization.createChannel, tag: 2)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                Divider().padding(.top, 8)

                switch selectedTab {
                case 0:
                    newChatTab
                case 1:
                    createGroupTab
                case 2:
                    createChannelTab
                default:
                    EmptyView()
                }
            }
            .navigationTitle(localization.localized("Создать", "Create"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(localization.cancel) { dismiss() }
                }
            }
        }
    }

    // MARK: - Tab Button
    private func tabButton(_ title: String, tag: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3)) { selectedTab = tag }
        } label: {
            Text(title)
                .font(.caption.bold())
                .foregroundStyle(selectedTab == tag ? .blue : .secondary)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(
                    Capsule()
                        .fill(selectedTab == tag ? Color.blue.opacity(0.12) : Color.clear)
                )
        }
    }

    // MARK: - New Chat (search by username)
    private var newChatTab: some View {
        VStack(spacing: 0) {
            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField(localization.searchByUsername, text: $searchQuery)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .onChange(of: searchQuery) { _, newValue in
                        // Debounced server search
                        searchDebounce?.cancel()
                        searchDebounce = Just(newValue)
                            .delay(for: .milliseconds(400), scheduler: RunLoop.main)
                            .sink { query in
                                chatService.searchUsersOnServer(query: query)
                            }
                    }
                if chatService.isSearching {
                    ProgressView()
                        .scaleEffect(0.7)
                }
            }
            .padding(12)
            .liquidGlassCard(cornerRadius: 12)
            .padding(.horizontal)
            .padding(.top, 12)

            if searchQuery.isEmpty {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "person.badge.magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text(localization.localized("Введите юзернейм для поиска", "Enter username to search"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else if searchResults.isEmpty && !chatService.isSearching {
                VStack(spacing: 12) {
                    Spacer()
                    Image(systemName: "person.slash")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text(localization.localized("Пользователь не найден", "User not found"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(searchResults) { user in
                        Button {
                            let chat = chatService.startChat(with: user)
                            createdChat = chat
                            dismiss()
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(user: user, size: 44)

                                VStack(alignment: .leading, spacing: 2) {
                                    HStack(spacing: 4) {
                                        Text(user.displayName)
                                            .font(.subheadline.bold())
                                            .foregroundStyle(.primary)
                                        if user.isVerified || AdminService.shared.isVerified(user.username) {
                                            Image(systemName: "checkmark.seal.fill")
                                                .font(.system(size: 12))
                                                .foregroundStyle(.blue)
                                        }
                                    }
                                    Text("@\(user.username)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                Spacer()

                                if user.isOnline {
                                    Circle()
                                        .fill(.green)
                                        .frame(width: 8, height: 8)
                                }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 10)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        Divider().padding(.leading, 72)
                    }
                }
                .padding(.top, 8)
            }

            } // end else
        }
    }

    // MARK: - Create Group
    private var createGroupTab: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "person.3.fill")
                    .foregroundStyle(.indigo)
                TextField(localization.groupName, text: $groupName)
            }
            .padding(12)
            .liquidGlassCard(cornerRadius: 12)
            .padding(.horizontal)
            .padding(.top, 12)

            // User selection
            Text(localization.addParticipants)
                .font(.caption.bold())
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(ChatService.demoUsers.filter { !$0.isCensored }) { user in
                        Button {
                            if selectedUsers.contains(user.id) {
                                selectedUsers.remove(user.id)
                            } else {
                                selectedUsers.insert(user.id)
                            }
                        } label: {
                            HStack(spacing: 12) {
                                AvatarView(user: user, size: 40)

                                Text(user.displayName)
                                    .font(.subheadline)
                                    .foregroundStyle(.primary)

                                Spacer()

                                Image(systemName: selectedUsers.contains(user.id) ? "checkmark.circle.fill" : "circle")
                                    .foregroundStyle(selectedUsers.contains(user.id) ? .blue : .secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            // Create button
            Button {
                guard !groupName.isEmpty else { return }
                let users = ChatService.demoUsers.filter { selectedUsers.contains($0.id) }
                _ = chatService.createGroup(name: groupName, participants: users)
                dismiss()
            } label: {
                Text(localization.create)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(groupName.isEmpty || selectedUsers.isEmpty ? Color.gray : Color.blue)
                    )
            }
            .disabled(groupName.isEmpty || selectedUsers.isEmpty)
            .padding(.horizontal)
            .padding(.bottom, 16)
        }
    }

    // MARK: - Create Channel
    private var createChannelTab: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .indigo],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 80, height: 80)
                Image(systemName: "megaphone.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.white)
            }

            Text(localization.createChannel)
                .font(.title2.bold())

            HStack {
                Image(systemName: "megaphone")
                    .foregroundStyle(.purple)
                TextField(localization.channelName, text: $channelName)
            }
            .padding(14)
            .liquidGlassCard(cornerRadius: 12)
            .padding(.horizontal)

            Button {
                guard !channelName.isEmpty else { return }
                _ = chatService.createChannel(name: channelName)
                dismiss()
            } label: {
                Text(localization.create)
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .fill(channelName.isEmpty ? Color.gray : Color.purple)
                    )
            }
            .disabled(channelName.isEmpty)
            .padding(.horizontal)

            Spacer()
            Spacer()
        }
    }
}
