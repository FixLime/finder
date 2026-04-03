package com.finder.app.ui.main

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.finder.app.models.*
import com.finder.app.services.ApiService
import com.finder.app.services.WebSocketService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class ChatListViewModel : ViewModel() {
    private val _chats = MutableStateFlow<List<Chat>>(emptyList())
    val chats = _chats.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    // Search
    private val _searchResults = MutableStateFlow<List<FinderUser>>(emptyList())
    val searchResults = _searchResults.asStateFlow()

    private val _isSearching = MutableStateFlow(false)
    val isSearching = _isSearching.asStateFlow()

    init {
        loadChats()
        listenForMessages()
    }

    fun loadChats() {
        viewModelScope.launch {
            _isLoading.value = true
            try {
                val serverChats = ApiService.getChats()
                _chats.value = serverChats.map { it.toChat() }
            } catch (e: Exception) {
                e.printStackTrace()
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun searchUsers(query: String) {
        if (query.isBlank()) {
            _searchResults.value = emptyList()
            _isSearching.value = false
            return
        }
        viewModelScope.launch {
            _isSearching.value = true
            try {
                val users = ApiService.searchUsers(query)
                _searchResults.value = users
                    .map { it.toFinderUser() }
                    .filter { it.id != ApiService.currentUserId && !it.isCensored }
            } catch (e: Exception) {
                _searchResults.value = emptyList()
            } finally {
                _isSearching.value = false
            }
        }
    }

    fun createChat(user: FinderUser, onCreated: (Chat) -> Unit) {
        // Check if chat already exists
        val existing = _chats.value.find { chat ->
            !chat.isGroup && !chat.isChannel &&
            chat.participants.any { it.id == user.id }
        }
        if (existing != null) {
            onCreated(existing)
            return
        }

        viewModelScope.launch {
            try {
                val serverChat = ApiService.createChat(listOf(user.id))
                val chat = serverChat.toChat()
                _chats.value = _chats.value + chat
                onCreated(chat)
            } catch (e: Exception) {
                e.printStackTrace()
            }
        }
    }

    private fun listenForMessages() {
        viewModelScope.launch {
            WebSocketService.messageReceived.collect { serverMsg ->
                val message = serverMsg.toMessage()
                val updatedChats = _chats.value.toMutableList()
                val chatIndex = updatedChats.indexOfFirst { it.id == message.chatId }
                if (chatIndex >= 0) {
                    val chat = updatedChats[chatIndex]
                    chat.messages.add(message)
                    updatedChats[chatIndex] = chat.copy(
                        unreadCount = if (message.senderId != ApiService.currentUserId)
                            chat.unreadCount + 1 else chat.unreadCount
                    )
                    _chats.value = updatedChats
                } else {
                    // New chat — reload from server
                    loadChats()
                }
            }
        }
    }

    fun updateChatMessages(chatId: String, messages: List<Message>) {
        val updatedChats = _chats.value.toMutableList()
        val idx = updatedChats.indexOfFirst { it.id == chatId }
        if (idx >= 0) {
            updatedChats[idx].messages.clear()
            updatedChats[idx].messages.addAll(messages)
            _chats.value = updatedChats
        }
    }
}
