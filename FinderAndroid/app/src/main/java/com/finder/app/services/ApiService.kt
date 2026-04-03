package com.finder.app.services

import com.finder.app.models.*
import kotlinx.serialization.json.Json
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.IOException

object ApiService {
    private const val BASE_URL = "http://155.212.165.134:3000/api"
    private val client = OkHttpClient.Builder()
        .connectTimeout(15, java.util.concurrent.TimeUnit.SECONDS)
        .readTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
        .build()
    private val json = Json { ignoreUnknownKeys = true; coerceInputValues = true }
    private val jsonMediaType = "application/json; charset=utf-8".toMediaType()

    var authToken: String? = null
    var currentUserId: String? = null

    private fun buildRequest(path: String): Request.Builder {
        val builder = Request.Builder().url("$BASE_URL$path")
        authToken?.let { builder.addHeader("Authorization", "Bearer $it") }
        return builder
    }

    private suspend fun executeRequest(request: Request): String = withContext(Dispatchers.IO) {
        val response = client.newCall(request).execute()
        val body = response.body?.string() ?: ""
        if (!response.isSuccessful) {
            throw IOException("HTTP ${response.code}: $body")
        }
        body
    }

    // Auth
    suspend fun login(username: String, password: String): AuthResponse {
        val body = json.encodeToString(LoginRequest.serializer(), LoginRequest(username, password))
        val request = buildRequest("/login")
            .post(body.toRequestBody(jsonMediaType))
            .build()
        val response = executeRequest(request)
        val auth = json.decodeFromString(AuthResponse.serializer(), response)
        authToken = auth.token
        currentUserId = auth.user.id
        return auth
    }

    suspend fun register(username: String, password: String, displayName: String): AuthResponse {
        val body = json.encodeToString(RegisterRequest.serializer(), RegisterRequest(username, password, displayName))
        val request = buildRequest("/register")
            .post(body.toRequestBody(jsonMediaType))
            .build()
        val response = executeRequest(request)
        val auth = json.decodeFromString(AuthResponse.serializer(), response)
        authToken = auth.token
        currentUserId = auth.user.id
        return auth
    }

    // Users
    suspend fun searchUsers(query: String): List<ServerUser> {
        val encoded = java.net.URLEncoder.encode(query, "UTF-8")
        val request = buildRequest("/users/search?q=$encoded").get().build()
        val response = executeRequest(request)
        return json.decodeFromString(response)
    }

    suspend fun getUser(id: String): ServerUser {
        val request = buildRequest("/users/$id").get().build()
        val response = executeRequest(request)
        return json.decodeFromString(response)
    }

    // Chats
    suspend fun getChats(): List<ServerChat> {
        val request = buildRequest("/chats").get().build()
        val response = executeRequest(request)
        return json.decodeFromString(response)
    }

    suspend fun createChat(participantIds: List<String>, isGroup: Boolean = false, groupName: String? = null): ServerChat {
        val body = json.encodeToString(CreateChatRequest.serializer(), CreateChatRequest(participantIds, isGroup, groupName))
        val request = buildRequest("/chats")
            .post(body.toRequestBody(jsonMediaType))
            .build()
        val response = executeRequest(request)
        return json.decodeFromString(response)
    }

    // Messages
    suspend fun getMessages(chatId: String, limit: Int = 50, offset: Int = 0): List<ServerMessage> {
        val request = buildRequest("/chats/$chatId/messages?limit=$limit&offset=$offset").get().build()
        val response = executeRequest(request)
        return json.decodeFromString(response)
    }

    suspend fun sendMessage(chatId: String, text: String, messageType: String = "text", replyToId: String? = null): ServerMessage {
        val body = json.encodeToString(SendMessageRequest.serializer(), SendMessageRequest(text, messageType, replyToId))
        val request = buildRequest("/chats/$chatId/messages")
            .post(body.toRequestBody(jsonMediaType))
            .build()
        val response = executeRequest(request)
        return json.decodeFromString(response)
    }

    // Calls
    suspend fun startCall(chatId: String, isVideo: Boolean): ServerCall {
        val body = json.encodeToString(StartCallRequest.serializer(), StartCallRequest(chatId, isVideo))
        val request = buildRequest("/calls")
            .post(body.toRequestBody(jsonMediaType))
            .build()
        val response = executeRequest(request)
        return json.decodeFromString(response)
    }

    // Health check
    suspend fun checkHealth(): Boolean = withContext(Dispatchers.IO) {
        try {
            val request = Request.Builder().url("$BASE_URL/health").get().build()
            val response = client.newCall(request).execute()
            response.isSuccessful
        } catch (_: Exception) {
            false
        }
    }

    fun clearAuth() {
        authToken = null
        currentUserId = null
    }
}
