package com.finder.app.models

import kotlinx.serialization.Serializable

@Serializable
data class AuthResponse(
    val token: String,
    val user: ServerUser
)

@Serializable
data class LoginRequest(
    val username: String,
    val password: String
)

@Serializable
data class RegisterRequest(
    val username: String,
    val password: String,
    val display_name: String
)

@Serializable
data class CreateChatRequest(
    val participant_ids: List<String>,
    val is_group: Boolean = false,
    val group_name: String? = null
)

@Serializable
data class SendMessageRequest(
    val text: String,
    val message_type: String = "text",
    val reply_to_id: String? = null
)

@Serializable
data class StartCallRequest(
    val chat_id: String,
    val is_video: Boolean
)

@Serializable
data class ServerCall(
    val id: String,
    val chat_id: String,
    val caller_id: String,
    val is_video: Boolean,
    val status: String,
    val started_at: String? = null,
    val ended_at: String? = null,
    val duration: Int? = null
)
