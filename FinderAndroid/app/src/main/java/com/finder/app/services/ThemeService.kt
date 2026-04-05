package com.finder.app.services

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

object ThemeService {
    private const val PREFS_NAME = "finder_theme_prefs"
    private const val KEY_DARK_MODE = "dark_mode"

    private lateinit var prefs: SharedPreferences

    private val _isDarkMode = MutableStateFlow(true)
    val isDarkMode: StateFlow<Boolean> = _isDarkMode.asStateFlow()

    fun init(context: Context) {
        prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        _isDarkMode.value = prefs.getBoolean(KEY_DARK_MODE, true)
    }

    fun toggleDarkMode() {
        val newValue = !_isDarkMode.value
        _isDarkMode.value = newValue
        if (::prefs.isInitialized) {
            prefs.edit().putBoolean(KEY_DARK_MODE, newValue).apply()
        }
    }

    fun setDarkMode(enabled: Boolean) {
        _isDarkMode.value = enabled
        if (::prefs.isInitialized) {
            prefs.edit().putBoolean(KEY_DARK_MODE, enabled).apply()
        }
    }
}
