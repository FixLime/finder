package com.finder.app.ui.screens.auth

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInHorizontally
import androidx.compose.animation.slideOutHorizontally
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AlternateEmail
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Snackbar
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.finder.app.services.AuthService
import com.finder.app.ui.screens.onboarding.GlassActionButton
import com.finder.app.ui.screens.onboarding.localized
import com.finder.app.ui.theme.FinderTheme

/**
 * Multi-step Finder ID setup screen (5 steps):
 *   1. Username entry
 *   2. Display name entry
 *   3. Finder ID reveal (FID-XXXXXXXX) with copy
 *   4. PIN setup (embeds PinCodeScreen in setup mode)
 *   5. Biometric setup (optional, with skip)
 */
@Composable
fun FinderIDSetupScreen(
    isRussian: Boolean = true,
    onSetupComplete: () -> Unit
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current
    val context = LocalContext.current

    var currentStep by remember { mutableIntStateOf(1) }
    var username by remember { mutableStateOf("") }
    var displayName by remember { mutableStateOf("") }
    var generatedFinderID by remember { mutableStateOf("") }
    var showError by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf("") }

    // Progress fraction
    val progress by animateFloatAsState(
        targetValue = currentStep / 5f,
        animationSpec = spring(dampingRatio = 0.7f, stiffness = 300f),
        label = "progress"
    )

    fun goBack() {
        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
        if (currentStep > 1) currentStep--
    }

    fun validateAndAdvanceUsername() {
        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
        val trimmed = username.trim().lowercase()
        when {
            trimmed.length < 3 -> {
                errorMessage = localized(isRussian, "Минимум 3 символа", "Minimum 3 characters")
                showError = true
            }
            trimmed.length > 30 -> {
                errorMessage = localized(isRussian, "Максимум 30 символов", "Maximum 30 characters")
                showError = true
            }
            trimmed.contains(" ") -> {
                errorMessage = localized(isRussian, "Пробелы запрещены", "Spaces not allowed")
                showError = true
            }
            !trimmed.all { it.isLetterOrDigit() || it == '_' } -> {
                errorMessage = localized(isRussian, "Только буквы, цифры и _", "Only letters, digits and _")
                showError = true
            }
            else -> {
                username = trimmed
                showError = false
                currentStep = 2
            }
        }
    }

    fun advanceDisplayName() {
        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
        if (displayName.trim().length < 2) {
            errorMessage = localized(isRussian, "Минимум 2 символа", "Minimum 2 characters")
            showError = true
            return
        }
        showError = false
        // Check if username is admin restore code
        AuthService.login(username, displayName.trim())
        generatedFinderID = AuthService.currentFinderID.value
        currentStep = 3
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        Column(modifier = Modifier.fillMaxSize()) {

            // --- Top bar: back + progress + step counter ---
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (currentStep > 1) {
                    Box(
                        modifier = Modifier
                            .size(40.dp)
                            .clip(RoundedCornerShape(12.dp))
                            .background(colors.glassCardBackground)
                            .border(0.5.dp, colors.glassBorder, RoundedCornerShape(12.dp))
                            .clickable { goBack() },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                            contentDescription = localized(isRussian, "Назад", "Back"),
                            tint = colors.textPrimary,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                } else {
                    Spacer(modifier = Modifier.size(40.dp))
                }

                Spacer(modifier = Modifier.width(12.dp))

                LinearProgressIndicator(
                    progress = { progress },
                    modifier = Modifier
                        .weight(1f)
                        .height(4.dp)
                        .clip(RoundedCornerShape(2.dp)),
                    color = colors.accentBlue,
                    trackColor = colors.glassCardBackground,
                )

                Spacer(modifier = Modifier.width(12.dp))

                Text(
                    text = "$currentStep/5",
                    color = colors.textSecondary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium
                )
            }

            // --- Animated step content ---
            AnimatedContent(
                targetState = currentStep,
                transitionSpec = {
                    (slideInHorizontally { it } + fadeIn()) togetherWith
                            (slideOutHorizontally { -it } + fadeOut())
                },
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                label = "stepContent"
            ) { step ->
                when (step) {
                    1 -> StepUsername(
                        username = username,
                        onUsernameChange = {
                            username = it.filter { c -> !c.isWhitespace() }
                            showError = false
                        },
                        isRussian = isRussian,
                        onNext = { validateAndAdvanceUsername() }
                    )
                    2 -> StepDisplayName(
                        displayName = displayName,
                        onDisplayNameChange = {
                            displayName = it
                            showError = false
                        },
                        isRussian = isRussian,
                        onNext = { advanceDisplayName() }
                    )
                    3 -> StepFinderIDReveal(
                        finderID = generatedFinderID,
                        isRussian = isRussian,
                        context = context,
                        onNext = {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                            currentStep = 4
                        }
                    )
                    4 -> PinCodeScreen(
                        isSetup = true,
                        isRussian = isRussian,
                        onPinCreated = { pin ->
                            AuthService.setupPIN(pin)
                            currentStep = 5
                        }
                    )
                    5 -> StepBiometric(
                        isRussian = isRussian,
                        onSetup = {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                            AuthService.setBiometricBindingEnabled(true)
                            AuthService.completeOnboarding()
                            onSetupComplete()
                        },
                        onSkip = {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                            AuthService.completeOnboarding()
                            onSetupComplete()
                        }
                    )
                }
            }
        }

        // Error snackbar
        if (showError) {
            Snackbar(
                modifier = Modifier
                    .align(Alignment.BottomCenter)
                    .padding(16.dp),
                action = {
                    TextButton(onClick = { showError = false }) {
                        Text("OK", color = Color.White)
                    }
                },
                containerColor = colors.errorRed
            ) {
                Text(errorMessage, color = Color.White)
            }
        }
    }
}

// ============================================================
// Step 1 -- Username
// ============================================================

@Composable
private fun StepUsername(
    username: String,
    onUsernameChange: (String) -> Unit,
    isRussian: Boolean,
    onNext: () -> Unit
) {
    val colors = FinderTheme.colors

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Box(
            modifier = Modifier
                .size(80.dp)
                .clip(CircleShape)
                .background(colors.accentBlue.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Filled.AlternateEmail,
                contentDescription = null,
                tint = colors.accentBlue,
                modifier = Modifier.size(36.dp)
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            text = localized(isRussian, "Создайте имя пользователя", "Create your username"),
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            color = colors.textPrimary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = localized(
                isRussian,
                "Это ваш уникальный идентификатор в Finder.\nБез номера телефона, без почты.",
                "This is your unique Finder identifier.\nNo phone number, no email."
            ),
            fontSize = 14.sp,
            color = colors.textSecondary,
            textAlign = TextAlign.Center,
            lineHeight = 20.sp
        )

        Spacer(modifier = Modifier.height(24.dp))

        OutlinedTextField(
            value = username,
            onValueChange = onUsernameChange,
            label = {
                Text(localized(isRussian, "Имя пользователя", "Username"), color = colors.textSecondary)
            },
            singleLine = true,
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Ascii,
                imeAction = ImeAction.Next
            ),
            keyboardActions = KeyboardActions(onNext = { onNext() }),
            colors = OutlinedTextFieldDefaults.colors(
                focusedContainerColor = colors.glassTextFieldBackground,
                unfocusedContainerColor = colors.glassTextFieldBackground,
                focusedBorderColor = colors.accentBlue,
                unfocusedBorderColor = colors.glassBorder,
                focusedTextColor = colors.textPrimary,
                unfocusedTextColor = colors.textPrimary,
                cursorColor = colors.accentBlue
            ),
            shape = RoundedCornerShape(14.dp),
            modifier = Modifier.fillMaxWidth(),
            supportingText = {
                Text(
                    localized(isRussian, "3-30 символов, без пробелов", "3-30 characters, no spaces"),
                    color = colors.textSecondary.copy(alpha = 0.6f),
                    fontSize = 12.sp
                )
            }
        )

        Spacer(modifier = Modifier.height(24.dp))

        GlassActionButton(
            text = localized(isRussian, "Далее", "Next"),
            onClick = onNext,
            enabled = username.length >= 3
        )
    }
}

// ============================================================
// Step 2 -- Display Name
// ============================================================

@Composable
private fun StepDisplayName(
    displayName: String,
    onDisplayNameChange: (String) -> Unit,
    isRussian: Boolean,
    onNext: () -> Unit
) {
    val colors = FinderTheme.colors

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Box(
            modifier = Modifier
                .size(80.dp)
                .clip(CircleShape)
                .background(colors.accentPurple.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Filled.Person,
                contentDescription = null,
                tint = colors.accentPurple,
                modifier = Modifier.size(36.dp)
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            text = localized(isRussian, "Как вас зовут?", "What's your name?"),
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            color = colors.textPrimary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = localized(
                isRussian,
                "Это имя увидят другие пользователи",
                "This name will be visible to others"
            ),
            fontSize = 14.sp,
            color = colors.textSecondary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(24.dp))

        OutlinedTextField(
            value = displayName,
            onValueChange = onDisplayNameChange,
            label = {
                Text(localized(isRussian, "Отображаемое имя", "Display name"), color = colors.textSecondary)
            },
            singleLine = true,
            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done),
            keyboardActions = KeyboardActions(onDone = { onNext() }),
            colors = OutlinedTextFieldDefaults.colors(
                focusedContainerColor = colors.glassTextFieldBackground,
                unfocusedContainerColor = colors.glassTextFieldBackground,
                focusedBorderColor = colors.accentPurple,
                unfocusedBorderColor = colors.glassBorder,
                focusedTextColor = colors.textPrimary,
                unfocusedTextColor = colors.textPrimary,
                cursorColor = colors.accentPurple
            ),
            shape = RoundedCornerShape(14.dp),
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(24.dp))

        GlassActionButton(
            text = localized(isRussian, "Далее", "Next"),
            onClick = onNext,
            enabled = displayName.trim().length >= 2
        )
    }
}

// ============================================================
// Step 3 -- Finder ID Reveal
// ============================================================

@Composable
private fun StepFinderIDReveal(
    finderID: String,
    isRussian: Boolean,
    context: Context,
    onNext: () -> Unit
) {
    val colors = FinderTheme.colors
    var copied by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Box(
            modifier = Modifier
                .size(100.dp)
                .clip(CircleShape)
                .background(colors.accentCyan.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Filled.Fingerprint,
                contentDescription = null,
                tint = colors.accentCyan,
                modifier = Modifier.size(52.dp)
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            text = localized(isRussian, "Ваш FinderID", "Your FinderID"),
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            color = colors.textPrimary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Finder ID card with copy button
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(colors.glassCardBackground)
                .border(0.5.dp, colors.glassBorder, RoundedCornerShape(16.dp))
                .padding(16.dp),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = finderID,
                fontSize = 22.sp,
                fontWeight = FontWeight.Bold,
                fontFamily = FontFamily.Monospace,
                color = colors.accentCyan,
                modifier = Modifier.weight(1f),
                textAlign = TextAlign.Center
            )

            IconButton(onClick = {
                val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                clipboard.setPrimaryClip(ClipData.newPlainText("FinderID", finderID))
                copied = true
            }) {
                Icon(
                    imageVector = if (copied) Icons.Filled.Check else Icons.Filled.ContentCopy,
                    contentDescription = localized(isRussian, "Копировать", "Copy"),
                    tint = if (copied) colors.onlineGreen else colors.textSecondary,
                    modifier = Modifier.size(22.dp)
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = localized(
                isRussian,
                "Запомните ваш FinderID.\nОн понадобится для входа в аккаунт.",
                "Remember your FinderID.\nYou'll need it to log in."
            ),
            fontSize = 14.sp,
            color = colors.textSecondary,
            textAlign = TextAlign.Center,
            lineHeight = 20.sp
        )

        Spacer(modifier = Modifier.height(24.dp))

        GlassActionButton(
            text = localized(isRussian, "Продолжить", "Continue"),
            onClick = onNext
        )
    }
}

// ============================================================
// Step 5 -- Biometric (optional)
// ============================================================

@Composable
private fun StepBiometric(
    isRussian: Boolean,
    onSetup: () -> Unit,
    onSkip: () -> Unit
) {
    val colors = FinderTheme.colors

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Box(
            modifier = Modifier
                .size(80.dp)
                .clip(CircleShape)
                .background(colors.onlineGreen.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Filled.Fingerprint,
                contentDescription = null,
                tint = colors.onlineGreen,
                modifier = Modifier.size(36.dp)
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            text = localized(isRussian, "Настроить биометрию?", "Set up biometrics?"),
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            color = colors.textPrimary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = localized(
                isRussian,
                "Быстрый и безопасный вход\nс помощью биометрии",
                "Quick and secure login\nusing biometrics"
            ),
            fontSize = 14.sp,
            color = colors.textSecondary,
            textAlign = TextAlign.Center,
            lineHeight = 20.sp
        )

        Spacer(modifier = Modifier.height(32.dp))

        GlassActionButton(
            text = localized(isRussian, "Настроить", "Set Up"),
            onClick = onSetup
        )

        Spacer(modifier = Modifier.height(12.dp))

        TextButton(onClick = onSkip) {
            Text(
                text = localized(isRussian, "Пропустить", "Skip"),
                color = colors.textSecondary,
                fontSize = 14.sp
            )
        }
    }
}
