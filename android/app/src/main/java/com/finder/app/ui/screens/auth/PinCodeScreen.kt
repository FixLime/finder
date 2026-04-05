package com.finder.app.ui.screens.auth

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Backspace
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.ripple
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.finder.app.services.AuthService
import com.finder.app.ui.screens.onboarding.localized
import com.finder.app.ui.theme.FinderTheme
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

/**
 * PIN code screen supporting two modes:
 *
 * **Setup** (`isSetup = true`): enter a 4-digit PIN, then confirm it. Calls [onPinCreated]
 * with the validated PIN string. Shake animation and haptic error on mismatch.
 *
 * **Login** (`isSetup = false`): enter a 4-digit PIN and verify against stored value via
 * [AuthService.verifyPIN]. Calls [onPinVerified] on success. Detects decoy PIN internally.
 * After 5 wrong attempts the pad locks for 30 seconds.
 *
 * Features:
 * - Glass numpad buttons with haptic on each tap
 * - 4 dots that fill/scale as digits are entered
 * - Shake animation on wrong PIN
 * - Optional biometric shortcut button (bottom-left of numpad)
 * - Decoy PIN detection (handled inside AuthService)
 */
@Composable
fun PinCodeScreen(
    isSetup: Boolean = false,
    isRussian: Boolean = true,
    onPinVerified: () -> Unit = {},
    onPinCreated: (String) -> Unit = {},
    showBiometricButton: Boolean = false,
    onBiometricRequest: () -> Unit = {}
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current
    val coroutineScope = rememberCoroutineScope()

    var pin by remember { mutableStateOf("") }
    var confirmPin by remember { mutableStateOf("") }
    var isConfirmStep by remember { mutableStateOf(false) }
    var attempts by remember { mutableIntStateOf(0) }
    var isLocked by remember { mutableStateOf(false) }
    var lockCountdown by remember { mutableIntStateOf(0) }
    var appear by remember { mutableStateOf(false) }

    val shakeOffset = remember { Animatable(0f) }

    // The PIN currently being typed
    val currentPin = if (isSetup && isConfirmStep) pin else pin
    // (In setup: first round fills `confirmPin` after 4 digits, second round fills `pin` for confirm)
    // Re-structure: first entry -> confirmPin, second entry -> pin for matching
    // Actually simpler: first entry stored in confirmPin, then reset pin for re-entry

    LaunchedEffect(Unit) { appear = true }

    val scale by animateFloatAsState(
        targetValue = if (appear) 1f else 0.5f,
        animationSpec = spring(dampingRatio = 0.8f, stiffness = 300f),
        label = "scale"
    )
    val alpha by animateFloatAsState(
        targetValue = if (appear) 1f else 0f,
        animationSpec = tween(500),
        label = "alpha"
    )

    fun triggerShake() {
        coroutineScope.launch {
            for (i in 0..5) {
                shakeOffset.animateTo(
                    targetValue = if (i % 2 == 0) 12f else -12f,
                    animationSpec = tween(durationMillis = 50)
                )
            }
            shakeOffset.animateTo(0f, animationSpec = tween(50))
        }
    }

    fun onDigitEntered(digit: String) {
        if (isLocked) return
        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
        if (pin.length >= 4) return

        pin += digit

        if (pin.length == 4) {
            coroutineScope.launch {
                delay(150)
                if (isSetup) {
                    if (!isConfirmStep) {
                        // First entry done -- save and ask to confirm
                        confirmPin = pin
                        pin = ""
                        isConfirmStep = true
                    } else {
                        // Confirm entry -- compare
                        if (pin == confirmPin) {
                            onPinCreated(pin)
                        } else {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                            triggerShake()
                            delay(400)
                            pin = ""
                            confirmPin = ""
                            isConfirmStep = false
                        }
                    }
                } else {
                    // Login mode -- verify
                    val valid = AuthService.verifyPIN(pin)
                    if (valid) {
                        // AuthService internally detects decoy PIN and sets isDecoyMode
                        onPinVerified()
                    } else {
                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        triggerShake()
                        attempts++
                        if (attempts >= 5) {
                            isLocked = true
                            lockCountdown = 30
                            coroutineScope.launch {
                                while (lockCountdown > 0) {
                                    delay(1000)
                                    lockCountdown--
                                }
                                isLocked = false
                                attempts = 0
                            }
                        }
                        delay(400)
                        pin = ""
                    }
                }
            }
        }
    }

    fun onBackspace() {
        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
        if (pin.isNotEmpty()) pin = pin.dropLast(1)
    }

    // Title / subtitle
    val title = when {
        isSetup && isConfirmStep -> localized(isRussian, "Подтвердите PIN", "Confirm PIN")
        isSetup -> localized(isRussian, "Создайте PIN-код", "Create PIN code")
        else -> localized(isRussian, "Введите PIN-код", "Enter PIN code")
    }
    val subtitle = when {
        isSetup && isConfirmStep -> localized(isRussian, "Введите PIN-код повторно", "Re-enter your PIN")
        isSetup -> localized(isRussian, "4-значный код для защиты аккаунта", "4-digit code to protect your account")
        else -> localized(isRussian, "Для входа в приложение", "To unlock the app")
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier.fillMaxSize(),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.weight(1f))

            // Logo (login mode) or Lock icon (setup mode)
            if (!isSetup) {
                Box(
                    modifier = Modifier
                        .graphicsLayer { scaleX = scale; scaleY = scale; this.alpha = alpha }
                        .size(80.dp)
                        .clip(CircleShape)
                        .background(
                            Brush.linearGradient(listOf(colors.accentBlue, colors.accentCyan))
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "F",
                        fontSize = 40.sp,
                        fontWeight = FontWeight.Bold,
                        color = Color.White
                    )
                }
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = "Finder",
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold,
                    color = colors.textPrimary,
                    modifier = Modifier.graphicsLayer { this.alpha = alpha }
                )
                Spacer(modifier = Modifier.height(8.dp))
            } else {
                Box(
                    modifier = Modifier
                        .graphicsLayer { scaleX = scale; scaleY = scale; this.alpha = alpha }
                        .size(80.dp)
                        .clip(CircleShape)
                        .background(Color(0xFF5C6BC0).copy(alpha = 0.15f)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Filled.Lock,
                        contentDescription = null,
                        tint = Color(0xFF5C6BC0),
                        modifier = Modifier.size(36.dp)
                    )
                }
                Spacer(modifier = Modifier.height(16.dp))
            }

            Text(
                text = title,
                fontSize = if (isSetup) 22.sp else 16.sp,
                fontWeight = if (isSetup) FontWeight.Bold else FontWeight.Normal,
                color = if (isSetup) colors.textPrimary else colors.textSecondary,
                textAlign = TextAlign.Center
            )

            if (isSetup) {
                Spacer(modifier = Modifier.height(4.dp))
                Text(text = subtitle, fontSize = 14.sp, color = colors.textSecondary)
            }

            Spacer(modifier = Modifier.height(32.dp))

            // PIN dots
            Row(
                modifier = Modifier.graphicsLayer { translationX = shakeOffset.value },
                horizontalArrangement = Arrangement.spacedBy(20.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                repeat(4) { index ->
                    val filled = index < pin.length
                    val dotScale by animateFloatAsState(
                        targetValue = if (filled) 1.2f else 1f,
                        animationSpec = spring(dampingRatio = 0.5f, stiffness = 500f),
                        label = "dot$index"
                    )
                    Box(
                        modifier = Modifier
                            .size(18.dp)
                            .graphicsLayer { scaleX = dotScale; scaleY = dotScale }
                            .clip(CircleShape)
                            .background(
                                if (filled) {
                                    if (isSetup) Color(0xFF5C6BC0) else colors.accentBlue
                                } else {
                                    colors.glassCardBackground
                                },
                                CircleShape
                            )
                            .border(1.dp, colors.glassBorder, CircleShape)
                    )
                }
            }

            // Locked message
            if (isLocked) {
                Spacer(modifier = Modifier.height(12.dp))
                Text(
                    text = localized(
                        isRussian,
                        "Подождите ${lockCountdown}с",
                        "Wait ${lockCountdown}s"
                    ),
                    fontSize = 13.sp,
                    color = colors.errorRed
                )
            }

            Spacer(modifier = Modifier.weight(1f))

            // Number pad
            val keys = listOf(
                listOf("1", "2", "3"),
                listOf("4", "5", "6"),
                listOf("7", "8", "9"),
                listOf(if (showBiometricButton) "bio" else "", "0", "back")
            )

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 40.dp)
                    .padding(bottom = 40.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                keys.forEach { row ->
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceEvenly,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        row.forEach { key ->
                            when (key) {
                                "" -> Spacer(modifier = Modifier.size(72.dp))
                                "bio" -> {
                                    GlassNumpadButton(
                                        onClick = onBiometricRequest,
                                        content = {
                                            Icon(
                                                imageVector = Icons.Filled.Fingerprint,
                                                contentDescription = null,
                                                tint = colors.textPrimary,
                                                modifier = Modifier.size(28.dp)
                                            )
                                        }
                                    )
                                }
                                "back" -> {
                                    Box(
                                        modifier = Modifier
                                            .size(72.dp)
                                            .clip(CircleShape)
                                            .clickable(
                                                interactionSource = remember { MutableInteractionSource() },
                                                indication = ripple(bounded = true, radius = 36.dp)
                                            ) { onBackspace() },
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Icon(
                                            imageVector = Icons.Filled.Backspace,
                                            contentDescription = localized(isRussian, "Удалить", "Delete"),
                                            tint = colors.textPrimary,
                                            modifier = Modifier.size(24.dp)
                                        )
                                    }
                                }
                                else -> {
                                    GlassNumpadButton(
                                        onClick = { onDigitEntered(key) },
                                        content = {
                                            Text(
                                                text = key,
                                                fontSize = 28.sp,
                                                fontWeight = FontWeight.Medium,
                                                color = colors.textPrimary
                                            )
                                        }
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

// ============================================================
// Glass numpad button
// ============================================================

@Composable
private fun GlassNumpadButton(
    onClick: () -> Unit,
    content: @Composable () -> Unit
) {
    val colors = FinderTheme.colors

    Box(
        modifier = Modifier
            .size(72.dp)
            .clip(CircleShape)
            .background(colors.glassOverlay, CircleShape)
            .border(0.5.dp, colors.glassBorder, CircleShape)
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = ripple(bounded = true, radius = 36.dp),
                onClick = onClick
            ),
        contentAlignment = Alignment.Center
    ) {
        content()
    }
}
