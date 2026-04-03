package com.finder.app.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class ServerChat(
    val id: String,
    @SerialName("is_group") val isGroup: Boolean,
    @SerialName("is_channel") val isChannel: Boolean? = null,
    @SerialName("group_name") val groupName: String? = null,
    @SerialName("created_at") val createdAt: String? = null,
    val members: List<ServerUser>? = null,
    @SerialName("last_message") val lastMessage: ServerMessage? = null,
    @SerialName("unread_count") val unreadCount: Int? = null
)

data class Chat(
    val id: String,
    val participants: List<FinderUser>,
    val messages: MutableList<Message> = mutableListOf(),
    val isGroup: Boolean = false,
    val isChannel: Boolean = false,
    val groupName: String? = null,
    val unreadCount: Int = 0
) {
    val displayName: String
        get() = when {
            isGroup || isChannel -> groupName ?: if (isChannel) "Канал" else "Группа"
            participants.isNotEmpty() -> participants.first().displayName
            else -> "Неизвестный"
        }

    val lastMessage: Message?
        get() = messages.maxByOrNull { it.timestamp }

    val otherUser: FinderUser?
        get() = participants.firstOrNull()
}

fun ServerChat.toChat() = Chat(
    id = id,
    participants = (members ?: emptyList()).map { it.toFinderUser() },
    messages = if (lastMessage != null) mutableListOf(lastMessage.toMessage()) else mutableListOf(),
    isGroup = isGroup,
    isChannel = isChannel ?: false,
    groupName = groupName,
    unreadCount = unreadCount ?: 0
)
