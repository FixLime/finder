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
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.AlternateEmail
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ContentCopy
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Person
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Snackbar
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
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
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.finder.app.services.AuthService
import com.finder.app.ui.screens.onboarding.GlassActionButton
import com.finder.app.ui.screens.onboarding.localized
import com.finder.app.ui.theme.FinderTheme

@OptIn(ExperimentalMaterial3Api::class)
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
    var password by remember { mutableStateOf("") }
    var displayName by remember { mutableStateOf("") }
    var generatedFinderID by remember { mutableStateOf("") }
    var showError by remember { mutableStateOf(false) }
    var errorMessage by remember { mutableStateOf("") }
    var showLegalSheet by remember { mutableStateOf(false) }
    var legalSheetType by remember { mutableStateOf("terms") } // "terms" or "privacy"
    var isLoginMode by remember { mutableStateOf(false) }

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
                return
            }
            trimmed.length > 30 -> {
                errorMessage = localized(isRussian, "Максимум 30 символов", "Maximum 30 characters")
                showError = true
                return
            }
            trimmed.contains(" ") -> {
                errorMessage = localized(isRussian, "Пробелы запрещены", "Spaces not allowed")
                showError = true
                return
            }
            !trimmed.all { it.isLetterOrDigit() || it == '_' } -> {
                errorMessage = localized(isRussian, "Только буквы, цифры и _", "Only letters, digits and _")
                showError = true
                return
            }
            password.length < 4 -> {
                errorMessage = localized(isRussian, "Пароль минимум 4 символа", "Password minimum 4 characters")
                showError = true
                return
            }
        }
        username = trimmed

        // Check if username already registered
        if (AuthService.isUsernameRegistered(trimmed)) {
            if (!isLoginMode) {
                isLoginMode = true
                return
            }
            // Login mode — verify password
            if (AuthService.loginWithPassword(trimmed, password)) {
                showError = false
                AuthService.login(trimmed, AuthService.currentDisplayName.value.ifEmpty { trimmed })
                AuthService.completeOnboarding()
                onSetupComplete()
            } else {
                errorMessage = localized(isRussian, "Неверный пароль", "Wrong password")
                showError = true
                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
            }
            return
        }

        // New registration — proceed to display name
        showError = false
        currentStep = 2
    }

    fun advanceDisplayName() {
        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
        if (displayName.trim().length < 2) {
            errorMessage = localized(isRussian, "Минимум 2 символа", "Minimum 2 characters")
            showError = true
            return
        }
        showError = false
        AuthService.registerWithPassword(username, displayName.trim(), password)
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
                            if (isLoginMode) {
                                isLoginMode = false
                                password = ""
                            }
                        },
                        password = password,
                        onPasswordChange = {
                            password = it
                            showError = false
                        },
                        isLoginMode = isLoginMode,
                        isRussian = isRussian,
                        onNext = { validateAndAdvanceUsername() },
                        onOpenTerms = {
                            legalSheetType = "terms"
                            showLegalSheet = true
                        },
                        onOpenPrivacy = {
                            legalSheetType = "privacy"
                            showLegalSheet = true
                        }
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

    // Legal bottom sheet
    if (showLegalSheet) {
        ModalBottomSheet(
            onDismissRequest = { showLegalSheet = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = MaterialTheme.colorScheme.surface
        ) {
            LegalContent(
                type = legalSheetType,
                isRussian = isRussian,
                onDismiss = { showLegalSheet = false }
            )
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
    password: String,
    onPasswordChange: (String) -> Unit,
    isLoginMode: Boolean,
    isRussian: Boolean,
    onNext: () -> Unit,
    onOpenTerms: () -> Unit = {},
    onOpenPrivacy: () -> Unit = {}
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
                imageVector = if (isLoginMode) Icons.Filled.Person else Icons.Filled.AlternateEmail,
                contentDescription = null,
                tint = colors.accentBlue,
                modifier = Modifier.size(36.dp)
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            text = if (isLoginMode)
                localized(isRussian, "Вход в аккаунт", "Sign in to account")
            else
                localized(isRussian, "Создайте имя пользователя", "Create your username"),
            fontSize = 22.sp,
            fontWeight = FontWeight.Bold,
            color = colors.textPrimary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = if (isLoginMode)
                localized(isRussian,
                    "Это имя уже занято. Введите пароль для входа.",
                    "This username is taken. Enter password to sign in.")
            else
                localized(isRussian,
                    "Это ваш уникальный идентификатор в Finder.\nБез номера телефона, без почты.",
                    "This is your unique Finder identifier.\nNo phone number, no email."),
            fontSize = 14.sp,
            color = if (isLoginMode) colors.warningOrange else colors.textSecondary,
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
            modifier = Modifier.fillMaxWidth()
        )

        Spacer(modifier = Modifier.height(12.dp))

        OutlinedTextField(
            value = password,
            onValueChange = onPasswordChange,
            label = {
                Text(localized(isRussian, "Пароль", "Password"), color = colors.textSecondary)
            },
            singleLine = true,
            visualTransformation = PasswordVisualTransformation(),
            keyboardOptions = KeyboardOptions(
                keyboardType = KeyboardType.Password,
                imeAction = ImeAction.Done
            ),
            keyboardActions = KeyboardActions(onDone = { onNext() }),
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
                    localized(isRussian, "Минимум 4 символа", "Minimum 4 characters"),
                    color = colors.textSecondary.copy(alpha = 0.6f),
                    fontSize = 12.sp
                )
            }
        )

        Spacer(modifier = Modifier.height(24.dp))

        GlassActionButton(
            text = if (isLoginMode) localized(isRussian, "Войти", "Sign In")
                   else localized(isRussian, "Далее", "Next"),
            onClick = onNext,
            enabled = username.length >= 3 && password.length >= 4
        )

        Spacer(modifier = Modifier.height(16.dp))

        // Terms & Privacy notice
        Column(horizontalAlignment = Alignment.CenterHorizontally) {
            Text(
                text = localized(
                    isRussian,
                    "Регистрируясь, вы соглашаетесь с",
                    "By registering, you agree to the"
                ),
                fontSize = 12.sp,
                color = colors.textTertiary,
                textAlign = TextAlign.Center
            )
            Row(
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = localized(isRussian, "Условиями использования", "Terms of Service"),
                    fontSize = 12.sp,
                    color = colors.accentBlue,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.clickable { onOpenTerms() }
                )
                Text(
                    text = localized(isRussian, " и ", " and "),
                    fontSize = 12.sp,
                    color = colors.textTertiary
                )
                Text(
                    text = localized(isRussian, "Политикой конфиденциальности", "Privacy Policy"),
                    fontSize = 12.sp,
                    color = colors.accentBlue,
                    fontWeight = FontWeight.Medium,
                    modifier = Modifier.clickable { onOpenPrivacy() }
                )
            }
        }
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

// ============================================================
// Legal content (Terms of Service & Privacy Policy)
// ============================================================

@Composable
private fun LegalContent(
    type: String,
    isRussian: Boolean,
    onDismiss: () -> Unit
) {
    val colors = FinderTheme.colors
    val scrollState = rememberScrollState()

    val title = if (type == "terms") {
        localized(isRussian, "Условия использования", "Terms of Service")
    } else {
        localized(isRussian, "Политика конфиденциальности", "Privacy Policy")
    }

    val content = if (type == "terms") {
        if (isRussian) TERMS_OF_SERVICE_RU else TERMS_OF_SERVICE_EN
    } else {
        if (isRussian) PRIVACY_POLICY_RU else PRIVACY_POLICY_EN
    }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
            .windowInsetsPadding(WindowInsets.navigationBars)
    ) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Text(
                text = title,
                style = MaterialTheme.typography.headlineMedium,
                color = colors.textPrimary,
                fontWeight = FontWeight.Bold
            )
            TextButton(onClick = onDismiss) {
                Text(
                    localized(isRussian, "Закрыть", "Close"),
                    color = colors.accentBlue
                )
            }
        }

        Spacer(modifier = Modifier.height(4.dp))

        Text(
            text = localized(isRussian, "Последнее обновление: 5 апреля 2026", "Last updated: April 5, 2026"),
            fontSize = 12.sp,
            color = colors.textTertiary
        )

        Spacer(modifier = Modifier.height(12.dp))

        // Scrollable legal text
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .weight(1f, fill = false)
                .verticalScroll(scrollState)
                .clip(RoundedCornerShape(16.dp))
                .background(colors.glassCardBackground)
                .border(0.5.dp, colors.glassBorder, RoundedCornerShape(16.dp))
                .padding(16.dp)
        ) {
            Text(
                text = content,
                fontSize = 14.sp,
                color = colors.textSecondary,
                lineHeight = 22.sp
            )
        }

        Spacer(modifier = Modifier.height(16.dp))
    }
}

// ============================================================
// Legal text constants
// ============================================================

private const val TERMS_OF_SERVICE_RU = """Условия использования Finder

1. Общие положения

1.1. Настоящие Условия использования (далее — «Условия») регулируют отношения между пользователем (далее — «Пользователь») и разработчиками мессенджера Finder (далее — «Finder», «мы», «нас»).

1.2. Используя приложение Finder, Пользователь подтверждает, что ознакомился с настоящими Условиями и принимает их в полном объёме.

1.3. Finder — мессенджер, ориентированный на конфиденциальность и безопасность общения.

2. Регистрация и аккаунт

2.1. Для использования Finder необходимо создать аккаунт с уникальным именем пользователя и PIN-кодом.

2.2. Finder не требует номер телефона, адрес электронной почты или иные персональные данные для регистрации.

2.3. Пользователь несёт полную ответственность за сохранность своего FinderID и PIN-кода. В случае утраты доступа восстановление может быть невозможно.

2.4. Один пользователь может иметь только один активный аккаунт.

3. Правила поведения

3.1. Пользователь обязуется не использовать Finder для:
• распространения незаконного контента;
• угроз, оскорблений и травли других пользователей;
• мошенничества и обмана;
• распространения спама и нежелательной рекламы;
• распространения вредоносного программного обеспечения;
• нарушения прав третьих лиц.

3.2. Нарушение правил может привести к временной или постоянной блокировке аккаунта.

4. Контент и сообщения

4.1. Пользователь несёт ответственность за содержание своих сообщений.

4.2. Сообщения передаются с использованием сквозного шифрования. Мы не имеем технической возможности читать содержимое переписок.

4.3. Функции самоуничтожения сообщений и «Протокол Fenix» удаляют данные безвозвратно.

5. Система рейтинга

5.1. Finder использует систему рейтинга для поощрения активных пользователей.

5.2. Некоторые функции доступны только пользователям определённого уровня рейтинга.

5.3. Мы оставляем за собой право изменять требования к рейтингу.

6. Ограничение ответственности

6.1. Finder предоставляется «как есть». Мы не гарантируем бесперебойную работу сервиса.

6.2. Мы не несём ответственности за утрату данных, связанную с использованием функций самоуничтожения.

6.3. Мы не несём ответственности за действия пользователей и контент, который они передают через Finder.

7. Изменения условий

7.1. Мы оставляем за собой право изменять настоящие Условия в любое время.

7.2. Продолжение использования Finder после изменения Условий означает согласие с новой редакцией.

8. Прекращение использования

8.1. Пользователь может в любой момент удалить свой аккаунт, в том числе с помощью «Протокола Fenix».

8.2. Мы оставляем за собой право заблокировать или удалить аккаунт пользователя при нарушении Условий."""

private const val TERMS_OF_SERVICE_EN = """Finder Terms of Service

1. General Provisions

1.1. These Terms of Service (hereinafter — "Terms") govern the relationship between the user (hereinafter — "User") and the developers of the Finder messenger (hereinafter — "Finder," "we," "us").

1.2. By using Finder, the User confirms that they have read and fully accept these Terms.

1.3. Finder is a messenger focused on privacy and secure communication.

2. Registration and Account

2.1. To use Finder, you must create an account with a unique username and PIN code.

2.2. Finder does not require a phone number, email address, or other personal data for registration.

2.3. The User is fully responsible for the security of their FinderID and PIN code. Recovery may not be possible if access is lost.

2.4. Each user may have only one active account.

3. Code of Conduct

3.1. Users agree not to use Finder for:
• distributing illegal content;
• threats, insults, and harassment of other users;
• fraud and deception;
• distributing spam and unwanted advertising;
• distributing malicious software;
• violating the rights of third parties.

3.2. Violations may result in temporary or permanent account suspension.

4. Content and Messages

4.1. Users are responsible for the content of their messages.

4.2. Messages are transmitted using end-to-end encryption. We have no technical ability to read the content of conversations.

4.3. Self-destructing message features and "Fenix Protocol" permanently delete data.

5. Rating System

5.1. Finder uses a rating system to reward active users.

5.2. Some features are only available to users with a certain rating level.

5.3. We reserve the right to modify rating requirements.

6. Limitation of Liability

6.1. Finder is provided "as is." We do not guarantee uninterrupted service.

6.2. We are not responsible for data loss related to the use of self-destruct features.

6.3. We are not responsible for user actions or content transmitted through Finder.

7. Changes to Terms

7.1. We reserve the right to modify these Terms at any time.

7.2. Continued use of Finder after changes to the Terms constitutes acceptance of the new version.

8. Termination

8.1. Users may delete their account at any time, including through "Fenix Protocol."

8.2. We reserve the right to suspend or delete a user's account for violations of these Terms."""

private const val PRIVACY_POLICY_RU = """Политика конфиденциальности Finder

1. Введение

Мы в Finder уважаем вашу конфиденциальность и стремимся защитить ваши персональные данные. Настоящая Политика конфиденциальности описывает, как мы собираем, используем и защищаем вашу информацию.

2. Какие данные мы собираем

2.1. Данные при регистрации:
• имя пользователя (username);
• отображаемое имя;
• FinderID (генерируется автоматически).

2.2. Мы НЕ собираем:
• номер телефона;
• адрес электронной почты;
• геолокацию;
• контакты из телефонной книги;
• фотографии из галереи (без явного разрешения).

3. Шифрование и безопасность

3.1. Все сообщения в Finder защищены сквозным шифрованием (end-to-end encryption).

3.2. Мы не имеем технической возможности прочитать содержимое ваших сообщений.

3.3. PIN-коды хранятся в хешированном виде и не могут быть восстановлены нами.

3.4. Биометрические данные обрабатываются исключительно на вашем устройстве и никогда не передаются на наши серверы.

4. Хранение данных

4.1. Ваши сообщения и заметки хранятся локально на вашем устройстве.

4.2. Минимальные метаданные (имя пользователя, FinderID, настройки) могут храниться на сервере для обеспечения работы сервиса.

4.3. Функция «Протокол Fenix» удаляет все ваши данные безвозвратно — как с устройства, так и с серверов.

5. Функции конфиденциальности

5.1. Режим призрака — полная невидимость вашей активности.

5.2. Фантомные сообщения — автоматическое удаление сообщений после прочтения.

5.3. Защита от скриншотов — предотвращение захвата экрана собеседником.

5.4. Маскировка IP — скрытие вашего IP-адреса.

5.5. Запрет пересылки — запрет на пересылку ваших сообщений.

5.6. Decoy PIN — ввод специального PIN-кода показывает пустой аккаунт.

6. Передача данных третьим лицам

6.1. Мы не продаём, не передаём и не предоставляем ваши данные третьим лицам.

6.2. Мы не используем рекламные трекеры и аналитические системы третьих сторон.

6.3. Мы можем раскрыть информацию только по требованию закона, если это технически возможно с учётом сквозного шифрования.

7. Права пользователя

7.1. Вы имеете право:
• удалить свой аккаунт в любой момент;
• активировать «Протокол Fenix» для полного удаления данных;
• управлять настройками конфиденциальности;
• запросить информацию о хранимых данных.

8. Изменения политики

8.1. Мы можем обновлять настоящую Политику. Существенные изменения будут доведены до сведения пользователей через приложение.

9. Контакты

По вопросам конфиденциальности обращайтесь через чат поддержки Finder Support в приложении."""

private const val PRIVACY_POLICY_EN = """Finder Privacy Policy

1. Introduction

At Finder, we respect your privacy and are committed to protecting your personal data. This Privacy Policy describes how we collect, use, and protect your information.

2. Data We Collect

2.1. Registration data:
• username;
• display name;
• FinderID (automatically generated).

2.2. We do NOT collect:
• phone numbers;
• email addresses;
• geolocation;
• contacts from your phone book;
• photos from your gallery (without explicit permission).

3. Encryption and Security

3.1. All messages in Finder are protected by end-to-end encryption.

3.2. We have no technical ability to read the content of your messages.

3.3. PIN codes are stored in hashed form and cannot be recovered by us.

3.4. Biometric data is processed exclusively on your device and is never transmitted to our servers.

4. Data Storage

4.1. Your messages and notes are stored locally on your device.

4.2. Minimal metadata (username, FinderID, settings) may be stored on our server to ensure service operation.

4.3. The "Fenix Protocol" feature permanently deletes all your data — both from your device and from our servers.

5. Privacy Features

5.1. Ghost Mode — complete invisibility of your activity.

5.2. Phantom Messages — automatic deletion of messages after reading.

5.3. Screenshot Protection — preventing screen capture by the other party.

5.4. IP Masking — hiding your IP address.

5.5. Anti-Forward — preventing forwarding of your messages.

5.6. Decoy PIN — entering a special PIN code shows an empty account.

6. Third-Party Data Sharing

6.1. We do not sell, transfer, or provide your data to third parties.

6.2. We do not use advertising trackers or third-party analytics systems.

6.3. We may disclose information only as required by law, if technically possible given end-to-end encryption.

7. User Rights

7.1. You have the right to:
• delete your account at any time;
• activate "Fenix Protocol" for complete data deletion;
• manage your privacy settings;
• request information about stored data.

8. Policy Changes

8.1. We may update this Policy. Significant changes will be communicated to users through the application.

9. Contact

For privacy-related questions, please contact us through the Finder Support chat in the application."""
