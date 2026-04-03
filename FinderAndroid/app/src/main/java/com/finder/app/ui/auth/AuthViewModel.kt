package com.finder.app.ui.auth

import android.app.Application
import android.content.Context
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.finder.app.models.toFinderUser
import com.finder.app.models.FinderUser
import com.finder.app.services.ApiService
import com.finder.app.services.WebSocketService
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class AuthViewModel(application: Application) : AndroidViewModel(application) {
    private val prefs = application.getSharedPreferences("finder_auth", Context.MODE_PRIVATE)

    private val _isLoggedIn = MutableStateFlow(false)
    val isLoggedIn = _isLoggedIn.asStateFlow()

    private val _isLoading = MutableStateFlow(false)
    val isLoading = _isLoading.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error = _error.asStateFlow()

    private val _currentUser = MutableStateFlow<FinderUser?>(null)
    val currentUser = _currentUser.asStateFlow()

    init {
        val savedToken = prefs.getString("token", null)
        val savedUserId = prefs.getString("userId", null)
        val savedUsername = prefs.getString("username", null)
        val savedDisplayName = prefs.getString("displayName", null)

        if (savedToken != null && savedUserId != null) {
            ApiService.authToken = savedToken
            ApiService.currentUserId = savedUserId
            _currentUser.value = FinderUser(
                id = savedUserId,
                username = savedUsername ?: "",
                displayName = savedDisplayName ?: ""
            )
            _isLoggedIn.value = true
            // Connect WebSocket
            WebSocketService.connect(savedToken)
        }
    }

    fun login(username: String, password: String) {
        viewModelScope.launch {
            _isLoading.value = true
            _error.value = null
            try {
                val response = ApiService.login(username, password)
                saveSession(response.token, response.user.id, response.user.username, response.user.displayName)
                _currentUser.value = response.user.toFinderUser()
                _isLoggedIn.value = true
                WebSocketService.connect(response.token)
            } catch (e: Exception) {
                // Try register if login fails
                try {
                    val response = ApiService.register(username, password, username)
                    saveSession(response.token, response.user.id, response.user.username, response.user.displayName)
                    _currentUser.value = response.user.toFinderUser()
                    _isLoggedIn.value = true
                    WebSocketService.connect(response.token)
                } catch (e2: Exception) {
                    _error.value = "Ошибка входа: ${e2.message}"
                }
            } finally {
                _isLoading.value = false
            }
        }
    }

    fun logout() {
        WebSocketService.disconnect()
        ApiService.clearAuth()
        prefs.edit().clear().apply()
        _currentUser.value = null
        _isLoggedIn.value = false
    }

    private fun saveSession(token: String, userId: String, username: String, displayName: String) {
        prefs.edit()
            .putString("token", token)
            .putString("userId", userId)
            .putString("username", username)
            .putString("displayName", displayName)
            .apply()
    }
}
