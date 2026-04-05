package com.finder.app.services

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

object AdminService {
    private const val PREFS_NAME = "finder_admin_prefs"
    private const val KEY_VERIFIED = "verified_usernames"
    private const val KEY_BANNED = "banned_usernames"
    private const val KEY_DELETED = "deleted_usernames"
    private const val KEY_UNTRUSTED = "untrusted_usernames"

    private lateinit var prefs: SharedPreferences

    private val _verifiedUsernames = MutableStateFlow<Set<String>>(emptySet())
    val verifiedUsernames: StateFlow<Set<String>> = _verifiedUsernames.asStateFlow()

    private val _bannedUsernames = MutableStateFlow<Set<String>>(emptySet())
    val bannedUsernames: StateFlow<Set<String>> = _bannedUsernames.asStateFlow()

    private val _deletedUsernames = MutableStateFlow<Set<String>>(emptySet())
    val deletedUsernames: StateFlow<Set<String>> = _deletedUsernames.asStateFlow()

    private val _untrustedUsernames = MutableStateFlow<Set<String>>(emptySet())
    val untrustedUsernames: StateFlow<Set<String>> = _untrustedUsernames.asStateFlow()

    fun init(context: Context) {
        prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        loadState()
    }

    private fun loadState() {
        _verifiedUsernames.value = loadSet(KEY_VERIFIED)
        _bannedUsernames.value = loadSet(KEY_BANNED)
        _deletedUsernames.value = loadSet(KEY_DELETED)
        _untrustedUsernames.value = loadSet(KEY_UNTRUSTED)
    }

    private fun loadSet(key: String): Set<String> {
        val raw = prefs.getString(key, "") ?: ""
        return if (raw.isBlank()) emptySet() else raw.split(",").toSet()
    }

    private fun saveSet(key: String, set: Set<String>) {
        prefs.edit().putString(key, set.joinToString(",")).apply()
    }

    fun isVerified(username: String): Boolean = _verifiedUsernames.value.contains(username)
    fun isBanned(username: String): Boolean = _bannedUsernames.value.contains(username)
    fun isDeleted(username: String): Boolean = _deletedUsernames.value.contains(username)
    fun isUntrusted(username: String): Boolean = _untrustedUsernames.value.contains(username)

    fun verifyUser(username: String) {
        _verifiedUsernames.value = _verifiedUsernames.value + username
        saveSet(KEY_VERIFIED, _verifiedUsernames.value)
    }

    fun unverifyUser(username: String) {
        _verifiedUsernames.value = _verifiedUsernames.value - username
        saveSet(KEY_VERIFIED, _verifiedUsernames.value)
    }

    fun banUser(username: String) {
        _bannedUsernames.value = _bannedUsernames.value + username
        saveSet(KEY_BANNED, _bannedUsernames.value)
    }

    fun unbanUser(username: String) {
        _bannedUsernames.value = _bannedUsernames.value - username
        saveSet(KEY_BANNED, _bannedUsernames.value)
    }

    fun deleteUser(username: String) {
        _deletedUsernames.value = _deletedUsernames.value + username
        saveSet(KEY_DELETED, _deletedUsernames.value)
    }

    fun restoreUser(username: String) {
        _deletedUsernames.value = _deletedUsernames.value - username
        saveSet(KEY_DELETED, _deletedUsernames.value)
    }

    fun untrustUser(username: String) {
        _untrustedUsernames.value = _untrustedUsernames.value + username
        saveSet(KEY_UNTRUSTED, _untrustedUsernames.value)
    }

    fun trustUser(username: String) {
        _untrustedUsernames.value = _untrustedUsernames.value - username
        saveSet(KEY_UNTRUSTED, _untrustedUsernames.value)
    }
}
