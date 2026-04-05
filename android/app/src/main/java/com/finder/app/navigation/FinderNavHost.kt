package com.finder.app.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.finder.app.models.FinderUser
import com.finder.app.services.AuthService
import com.finder.app.services.ChatService
import com.finder.app.ui.screens.admin.AdminPanelScreen
import com.finder.app.ui.screens.auth.BannedScreen
import com.finder.app.ui.screens.auth.BiometricLockScreen
import com.finder.app.ui.screens.auth.DeletedScreen
import com.finder.app.ui.screens.auth.FinderIDSetupScreen
import com.finder.app.ui.screens.auth.PinCodeScreen
import com.finder.app.ui.screens.calls.ActiveCallScreen
import com.finder.app.ui.screens.main.ChatDetailScreen
import com.finder.app.ui.screens.main.CreateChatScreen
import com.finder.app.ui.screens.main.MainScreen
import com.finder.app.ui.screens.notes.NotesScreen
import com.finder.app.ui.screens.onboarding.OnboardingScreen
import com.finder.app.ui.screens.profile.ReportUserScreen
import com.finder.app.ui.screens.profile.UserProfileScreen
import com.finder.app.ui.screens.settings.AccountSettingsScreen
import com.finder.app.ui.screens.settings.PrivacySettingsScreen
import com.finder.app.ui.screens.settings.SettingsScreen
import java.util.UUID

@Composable
fun FinderNavHost(
    navController: NavHostController = rememberNavController()
) {
    val hasCompletedOnboarding by AuthService.hasCompletedOnboarding.collectAsStateWithLifecycle()
    val isAuthenticated by AuthService.isAuthenticated.collectAsStateWithLifecycle()
    val isBanned by AuthService.isBannedScreen.collectAsStateWithLifecycle()
    val isDeleted by AuthService.isDeletedScreen.collectAsStateWithLifecycle()
    val isDecoyMode by AuthService.isDecoyMode.collectAsStateWithLifecycle()
    val isPINLocked by AuthService.isPINLocked.collectAsStateWithLifecycle()
    val hasSetupPIN by AuthService.hasSetupPIN.collectAsStateWithLifecycle()
    val finderID by AuthService.currentFinderID.collectAsStateWithLifecycle()

    val targetRoute by remember {
        derivedStateOf {
            when {
                isBanned -> NavRoutes.BannedScreen.route
                isDeleted -> NavRoutes.DeletedScreen.route
                !hasCompletedOnboarding -> NavRoutes.Onboarding.route
                finderID.isEmpty() -> NavRoutes.Login.route
                !hasSetupPIN -> NavRoutes.PinSetup.route
                isDecoyMode -> NavRoutes.DecoyScreen.route
                isPINLocked -> NavRoutes.PinLogin.route
                isAuthenticated -> NavRoutes.Main.route
                else -> NavRoutes.PinLogin.route
            }
        }
    }

    LaunchedEffect(targetRoute) {
        val currentRoute = navController.currentDestination?.route
        if (currentRoute != null && currentRoute != targetRoute) {
            navController.navigate(targetRoute) {
                popUpTo(0) { inclusive = true }
                launchSingleTop = true
            }
        }
    }

    NavHost(
        navController = navController,
        startDestination = targetRoute
    ) {
        // Auth flow
        composable(NavRoutes.Onboarding.route) {
            OnboardingScreen(
                onNavigateToSetup = {
                    AuthService.completeOnboarding()
                }
            )
        }

        composable(NavRoutes.Login.route) {
            FinderIDSetupScreen(
                onSetupComplete = {
                    // AuthService.login() is called inside the screen
                }
            )
        }

        composable(NavRoutes.PinSetup.route) {
            PinCodeScreen(
                isSetup = true,
                onPinCreated = { pin ->
                    AuthService.setupPIN(pin)
                }
            )
        }

        composable(NavRoutes.PinLogin.route) {
            PinCodeScreen(
                isSetup = false,
                onPinVerified = {
                    // AuthService.verifyPIN() is called inside the screen
                }
            )
        }

        composable(NavRoutes.BiometricLock.route) {
            BiometricLockScreen(
                onNavigateToPIN = {
                    navController.navigate(NavRoutes.PinLogin.route)
                }
            )
        }

        // Blocked states
        composable(NavRoutes.BannedScreen.route) {
            BannedScreen()
        }

        composable(NavRoutes.DeletedScreen.route) {
            DeletedScreen()
        }

        composable(NavRoutes.DecoyScreen.route) {
            // Decoy mode - show empty main screen
            MainScreen()
        }

        // Main app
        composable(NavRoutes.Main.route) {
            val chats by ChatService.chats.collectAsStateWithLifecycle()

            MainScreen(
                chats = chats,
                onChatSelected = { chat ->
                    navController.navigate(
                        NavRoutes.ChatDetail.createRoute(chat.id.toString())
                    )
                },
                onCreateChat = {
                    navController.navigate(NavRoutes.CreateChat.route)
                },
                onOpenSettings = {
                    navController.navigate(NavRoutes.Settings.route)
                }
            )
        }

        composable(
            route = NavRoutes.ChatDetail.route,
            arguments = listOf(navArgument("chatId") { type = NavType.StringType })
        ) { backStackEntry ->
            val chatId = backStackEntry.arguments?.getString("chatId") ?: return@composable
            val chats by ChatService.chats.collectAsStateWithLifecycle()
            val chat = chats.firstOrNull { it.id.toString() == chatId }

            if (chat != null) {
                ChatDetailScreen(
                    chat = chat,
                    currentUserId = FinderUser.current.id,
                    onBack = { navController.popBackStack() },
                    onSendMessage = { text ->
                        ChatService.sendMessage(UUID.fromString(chatId), text)
                    },
                    onVoiceCall = {
                        navController.navigate(NavRoutes.ActiveCall.route)
                    }
                )
            }
        }

        composable(NavRoutes.CreateChat.route) {
            CreateChatScreen(
                onBack = { navController.popBackStack() },
                onStartChat = { user ->
                    val chat = ChatService.startChat(user)
                    navController.popBackStack()
                    navController.navigate(
                        NavRoutes.ChatDetail.createRoute(chat.id.toString())
                    )
                }
            )
        }

        composable(
            route = NavRoutes.UserProfile.route,
            arguments = listOf(navArgument("userId") { type = NavType.StringType })
        ) { backStackEntry ->
            val userId = backStackEntry.arguments?.getString("userId") ?: return@composable
            UserProfileScreen(
                userId = userId,
                onBack = { navController.popBackStack() },
                onStartChat = { navController.popBackStack() },
                onReport = {
                    navController.navigate(NavRoutes.ReportUser.createRoute(userId))
                }
            )
        }

        composable(NavRoutes.Settings.route) {
            SettingsScreen(
                onBack = { navController.popBackStack() },
                onNavigateToPrivacy = {
                    navController.navigate(NavRoutes.PrivacySettings.route)
                },
                onNavigateToAccount = {
                    navController.navigate(NavRoutes.AccountSettings.route)
                },
                onNavigateToAdmin = {
                    navController.navigate(NavRoutes.AdminPanel.route)
                }
            )
        }

        composable(NavRoutes.PrivacySettings.route) {
            PrivacySettingsScreen(
                onBack = { navController.popBackStack() }
            )
        }

        composable(NavRoutes.AccountSettings.route) {
            AccountSettingsScreen(
                onBack = { navController.popBackStack() }
            )
        }

        composable(NavRoutes.AdminPanel.route) {
            AdminPanelScreen(
                onBack = { navController.popBackStack() }
            )
        }

        composable(NavRoutes.Notes.route) {
            NotesScreen(
                onBack = { navController.popBackStack() }
            )
        }

        composable(NavRoutes.ActiveCall.route) {
            ActiveCallScreen(
                onEndCall = { navController.popBackStack() }
            )
        }

        composable(
            route = NavRoutes.ReportUser.route,
            arguments = listOf(navArgument("userId") { type = NavType.StringType })
        ) { backStackEntry ->
            val userId = backStackEntry.arguments?.getString("userId") ?: return@composable
            ReportUserScreen(
                userId = userId,
                onBack = { navController.popBackStack() }
            )
        }
    }
}
