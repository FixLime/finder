package com.finder.app.services

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

object LocalizationService {

    private const val PREFS_NAME = "finder_localization_prefs"
    private const val KEY_LANGUAGE = "app_language"

    private lateinit var prefs: SharedPreferences

    private val _isRussian = MutableStateFlow(true)
    val isRussian: StateFlow<Boolean> = _isRussian.asStateFlow()

    fun init(context: Context) {
        prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        _isRussian.value = prefs.getString(KEY_LANGUAGE, "ru") == "ru"
    }

    fun toggleLanguage() {
        val newValue = !_isRussian.value
        _isRussian.value = newValue
        if (::prefs.isInitialized) {
            prefs.edit().putString(KEY_LANGUAGE, if (newValue) "ru" else "en").apply()
        }
    }

    fun localized(ru: String, en: String): String {
        return if (_isRussian.value) ru else en
    }

    // General
    val chats get() = localized("Чаты", "Chats")
    val settings get() = localized("Настройки", "Settings")
    val profile get() = localized("Профиль", "Profile")
    val notes get() = localized("Заметки", "Notes")
    val search get() = localized("Поиск", "Search")
    val cancel get() = localized("Отмена", "Cancel")
    val delete get() = localized("Удалить", "Delete")
    val save get() = localized("Сохранить", "Save")
    val done get() = localized("Готово", "Done")
    val next get() = localized("Далее", "Next")
    val back get() = localized("Назад", "Back")
    val online get() = localized("в сети", "online")
    val offline get() = localized("не в сети", "offline")
    val lastSeenText get() = localized("был(а)", "last seen")

    // Settings
    val privacy get() = localized("Конфиденциальность", "Privacy")
    val appearance get() = localized("Внешний вид", "Appearance")
    val language get() = localized("Язык", "Language")
    val darkMode get() = localized("Тёмная тема", "Dark Mode")
    val fenixProtocol get() = localized("Протокол Fenix", "Fenix Protocol")
    val ghostMode get() = localized("Режим призрака", "Ghost Mode")
    val phantomMessages get() = localized("Фантомные сообщения", "Phantom Messages")
    val autoDelete get() = localized("Автоудаление", "Auto-Delete")
    val screenshots get() = localized("Скриншоты", "Screenshots")
    val readReceipts get() = localized("Отчёты о прочтении", "Read Receipts")
    val onlineStatus get() = localized("Статус онлайн", "Online Status")
    val typingIndicator get() = localized("Индикатор набора", "Typing Indicator")
    val antiForward get() = localized("Запрет пересылки", "Anti-Forward")
    val ipMask get() = localized("Маскировка IP", "IP Masking")
    val decoyPinTitle get() = localized("Decoy PIN", "Decoy PIN")
    val biometricBinding get() = localized("Привязка биометрии", "Biometric Binding")
    val logout get() = localized("Выйти", "Log Out")
    val aboutFinder get() = localized("О Finder", "About Finder")
    val accountSettings get() = localized("Настройки аккаунта", "Account Settings")

    // Rating
    val rating get() = localized("Рейтинг", "Rating")
    val ratingPoints get() = localized("очков", "points")
    val tier get() = localized("Уровень", "Tier")
    val featureLocked get() = localized("Функция заблокирована", "Feature Locked")
    val tier2Required get() = localized("Требуется 2 уровень рейтинга", "Tier 2 rating required")

    // Admin
    val adminPanel get() = localized("Админ-панель", "Admin Panel")
    val username get() = localized("Юзернейм", "Username")

    // Account
    val switchAccount get() = localized("Сменить аккаунт", "Switch Account")
}
