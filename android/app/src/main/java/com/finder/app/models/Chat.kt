package com.finder.app.models

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import java.io.Serializable
import java.util.Date
import java.util.UUID

data class Chat(
    val id: UUID = UUID.randomUUID(),
    var participants: List<FinderUser>,
    var messages: List<Message>,
    var isGroup: Boolean,
    var isChannel: Boolean = false,
    var groupName: String? = null,
    var isPinned: Boolean = false,
    var isMuted: Boolean = false,
    var isArchived: Boolean = false,
    var isNotes: Boolean = false,
    var isSupport: Boolean = false,
    var unreadCount: Int = 0
) : Serializable {

    val lastMessage: Message?
        get() = messages.sortedByDescending { it.timestamp }.firstOrNull()

    fun displayName(currentUserId: UUID): String {
        if (isNotes) return "\u0417\u0430\u043C\u0435\u0442\u043A\u0438" // "Заметки"
        if (isSupport) return "Finder Support"
        if (isGroup || isChannel) return groupName ?: if (isChannel) "\u041A\u0430\u043D\u0430\u043B" else "\u0413\u0440\u0443\u043F\u043F\u0430" // "Канал" / "Группа"
        return participants.firstOrNull { it.id != currentUserId }?.displayName
            ?: "\u041D\u0435\u0438\u0437\u0432\u0435\u0441\u0442\u043D\u044B\u0439" // "Неизвестный"
    }

    fun otherUser(currentUserId: UUID): FinderUser? {
        return participants.firstOrNull { it.id != currentUserId }
    }

    fun isVerifiedChat(currentUserId: UUID, isVerifiedName: (String) -> Boolean): Boolean {
        if (isNotes) return true
        if (isSupport) return true
        if (isGroup || isChannel) {
            return groupName?.let { isVerifiedName(it) } ?: false
        }
        return participants.any { it.isVerified || isVerifiedName(it.username) }
    }

    fun isUntrustedChat(currentUserId: UUID, isUntrustedName: (String) -> Boolean): Boolean {
        if (isNotes || isSupport) return false
        val other = otherUser(currentUserId)
        if (other != null) {
            return other.isUntrusted || isUntrustedName(other.username)
        }
        return false
    }
}

data class Note(
    val id: UUID = UUID.randomUUID(),
    var text: String,
    var timestamp: Date,
    var isPinned: Boolean,
    var category: NoteCategory
) : Serializable

enum class NoteCategory(
    val rawValue: String,
    val ruName: String,
    val enName: String,
    val iconName: String,
    val color: Color
) {
    GENERAL(
        "general",
        "\u041E\u0431\u0449\u0435\u0435",     // "Общее"
        "General",
        "description",                          // doc.text equivalent
        Color(0xFF2196F3)                       // blue
    ),
    IMPORTANT(
        "important",
        "\u0412\u0430\u0436\u043D\u043E\u0435", // "Важное"
        "Important",
        "bolt",                                  // bolt.fill equivalent
        Color(0xFFFF9800)                        // orange
    ),
    IDEAS(
        "ideas",
        "\u0418\u0434\u0435\u0438",             // "Идеи"
        "Ideas",
        "lightbulb",                             // lightbulb.fill equivalent
        Color(0xFFFFEB3B)                        // yellow
    ),
    LINKS(
        "links",
        "\u0421\u0441\u044B\u043B\u043A\u0438", // "Ссылки"
        "Links",
        "link",
        Color(0xFF4CAF50)                        // green
    ),
    PASSWORDS(
        "passwords",
        "\u041F\u0430\u0440\u043E\u043B\u0438", // "Пароли"
        "Passwords",
        "lock",                                  // lock.fill equivalent
        Color(0xFFF44336)                        // red
    );

    companion object {
        fun fromString(value: String): NoteCategory {
            return entries.firstOrNull { it.rawValue == value } ?: GENERAL
        }
    }
}
