import SwiftUI

@main
struct FinderApp: App {
    @StateObject private var authService = AuthService.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var localization = LocalizationManager.shared
    @StateObject private var chatService = ChatService.shared
    @StateObject private var networkService = NetworkService.shared
    @StateObject private var callManager = CallManager.shared

    @State private var showIncomingCall = false

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authService)
                .environmentObject(themeManager)
                .environmentObject(localization)
                .environmentObject(chatService)
                .environmentObject(networkService)
                .preferredColorScheme(themeManager.colorScheme)
                .onAppear {
                    if networkService.authToken != nil {
                        chatService.connectToServer()
                    }
                }
                .onChange(of: callManager.callState) { _, newState in
                    showIncomingCall = (newState == .ringing && callManager.incomingCall != nil)
                }
                .fullScreenCover(isPresented: $showIncomingCall) {
                    IncomingCallView()
                        .environmentObject(localization)
                }
        }
    }
}
