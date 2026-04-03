package com.finder.app

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.animation.*
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import androidx.navigation.navArgument
import com.finder.app.models.Chat
import com.finder.app.ui.auth.AuthScreen
import com.finder.app.ui.auth.AuthViewModel
import com.finder.app.ui.call.CallScreen
import com.finder.app.ui.chat.ChatScreen
import com.finder.app.ui.main.ChatListScreen
import com.finder.app.ui.main.ChatListViewModel
import com.finder.app.ui.main.CreateChatScreen
import com.finder.app.ui.theme.FinderTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            FinderTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    FinderApp()
                }
            }
        }
    }
}

@Composable
fun FinderApp() {
    val authViewModel: AuthViewModel = viewModel()
    val chatListViewModel: ChatListViewModel = viewModel()
    val navController = rememberNavController()

    val isLoggedIn by authViewModel.isLoggedIn.collectAsState()
    val isLoading by authViewModel.isLoading.collectAsState()
    val error by authViewModel.error.collectAsState()
    val chats by chatListViewModel.chats.collectAsState()
    val searchResults by chatListViewModel.searchResults.collectAsState()
    val isSearching by chatListViewModel.isSearching.collectAsState()
    val isChatListLoading by chatListViewModel.isLoading.collectAsState()

    // Store selected chat for navigation
    var selectedChat by remember { mutableStateOf<Chat?>(null) }

    if (!isLoggedIn) {
        AuthScreen(
            isLoading = isLoading,
            error = error,
            onLogin = { username, password ->
                authViewModel.login(username, password)
            }
        )
    } else {
        NavHost(navController = navController, startDestination = "chatList") {
            composable("chatList") {
                ChatListScreen(
                    chats = chats,
                    isLoading = isChatListLoading,
                    onChatClick = { chat ->
                        selectedChat = chat
                        navController.navigate("chat")
                    },
                    onNewChat = { navController.navigate("createChat") },
                    onLogout = { authViewModel.logout() },
                    onRefresh = { chatListViewModel.loadChats() }
                )
            }

            composable("createChat") {
                CreateChatScreen(
                    searchResults = searchResults,
                    isSearching = isSearching,
                    onSearch = { chatListViewModel.searchUsers(it) },
                    onUserClick = { user ->
                        chatListViewModel.createChat(user) { chat ->
                            selectedChat = chat
                            navController.navigate("chat") {
                                popUpTo("chatList")
                            }
                        }
                    },
                    onBack = { navController.popBackStack() }
                )
            }

            composable("chat") {
                selectedChat?.let { chat ->
                    ChatScreen(
                        chat = chat,
                        onBack = { navController.popBackStack() },
                        onCall = { isVideo ->
                            navController.navigate("call/${chat.id}/${chat.displayName}/$isVideo")
                        }
                    )
                }
            }

            composable(
                "call/{chatId}/{callerName}/{isVideo}",
                arguments = listOf(
                    navArgument("chatId") { type = NavType.StringType },
                    navArgument("callerName") { type = NavType.StringType },
                    navArgument("isVideo") { type = NavType.BoolType }
                )
            ) { backStackEntry ->
                val chatId = backStackEntry.arguments?.getString("chatId") ?: ""
                val callerName = backStackEntry.arguments?.getString("callerName") ?: ""
                val isVideo = backStackEntry.arguments?.getBoolean("isVideo") ?: false

                CallScreen(
                    chatId = chatId,
                    callerName = callerName,
                    isVideo = isVideo,
                    isIncoming = false,
                    onEnd = { navController.popBackStack() }
                )
            }
        }
    }
}
