package com.finder.app.navigation

sealed class NavRoutes(val route: String) {
    object Onboarding : NavRoutes("onboarding")
    object Login : NavRoutes("login")
    object PinSetup : NavRoutes("pin_setup")
    object PinLogin : NavRoutes("pin_login")
    object BiometricLock : NavRoutes("biometric_lock")
    object BannedScreen : NavRoutes("banned")
    object DeletedScreen : NavRoutes("deleted")
    object DecoyScreen : NavRoutes("decoy")
    object Main : NavRoutes("main")
    object ChatDetail : NavRoutes("chat/{chatId}") {
        fun createRoute(chatId: String) = "chat/$chatId"
    }
    object UserProfile : NavRoutes("profile/{userId}") {
        fun createRoute(userId: String) = "profile/$userId"
    }
    object Settings : NavRoutes("settings")
    object PrivacySettings : NavRoutes("privacy_settings")
    object AccountSettings : NavRoutes("account_settings")
    object AdminPanel : NavRoutes("admin")
    object Notes : NavRoutes("notes")
    object CreateChat : NavRoutes("create_chat")
    object ActiveCall : NavRoutes("active_call")
    object ReportUser : NavRoutes("report/{userId}") {
        fun createRoute(userId: String) = "report/$userId"
    }
}
