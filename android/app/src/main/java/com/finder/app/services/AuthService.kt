package com.finder.app.services

import android.app.Application
import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.util.UUID

object AuthService {

    private const val PREFS_NAME = "finder_auth_prefs"
    private const val KEY_IS_AUTHENTICATED = "is_authenticated"
    private const val KEY_USERNAME = "username"
    private const val KEY_DISPLAY_NAME = "display_name"
    private const val KEY_FINDER_ID = "finder_id"
    private const val KEY_IS_PIN_LOCKED = "is_pin_locked"
    private const val KEY_IS_BANNED = "is_banned_screen"
    private const val KEY_IS_DELETED = "is_deleted_screen"
    private const val KEY_IS_DECOY_MODE = "is_decoy_mode"
    private const val KEY_HAS_COMPLETED_ONBOARDING = "has_completed_onboarding"
    private const val KEY_HAS_SETUP_PIN = "has_setup_pin"
    private const val KEY_PIN_HASH = "pin_hash"
    private const val KEY_DECOY_PIN_HASH = "decoy_pin_hash"
    private const val KEY_BIOMETRIC_BINDING_ENABLED = "biometric_binding_enabled"
    private const val KEY_CUSTOM_BIOMETRIC_ENABLED = "custom_biometric_enabled"

    private lateinit var prefs: SharedPreferences

    private val _isAuthenticated = MutableStateFlow(false)
    val isAuthenticated: StateFlow<Boolean> = _isAuthenticated.asStateFlow()

    private val _currentUsername = MutableStateFlow("")
    val currentUsername: StateFlow<String> = _currentUsername.asStateFlow()

    private val _currentDisplayName = MutableStateFlow("")
    val currentDisplayName: StateFlow<String> = _currentDisplayName.asStateFlow()

    private val _currentFinderID = MutableStateFlow("")
    val currentFinderID: StateFlow<String> = _currentFinderID.asStateFlow()

    private val _isPINLocked = MutableStateFlow(false)
    val isPINLocked: StateFlow<Boolean> = _isPINLocked.asStateFlow()

    private val _isBannedScreen = MutableStateFlow(false)
    val isBannedScreen: StateFlow<Boolean> = _isBannedScreen.asStateFlow()

    private val _isDeletedScreen = MutableStateFlow(false)
    val isDeletedScreen: StateFlow<Boolean> = _isDeletedScreen.asStateFlow()

    private val _isDecoyMode = MutableStateFlow(false)
    val isDecoyMode: StateFlow<Boolean> = _isDecoyMode.asStateFlow()

    private val _hasCompletedOnboarding = MutableStateFlow(false)
    val hasCompletedOnboarding: StateFlow<Boolean> = _hasCompletedOnboarding.asStateFlow()

    private val _hasSetupPIN = MutableStateFlow(false)
    val hasSetupPIN: StateFlow<Boolean> = _hasSetupPIN.asStateFlow()

    private val _biometricBindingEnabled = MutableStateFlow(false)
    val biometricBindingEnabled: StateFlow<Boolean> = _biometricBindingEnabled.asStateFlow()

    private val _customBiometricEnabled = MutableStateFlow(false)
    val customBiometricEnabled: StateFlow<Boolean> = _customBiometricEnabled.asStateFlow()

    val isAdmin: Boolean
        get() = _currentUsername.value == "awfulc"

    fun init(application: Application) {
        prefs = application.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        loadState()
    }

    private fun loadState() {
        _isAuthenticated.value = prefs.getBoolean(KEY_IS_AUTHENTICATED, false)
        _currentUsername.value = prefs.getString(KEY_USERNAME, "") ?: ""
        _currentDisplayName.value = prefs.getString(KEY_DISPLAY_NAME, "") ?: ""
        _currentFinderID.value = prefs.getString(KEY_FINDER_ID, "") ?: ""
        _isPINLocked.value = prefs.getBoolean(KEY_IS_PIN_LOCKED, false)
        _isBannedScreen.value = prefs.getBoolean(KEY_IS_BANNED, false)
        _isDeletedScreen.value = prefs.getBoolean(KEY_IS_DELETED, false)
        _isDecoyMode.value = prefs.getBoolean(KEY_IS_DECOY_MODE, false)
        _hasCompletedOnboarding.value = prefs.getBoolean(KEY_HAS_COMPLETED_ONBOARDING, false)
        _hasSetupPIN.value = prefs.getBoolean(KEY_HAS_SETUP_PIN, false)
        _biometricBindingEnabled.value = prefs.getBoolean(KEY_BIOMETRIC_BINDING_ENABLED, false)
        _customBiometricEnabled.value = prefs.getBoolean(KEY_CUSTOM_BIOMETRIC_ENABLED, false)
    }

    private fun saveState() {
        prefs.edit()
            .putBoolean(KEY_IS_AUTHENTICATED, _isAuthenticated.value)
            .putString(KEY_USERNAME, _currentUsername.value)
            .putString(KEY_DISPLAY_NAME, _currentDisplayName.value)
            .putString(KEY_FINDER_ID, _currentFinderID.value)
            .putBoolean(KEY_IS_PIN_LOCKED, _isPINLocked.value)
            .putBoolean(KEY_IS_BANNED, _isBannedScreen.value)
            .putBoolean(KEY_IS_DELETED, _isDeletedScreen.value)
            .putBoolean(KEY_IS_DECOY_MODE, _isDecoyMode.value)
            .putBoolean(KEY_HAS_COMPLETED_ONBOARDING, _hasCompletedOnboarding.value)
            .putBoolean(KEY_HAS_SETUP_PIN, _hasSetupPIN.value)
            .putBoolean(KEY_BIOMETRIC_BINDING_ENABLED, _biometricBindingEnabled.value)
            .putBoolean(KEY_CUSTOM_BIOMETRIC_ENABLED, _customBiometricEnabled.value)
            .apply()
    }

    fun login(username: String, displayName: String) {
        val finderID = "FID-${UUID.randomUUID().toString().take(8).uppercase()}"
        _currentUsername.value = username
        _currentDisplayName.value = displayName
        _currentFinderID.value = finderID
        _isAuthenticated.value = true
        _hasCompletedOnboarding.value = true
        _isPINLocked.value = false
        _isBannedScreen.value = false
        _isDeletedScreen.value = false
        _isDecoyMode.value = false
        saveState()
    }

    fun logout() {
        _isAuthenticated.value = false
        _currentUsername.value = ""
        _currentDisplayName.value = ""
        _currentFinderID.value = ""
        _isPINLocked.value = false
        _hasSetupPIN.value = false
        _isDecoyMode.value = false
        _isBannedScreen.value = false
        _isDeletedScreen.value = false
        prefs.edit()
            .remove(KEY_PIN_HASH)
            .remove(KEY_DECOY_PIN_HASH)
            .apply()
        saveState()
    }

    fun setupPIN(pin: String) {
        val pinHash = pin.hashCode().toString()
        prefs.edit().putString(KEY_PIN_HASH, pinHash).apply()
        _hasSetupPIN.value = true
        _isPINLocked.value = true
        saveState()
    }

    fun setupDecoyPIN(pin: String) {
        val pinHash = pin.hashCode().toString()
        prefs.edit().putString(KEY_DECOY_PIN_HASH, pinHash).apply()
    }

    fun verifyPIN(pin: String): Boolean {
        val inputHash = pin.hashCode().toString()

        // Check decoy PIN first
        val decoyHash = prefs.getString(KEY_DECOY_PIN_HASH, null)
        if (decoyHash != null && inputHash == decoyHash) {
            _isDecoyMode.value = true
            _isPINLocked.value = false
            saveState()
            return true
        }

        // Check real PIN
        val storedHash = prefs.getString(KEY_PIN_HASH, null)
        if (storedHash != null && inputHash == storedHash) {
            _isDecoyMode.value = false
            _isPINLocked.value = false
            saveState()
            return true
        }

        return false
    }

    fun lockWithPIN() {
        if (_hasSetupPIN.value) {
            _isPINLocked.value = true
            saveState()
        }
    }

    fun executeFenixProtocol() {
        // Fenix Protocol: wipe all local data
        _isAuthenticated.value = false
        _currentUsername.value = ""
        _currentDisplayName.value = ""
        _currentFinderID.value = ""
        _isPINLocked.value = false
        _hasSetupPIN.value = false
        _hasCompletedOnboarding.value = false
        _isDecoyMode.value = false
        _isBannedScreen.value = false
        _isDeletedScreen.value = false
        _biometricBindingEnabled.value = false
        _customBiometricEnabled.value = false
        prefs.edit().clear().apply()
        saveState()
    }

    fun forceLogoutBanned() {
        _isBannedScreen.value = true
        _isAuthenticated.value = false
        saveState()
    }

    fun forceLogoutDeleted() {
        _isDeletedScreen.value = true
        _isAuthenticated.value = false
        saveState()
    }

    fun restoreAccount(finderID: String): Boolean {
        if (finderID == _currentFinderID.value || finderID.startsWith("FID-")) {
            _isBannedScreen.value = false
            _isDeletedScreen.value = false
            _isAuthenticated.value = true
            saveState()
            return true
        }
        return false
    }

    fun setBiometricBindingEnabled(enabled: Boolean) {
        _biometricBindingEnabled.value = enabled
        saveState()
    }

    fun setCustomBiometricEnabled(enabled: Boolean) {
        _customBiometricEnabled.value = enabled
        saveState()
    }

    fun completeOnboarding() {
        _hasCompletedOnboarding.value = true
        saveState()
    }
}
