package com.finder.app.services

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

object ScreenshotExceptionsService {
    private const val PREFS_NAME = "finder_screenshot_exceptions"
    private const val KEY_EXCEPTIONS = "exception_usernames"

    private lateinit var prefs: SharedPreferences

    private val _exceptionUsernames = MutableStateFlow<Set<String>>(emptySet())
    val exceptionUsernames: StateFlow<Set<String>> = _exceptionUsernames.asStateFlow()

    val count: Int get() = _exceptionUsernames.value.size

    fun init(context: Context) {
        prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val raw = prefs.getString(KEY_EXCEPTIONS, "") ?: ""
        _exceptionUsernames.value = if (raw.isBlank()) emptySet() else raw.split(",").toSet()
    }

    fun addException(username: String) {
        _exceptionUsernames.value = _exceptionUsernames.value + username
        save()
    }

    fun removeException(username: String) {
        _exceptionUsernames.value = _exceptionUsernames.value - username
        save()
    }

    fun isException(username: String): Boolean = _exceptionUsernames.value.contains(username)

    private fun save() {
        prefs.edit().putString(KEY_EXCEPTIONS, _exceptionUsernames.value.joinToString(",")).apply()
    }
}
