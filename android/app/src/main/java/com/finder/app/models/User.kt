package com.finder.app.models

import androidx.compose.ui.graphics.Color
import java.io.Serializable
import java.util.Date
import java.util.UUID

data class FinderUser(
    val id: UUID = UUID.randomUUID(),
    var username: String,
    var displayName: String,
    var avatarIcon: String, // Material icon name
    var avatarColor: AvatarColor,
    var statusText: String,
    var isOnline: Boolean,
    var lastSeen: Date? = null,
    var isVerified: Boolean,
    var isUntrusted: Boolean,
    var isBanned: Boolean,
    var isDeleted: Boolean,
    var finderID: String,
    var joinDate: Date,
    var privacySettings: PrivacySettings
) : Serializable {

    val isCensored: Boolean
        get() = isBanned || isDeleted

    companion object {
        val current: FinderUser
            get() = FinderUser(
                id = UUID.randomUUID(),
                username = "me",
                displayName = "\u042F", // "Я"
                avatarIcon = "person",
                avatarColor = AvatarColor.BLUE,
                statusText = "\u0418\u0441\u043F\u043E\u043B\u044C\u0437\u0443\u044E Finder", // "Использую Finder"
                isOnline = true,
                lastSeen = null,
                isVerified = true,
                isUntrusted = false,
                isBanned = false,
                isDeleted = false,
                finderID = "FID-${UUID.randomUUID().toString().take(8).uppercase()}",
                joinDate = Date(),
                privacySettings = PrivacySettings.default
            )
    }
}

enum class AvatarColor(val color: Color) {
    BLUE(Color(0xFF2196F3)),
    PURPLE(Color(0xFF9C27B0)),
    GREEN(Color(0xFF4CAF50)),
    ORANGE(Color(0xFFFF9800)),
    RED(Color(0xFFF44336)),
    CYAN(Color(0xFF00BCD4)),
    INDIGO(Color(0xFF3F51B5)),
    PINK(Color(0xFFE91E63)),
    GRAY(Color(0xFF9E9E9E));

    companion object {
        fun fromString(value: String): AvatarColor {
            return entries.firstOrNull { it.name.equals(value, ignoreCase = true) } ?: BLUE
        }
    }
}

data class PrivacySettings(
    var showOnlineStatus: Boolean,
    var showLastSeen: Boolean,
    var showReadReceipts: Boolean,
    var allowScreenshots: Boolean,
    var autoDeleteMessages: AutoDeleteInterval,
    var hideTypingIndicator: Boolean,
    var ghostMode: Boolean,           // Full invisibility
    var phantomMessages: Boolean,     // Messages disappear after reading
    var stealthKeyboard: Boolean,     // Don't show "typing..."
    var antiForward: Boolean,         // Forbid message forwarding
    var selfDestructProfile: Boolean, // Profile visible only during active chat
    var ipMasking: Boolean,           // IP masking
    var decoyPin: String? = null      // Fake PIN shows empty account
) : Serializable {

    companion object {
        val default = PrivacySettings(
            showOnlineStatus = true,
            showLastSeen = true,
            showReadReceipts = true,
            allowScreenshots = false,
            autoDeleteMessages = AutoDeleteInterval.NEVER,
            hideTypingIndicator = false,
            ghostMode = false,
            phantomMessages = false,
            stealthKeyboard = false,
            antiForward = false,
            selfDestructProfile = false,
            ipMasking = false,
            decoyPin = null
        )
    }
}

enum class AutoDeleteInterval(
    val rawValue: String,
    val ruName: String,
    val enName: String
) {
    NEVER("never", "\u041D\u0438\u043A\u043E\u0433\u0434\u0430", "Never"),
    THIRTY_SECONDS("thirty_seconds", "30 \u0441\u0435\u043A\u0443\u043D\u0434", "30 seconds"),
    FIVE_MINUTES("five_minutes", "5 \u043C\u0438\u043D\u0443\u0442", "5 minutes"),
    ONE_HOUR("one_hour", "1 \u0447\u0430\u0441", "1 hour"),
    ONE_DAY("one_day", "1 \u0434\u0435\u043D\u044C", "1 day"),
    ONE_WEEK("one_week", "1 \u043D\u0435\u0434\u0435\u043B\u044F", "1 week"),
    ONE_MONTH("one_month", "1 \u043C\u0435\u0441\u044F\u0446", "1 month");

    val localizedName: Pair<String, String>
        get() = Pair(ruName, enName)

    companion object {
        fun fromString(value: String): AutoDeleteInterval {
            return entries.firstOrNull { it.rawValue == value } ?: NEVER
        }
    }
}
