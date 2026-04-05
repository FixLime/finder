package com.finder.app.models

import androidx.compose.ui.graphics.Color
import java.io.Serializable
import java.util.Date
import java.util.UUID

data class UserReport(
    val id: UUID = UUID.randomUUID(),
    val reporterUsername: String,
    val reportedUsername: String,
    val category: String,
    val description: String,
    val includeConversation: Boolean,
    val timestamp: Date
) : Serializable

enum class ReportCategory(
    val rawValue: String,
    val iconName: String,
    val color: Color,
    val ruName: String,
    val enName: String,
    val ruDescription: String,
    val enDescription: String
) {
    SPAM(
        "spam",
        "mail",                          // envelope.badge.fill equivalent
        Color(0xFFFF9800),               // orange
        "Спам",
        "Spam",
        "Нежелательные сообщения, реклама",
        "Unwanted messages, advertising"
    ),
    HARASSMENT(
        "harassment",
        "front_hand",                    // hand.raised.fill equivalent
        Color(0xFFF44336),               // red
        "Оскорбления и травля",
        "Harassment & Bullying",
        "Угрозы, запугивание, буллинг",
        "Threats, intimidation, bullying"
    ),
    INAPPROPRIATE_CONTENT(
        "inappropriate_content",
        "visibility_off",                // eye.slash.fill equivalent
        Color(0xFF9C27B0),               // purple
        "Неприемлемый контент",
        "Inappropriate Content",
        "Порнография, шок-контент",
        "Pornography, shock content"
    ),
    SCAM(
        "scam",
        "credit_card_off",               // creditcard.trianglebadge equivalent
        Color(0xFFFFEB3B),               // yellow
        "Мошенничество",
        "Scam & Fraud",
        "Попытка выманить деньги или данные",
        "Attempting to steal money or data"
    ),
    FAKE_ACCOUNT(
        "fake_account",
        "person_off",                    // person.crop.circle.badge.questionmark equivalent
        Color(0xFF3F51B5),               // indigo
        "Фейковый аккаунт",
        "Fake Account",
        "Выдаёт себя за другого человека",
        "Impersonating another person"
    ),
    VIOLENCE(
        "violence",
        "warning",                       // bolt.trianglebadge.exclamationmark.fill equivalent
        Color(0xFFF44336),               // red
        "Призывы к насилию",
        "Violence & Threats",
        "Угрозы физического насилия",
        "Threats of physical violence"
    ),
    PUBLIC_SAFETY_THREAT(
        "public_safety_threat",
        "shield",                        // exclamationmark.shield.fill equivalent
        Color(0xFFF44336),               // red
        "Угроза общественной безопасности",
        "Public Safety Threat",
        "Терроризм, экстремизм, угроза жизни людей",
        "Terrorism, extremism, threat to human life"
    ),
    OTHER(
        "other",
        "more_horiz",                    // ellipsis.circle.fill equivalent
        Color(0xFF9E9E9E),               // gray
        "Другое",
        "Other",
        "Опишите причину жалобы",
        "Describe the reason for your report"
    );

    val isPublicSafety: Boolean
        get() = this == PUBLIC_SAFETY_THREAT

    fun localizedName(isRussian: Boolean): String {
        return if (isRussian) ruName else enName
    }

    fun localizedDescription(isRussian: Boolean): String {
        return if (isRussian) ruDescription else enDescription
    }

    companion object {
        fun fromString(value: String): ReportCategory {
            return entries.firstOrNull { it.rawValue == value } ?: OTHER
        }
    }
}
