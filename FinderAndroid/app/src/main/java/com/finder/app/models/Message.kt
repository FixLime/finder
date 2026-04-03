package com.finder.app.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ServerMessage(
    val id: String,
    @SerialName("chat_id") val chatId: String,
    @SerialName("sender_id") val senderId: String,
    val text: String,
    @SerialName("message_type") val messageType: String? = null,
    @SerialName("reply_to_id") val replyToId: String? = null,
    @SerialName("is_edited") val isEdited: Boolean? = null,
    @SerialName("created_at") val createdAt: String? = null,
    val sender: ServerUser? = null
)

data class Message(
    val id: String,
    val chatId: String,
    val senderId: String,
    val text: String,
    val timestamp: Long = System.currentTimeMillis(),
    val messageType: String = "text",
    val isRead: Boolean = false,
    val isDelivered: Boolean = true,
    val isEdited: Boolean = false,
    val replyToId: String? = null,
    val senderName: String? = null
) {
    fun isFromCurrentUser(currentUserId: String): Boolean = senderId == currentUserId
}

fun ServerMessage.toMessage() = Message(
    id = id,
    chatId = chatId,
    senderId = senderId,
    text = text,
    messageType = messageType ?: "text",
    isEdited = isEdited ?: false,
    replyToId = replyToId,
    senderName = sender?.displayName,
    timestamp = try {
        java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.US)
            .parse(createdAt ?: "")?.time ?: System.currentTimeMillis()
    } catch (_: Exception) { System.currentTimeMillis() }
)
