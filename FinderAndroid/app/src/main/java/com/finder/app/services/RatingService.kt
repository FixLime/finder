package com.finder.app.services

import android.content.Context
import android.content.SharedPreferences
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

object RatingService {

    private const val PREFS_NAME = "finder_rating_prefs"
    private const val KEY_POINTS = "rating_points"
    private const val KEY_TIER = "rating_tier"

    const val TIER_2_THRESHOLD = 5000

    private lateinit var prefs: SharedPreferences

    private val _points = MutableStateFlow(0)
    val points: StateFlow<Int> = _points.asStateFlow()

    private val _tier = MutableStateFlow(1)
    val tier: StateFlow<Int> = _tier.asStateFlow()

    val isTier2: Boolean
        get() = _tier.value >= 2

    val progressToTier2: Float
        get() {
            if (isTier2) return 1f
            return (_points.value.toFloat() / TIER_2_THRESHOLD).coerceIn(0f, 1f)
        }

    val pointsToNextTier: Int
        get() {
            if (isTier2) return 0
            return (TIER_2_THRESHOLD - _points.value).coerceAtLeast(0)
        }

    fun init(context: Context) {
        prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        _points.value = prefs.getInt(KEY_POINTS, 0)
        _tier.value = prefs.getInt(KEY_TIER, 1)
        recalculateTier()
    }

    fun addPoints(count: Int = 1) {
        _points.value += count
        recalculateTier()
        saveState()
    }

    private fun recalculateTier() {
        _tier.value = if (_points.value >= TIER_2_THRESHOLD) 2 else 1
    }

    fun setPoints(value: Int) {
        _points.value = maxOf(0, value)
        recalculateTier()
        saveState()
    }

    fun resetRating() {
        _points.value = 0
        _tier.value = 1
        saveState()
    }

    private fun saveState() {
        if (::prefs.isInitialized) {
            prefs.edit()
                .putInt(KEY_POINTS, _points.value)
                .putInt(KEY_TIER, _tier.value)
                .apply()
        }
    }
}
