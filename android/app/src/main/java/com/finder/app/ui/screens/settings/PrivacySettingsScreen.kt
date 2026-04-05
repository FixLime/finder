package com.finder.app.ui.screens.settings

import androidx.compose.animation.animateContentSize
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Fingerprint
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Screenshot
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.finder.app.services.ScreenshotExceptionsService
import com.finder.app.ui.theme.FinderTheme

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun PrivacySettingsScreen(
    onBack: () -> Unit
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current

    var allowScreenshots by remember { mutableStateOf(false) }
    var showOnlineStatus by remember { mutableStateOf(true) }
    var showLastSeen by remember { mutableStateOf(true) }
    var showReadReceipts by remember { mutableStateOf(true) }
    var hideTypingIndicator by remember { mutableStateOf(false) }
    var ghostMode by remember { mutableStateOf(false) }
    var phantomMessages by remember { mutableStateOf(false) }
    var antiForward by remember { mutableStateOf(false) }
    var ipMasking by remember { mutableStateOf(false) }
    var stealthKeyboard by remember { mutableStateOf(false) }

    var showExceptionsSheet by remember { mutableStateOf(false) }
    val exceptions by ScreenshotExceptionsService.exceptionUsernames.collectAsStateWithLifecycle()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .windowInsetsPadding(WindowInsets.statusBars)
    ) {
        // Header
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 8.dp)
        ) {
            IconButton(onClick = {
                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                onBack()
            }) {
                Icon(Icons.Filled.ArrowBack, "Назад", tint = colors.accentBlue)
            }
            Text(
                text = "Конфиденциальность",
                style = MaterialTheme.typography.headlineMedium,
                color = colors.textPrimary
            )
        }

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // Biometric section
            item {
                SectionLabel("Биометрия")
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(colors.glassCardBackground)
                        .border(0.5.dp, colors.glassBorder, RoundedCornerShape(16.dp))
                        .padding(16.dp)
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(
                            Icons.Filled.Fingerprint,
                            contentDescription = null,
                            tint = colors.accentPurple,
                            modifier = Modifier.size(28.dp)
                        )
                        Column {
                            Text(
                                "Улучшаем биометрию...",
                                style = MaterialTheme.typography.titleMedium,
                                color = colors.textPrimary
                            )
                            Text(
                                "Скоро будет доступно",
                                style = MaterialTheme.typography.bodySmall,
                                color = colors.textTertiary
                            )
                        }
                    }
                }
            }

            // Privacy toggles
            item {
                Spacer(Modifier.height(4.dp))
                SectionLabel("Конфиденциальность")
            }

            item {
                PrivacyToggleCard(
                    title = "Скриншоты",
                    subtitle = "Разрешить собеседникам делать скриншоты",
                    checked = allowScreenshots,
                    onCheckedChange = {
                        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                        allowScreenshots = it
                    }
                )
            }

            item {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(16.dp))
                        .background(colors.glassCardBackground)
                        .border(0.5.dp, colors.glassBorder, RoundedCornerShape(16.dp))
                        .clickable {
                            haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                            showExceptionsSheet = true
                        }
                        .padding(16.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        Icons.Filled.Screenshot,
                        contentDescription = null,
                        tint = colors.accentBlue,
                        modifier = Modifier.size(24.dp)
                    )
                    Spacer(Modifier.width(12.dp))
                    Text(
                        "Исключения для скриншотов",
                        style = MaterialTheme.typography.titleMedium,
                        color = colors.textPrimary,
                        modifier = Modifier.weight(1f)
                    )
                    if (exceptions.isNotEmpty()) {
                        Box(
                            modifier = Modifier
                                .size(24.dp)
                                .background(colors.accentBlue, CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                "${exceptions.size}",
                                color = androidx.compose.ui.graphics.Color.White,
                                style = MaterialTheme.typography.labelSmall,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }

            item {
                PrivacyToggleCard("Статус онлайн", "Показывать когда вы в сети", showOnlineStatus) {
                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    showOnlineStatus = it
                }
            }
            item {
                PrivacyToggleCard("Последний визит", "Показывать когда были в сети", showLastSeen) {
                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    showLastSeen = it
                }
            }
            item {
                PrivacyToggleCard("Отчёты о прочтении", "Показывать когда вы прочитали", showReadReceipts) {
                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    showReadReceipts = it
                }
            }
            item {
                PrivacyToggleCard("Индикатор набора", "Скрыть что вы печатаете", hideTypingIndicator) {
                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    hideTypingIndicator = it
                }
            }

            // Advanced
            item {
                Spacer(Modifier.height(4.dp))
                SectionLabel("Расширенные")
            }
            item {
                PrivacyToggleCard("Режим призрака", "Полная невидимость в сети", ghostMode) {
                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    ghostMode = it
                }
            }
            item {
                PrivacyToggleCard("Фантомные сообщения", "Сообщения исчезают после прочтения", phantomMessages) {
                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    phantomMessages = it
                }
            }
            item {
                PrivacyToggleCard("Запрет пересылки", "Запретить пересылку ваших сообщений", antiForward) {
                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    antiForward = it
                }
            }
            item {
                PrivacyToggleCard("Маскировка IP", "Скрыть ваш IP-адрес", ipMasking) {
                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    ipMasking = it
                }
            }
            item {
                PrivacyToggleCard("Скрытая клавиатура", "Не показывать что вы печатаете", stealthKeyboard) {
                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    stealthKeyboard = it
                }
            }

            item { Spacer(Modifier.height(32.dp)) }
        }
    }

    // Screenshot exceptions sheet
    if (showExceptionsSheet) {
        ModalBottomSheet(
            onDismissRequest = { showExceptionsSheet = false },
            sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true),
            containerColor = MaterialTheme.colorScheme.surface
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(16.dp)
            ) {
                Text(
                    "Исключения для скриншотов",
                    style = MaterialTheme.typography.headlineMedium,
                    color = colors.textPrimary
                )
                Spacer(Modifier.height(4.dp))
                Text(
                    "Эти пользователи могут делать скриншоты",
                    style = MaterialTheme.typography.bodyMedium,
                    color = colors.textSecondary
                )
                Spacer(Modifier.height(16.dp))

                if (exceptions.isEmpty()) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(32.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            "Нет исключений",
                            style = MaterialTheme.typography.bodyLarge,
                            color = colors.textTertiary
                        )
                    }
                } else {
                    exceptions.forEach { username ->
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(12.dp))
                                .background(colors.glassCardBackground)
                                .border(0.5.dp, colors.glassBorder, RoundedCornerShape(12.dp))
                                .padding(12.dp)
                        ) {
                            Icon(
                                Icons.Filled.Person,
                                contentDescription = null,
                                tint = colors.accentBlue,
                                modifier = Modifier.size(24.dp)
                            )
                            Spacer(Modifier.width(12.dp))
                            Text(
                                username,
                                style = MaterialTheme.typography.titleMedium,
                                color = colors.textPrimary,
                                modifier = Modifier.weight(1f)
                            )
                            IconButton(
                                onClick = {
                                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                    ScreenshotExceptionsService.removeException(username)
                                },
                                modifier = Modifier.size(32.dp)
                            ) {
                                Icon(
                                    Icons.Filled.Close,
                                    contentDescription = "Удалить",
                                    tint = colors.errorRed,
                                    modifier = Modifier.size(18.dp)
                                )
                            }
                        }
                        Spacer(Modifier.height(8.dp))
                    }
                }
                Spacer(Modifier.height(16.dp))
            }
        }
    }
}

@Composable
private fun SectionLabel(text: String) {
    Text(
        text = text.uppercase(),
        style = MaterialTheme.typography.labelMedium,
        color = FinderTheme.colors.textTertiary,
        fontWeight = FontWeight.SemiBold,
        modifier = Modifier.padding(vertical = 4.dp)
    )
}

@Composable
private fun PrivacyToggleCard(
    title: String,
    subtitle: String,
    checked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    val colors = FinderTheme.colors

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(colors.glassCardBackground)
            .border(0.5.dp, colors.glassBorder, RoundedCornerShape(16.dp))
            .padding(horizontal = 16.dp, vertical = 12.dp)
            .animateContentSize()
    ) {
        Column(modifier = Modifier.weight(1f)) {
            Text(
                title,
                style = MaterialTheme.typography.titleMedium,
                color = colors.textPrimary
            )
            Text(
                subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = colors.textTertiary
            )
        }
        Spacer(Modifier.width(12.dp))
        Switch(
            checked = checked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = androidx.compose.ui.graphics.Color.White,
                checkedTrackColor = colors.accentBlue,
                uncheckedThumbColor = colors.textTertiary,
                uncheckedTrackColor = colors.glassCardBackground
            )
        )
    }
}
