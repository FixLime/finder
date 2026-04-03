import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var localization: LocalizationManager
    @EnvironmentObject var authService: AuthService
    @EnvironmentObject var chatService: ChatService

    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            ChatListView()
                .tabItem {
                    Label(localization.chats, systemImage: "bubble.left.and.bubble.right.fill")
                }
                .badge(totalUnread)
                .tag(0)

            CallsView()
                .tabItem {
                    Label(localization.localized("Вызовы", "Calls"), systemImage: "phone.fill")
                }
                .tag(1)

            ProfileTabView()
                .tabItem {
                    Label(localization.profile, systemImage: "person.fill")
                }
                .tag(2)
        }
    }

    private var totalUnread: Int {
        chatService.chats.reduce(0) { $0 + $1.unreadCount }
    }
}
