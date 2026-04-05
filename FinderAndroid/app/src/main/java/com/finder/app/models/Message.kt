package com.finder.app.models

import java.io.Serializable
import java.util.Date
import java.util.UUID

data class Message(
    val id: UUID = UUID.randomUUID(),
    val senderId: UUID,
    val chatId: UUID,
    var text: String,
    val timestamp: Date,
    var isRead: Boolean,
    var isDelivered: Boolean,
    var isEdited: Boolean,
    var replyToId: UUID? = null,
    var messageType: MessageType,
    var isPhantom: Boolean,              // Disappears after reading
    var selfDestructTime: Double? = null, // Self-destruct timer in seconds
    var isForwardable: Boolean,
    var encryptedPayload: EncryptedMessage? = null
) : Serializable {

    fun isFromCurrentUser(currentUserId: UUID): Boolean {
        return senderId == currentUserId
    }

    companion object {
        fun system(text: String, chatId: UUID): Message {
            return Message(
                id = UUID.randomUUID(),
                senderId = UUID.randomUUID(),
                chatId = chatId,
                text = text,
                timestamp = Date(),
                isRead = true,
                isDelivered = true,
                isEdited = false,
                replyToId = null,
                messageType = MessageType.SYSTEM,
                isPhantom = false,
                selfDestructTime = null,
                isForwardable = false,
                encryptedPayload = null
            )
        }
    }
}

enum class MessageType(val rawValue: String) {
    TEXT("text"),
    IMAGE("image"),
    VOICE("voice"),
    SYSTEM("system"),
    NOTE("note");

    companion object {
        fun fromString(value: String): MessageType {
            return entries.firstOrNull { it.rawValue == value } ?: TEXT
        }
    }
}

data class EncryptedMessage(
    val ciphertext: String,      // Base64 AES-256-GCM ciphertext
    val nonce: String,           // Base64 nonce/IV
    val senderPublicKey: String  // Base64 X25519 public key
) : Serializable
