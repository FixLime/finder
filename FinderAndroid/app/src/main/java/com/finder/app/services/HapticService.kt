package com.finder.app.services

import android.content.Context
import android.os.Build
import android.os.VibrationEffect
import android.os.Vibrator
import android.os.VibratorManager
import androidx.compose.ui.hapticfeedback.HapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType

/**
 * Centralized haptic feedback service for Finder.
 * Uses Compose HapticFeedback where available, falls back to system Vibrator.
 */
object HapticService {

    private var vibrator: Vibrator? = null

    fun init(context: Context) {
        vibrator = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            val manager = context.getSystemService(Context.VIBRATOR_MANAGER_SERVICE) as? VibratorManager
            manager?.defaultVibrator
        } else {
            @Suppress("DEPRECATION")
            context.getSystemService(Context.VIBRATOR_SERVICE) as? Vibrator
        }
    }

    /** Light tap for selections and toggles */
    fun lightTap(haptic: HapticFeedback? = null) {
        haptic?.performHapticFeedback(HapticFeedbackType.TextHandleMove)
            ?: vibrateMs(20)
    }

    /** Medium tap for button presses */
    fun mediumTap(haptic: HapticFeedback? = null) {
        haptic?.performHapticFeedback(HapticFeedbackType.LongPress)
            ?: vibrateMs(40)
    }

    /** Success feedback */
    fun success(haptic: HapticFeedback? = null) {
        haptic?.performHapticFeedback(HapticFeedbackType.LongPress)
            ?: vibrateMs(50)
    }

    /** Warning feedback */
    fun warning() {
        vibrateMs(80)
    }

    /** Error feedback */
    fun error() {
        vibrateMs(100)
    }

    /** Destructive action pattern */
    fun destructionPattern() {
        vibrateMs(100)
    }

    private fun vibrateMs(ms: Long) {
        val v = vibrator ?: return
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            v.vibrate(VibrationEffect.createOneShot(ms, VibrationEffect.DEFAULT_AMPLITUDE))
        } else {
            @Suppress("DEPRECATION")
            v.vibrate(ms)
        }
    }
}
