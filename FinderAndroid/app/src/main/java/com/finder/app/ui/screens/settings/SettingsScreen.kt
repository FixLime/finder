package com.finder.app.ui.screens.settings

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.filled.AdminPanelSettings
import androidx.compose.material.icons.filled.DarkMode
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Language
import androidx.compose.material.icons.filled.LightMode
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.finder.app.services.AuthService
import com.finder.app.services.HapticService
import com.finder.app.services.LocalizationService
import com.finder.app.services.RatingService
import com.finder.app.services.ThemeService
import com.finder.app.ui.theme.FinderTheme
import com.finder.app.ui.theme.glassCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBack: () -> Unit = {},
    onNavigateToPrivacy: () -> Unit = {},
    onNavigateToAccount: () -> Unit = {},
    onNavigateToAdmin: () -> Unit = {}
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current
    val isRussian by LocalizationService.isRussian.collectAsState()
    val isDarkMode by ThemeService.isDarkMode.collectAsState()
    val displayName by AuthService.currentDisplayName.collectAsState()
    val username by AuthService.currentUsername.collectAsState()
    val finderId by AuthService.currentFinderID.collectAsState()
    val ratingPoints by RatingService.points.collectAsState()
    val ratingTier by RatingService.tier.collectAsState()

    var appear by remember { mutableStateOf(false) }
    var showLogoutDialog by remember { mutableStateOf(false) }
    var showFenixDialog by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) { appear = true }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        // Top bar with back button and title
        TopAppBar(
            title = {
                Text(
                    text = LocalizationService.localized("Настройки", "Settings"),
                    style = MaterialTheme.typography.titleLarge
                )
            },
            navigationIcon = {
                IconButton(onClick = {
                    HapticService.lightTap(haptic)
                    onBack()
                }) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                        contentDescription = LocalizationService.back
                    )
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = Color.Transparent
            )
        )

        LazyColumn(
            contentPadding = PaddingValues(bottom = 120.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // Profile card
            item {
                AnimatedVisibility(
                    visible = appear,
                    enter = fadeIn() + slideInVertically(
                        initialOffsetY = { 60 },
                        animationSpec = spring(stiffness = Spring.StiffnessLow)
                    )
                ) {
                    ProfileCard(
                        displayName = displayName,
                        username = username,
                        finderId = finderId
                    )
                }
            }

            // Внешний вид section
            item {
                AnimatedVisibility(
                    visible = appear,
                    enter = fadeIn() + slideInVertically(
                        initialOffsetY = { 80 },
                        animationSpec = spring(stiffness = Spring.StiffnessLow, dampingRatio = 0.8f)
                    )
                ) {
                    SettingsSection(
                        title = LocalizationService.appearance
                    ) {
                        // Dark mode toggle
                        SettingsToggleRow(
                            icon = if (isDarkMode) Icons.Filled.DarkMode else Icons.Filled.LightMode,
                            iconTint = Color(0xFF5C6BC0),
                            title = LocalizationService.darkMode,
                            isChecked = isDarkMode,
                            onCheckedChange = {
                                HapticService.lightTap(haptic)
                                ThemeService.toggleDarkMode()
                            }
                        )
                        HorizontalDivider(modifier = Modifier.padding(start = 56.dp))
                        // Language toggle
                        SettingsValueRow(
                            icon = Icons.Filled.Language,
                            iconTint = colors.accentBlue,
                            title = LocalizationService.language,
                            value = if (isRussian) "RU" else "EN",
                            onClick = {
                                HapticService.lightTap(haptic)
                                LocalizationService.toggleLanguage()
                            }
                        )
                    }
                }
            }

            // Account & Privacy navigation section
            item {
                AnimatedVisibility(
                    visible = appear,
                    enter = fadeIn() + slideInVertically(
                        initialOffsetY = { 100 },
                        animationSpec = spring(stiffness = Spring.StiffnessLow, dampingRatio = 0.8f)
                    )
                ) {
                    SettingsSection(
                        title = LocalizationService.localized("Аккаунт и безопасность", "Account & Security")
                    ) {
                        // Конфиденциальность
                        SettingsNavigationRow(
                            icon = Icons.Filled.Shield,
                            iconTint = Color(0xFF4CAF50),
                            title = LocalizationService.privacy,
                            onClick = {
                                HapticService.lightTap(haptic)
                                onNavigateToPrivacy()
                            }
                        )
                        HorizontalDivider(modifier = Modifier.padding(start = 56.dp))
                        // Аккаунт
                        SettingsNavigationRow(
                            icon = Icons.Filled.Person,
                            iconTint = colors.accentBlue,
                            title = LocalizationService.accountSettings,
                            onClick = {
                                HapticService.lightTap(haptic)
                                onNavigateToAccount()
                            }
                        )
                        // Админ-панель (only visible if admin)
                        if (AuthService.isAdmin) {
                            HorizontalDivider(modifier = Modifier.padding(start = 56.dp))
                            SettingsNavigationRow(
                                icon = Icons.Filled.AdminPanelSettings,
                                iconTint = colors.accentPurple,
                                title = LocalizationService.adminPanel,
                                onClick = {
                                    HapticService.lightTap(haptic)
                                    onNavigateToAdmin()
                                }
                            )
                        }
                    }
                }
            }

            // Рейтинг section
            item {
                AnimatedVisibility(
                    visible = appear,
                    enter = fadeIn() + slideInVertically(
                        initialOffsetY = { 120 },
                        animationSpec = spring(stiffness = Spring.StiffnessLow, dampingRatio = 0.8f)
                    )
                ) {
                    SettingsSection(
                        title = LocalizationService.rating
                    ) {
                        // Points row
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 14.dp, vertical = 10.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Box(
                                    modifier = Modifier
                                        .size(32.dp)
                                        .clip(RoundedCornerShape(8.dp))
                                        .background(colors.accentBlue.copy(alpha = 0.15f)),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        imageVector = Icons.Filled.Star,
                                        contentDescription = null,
                                        tint = colors.accentBlue,
                                        modifier = Modifier.size(16.dp)
                                    )
                                }
                                Spacer(modifier = Modifier.width(12.dp))
                                Text(
                                    text = LocalizationService.localized("Очки", "Points"),
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = colors.textPrimary
                                )
                            }
                            Text(
                                text = "$ratingPoints",
                                style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Bold),
                                color = colors.accentBlue
                            )
                        }

                        HorizontalDivider(modifier = Modifier.padding(start = 56.dp))

                        // Tier row
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 14.dp, vertical = 10.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = LocalizationService.tier,
                                style = MaterialTheme.typography.bodyLarge,
                                color = colors.textPrimary,
                                modifier = Modifier.padding(start = 44.dp)
                            )
                            Text(
                                text = "$ratingTier",
                                style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Bold),
                                color = colors.accentPurple
                            )
                        }

                        // Progress bar
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 14.dp)
                                .padding(bottom = 12.dp),
                            verticalArrangement = Arrangement.spacedBy(4.dp)
                        ) {
                            Text(
                                text = LocalizationService.localized(
                                    "Прогресс до следующего уровня",
                                    "Progress to next tier"
                                ),
                                style = MaterialTheme.typography.bodySmall,
                                color = colors.textTertiary
                            )
                            LinearProgressIndicator(
                                progress = { RatingService.progressToTier2 },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(8.dp)
                                    .clip(RoundedCornerShape(4.dp)),
                                color = colors.accentPurple,
                                trackColor = colors.glassButtonBackground
                            )
                            Text(
                                text = if (RatingService.isTier2) {
                                    LocalizationService.localized("Максимальный уровень!", "Max tier reached!")
                                } else {
                                    LocalizationService.localized(
                                        "Ещё ${RatingService.pointsToNextTier} ${LocalizationService.ratingPoints}",
                                        "${RatingService.pointsToNextTier} ${LocalizationService.ratingPoints} to go"
                                    )
                                },
                                style = MaterialTheme.typography.labelSmall,
                                color = colors.textTertiary
                            )
                        }
                    }
                }
            }

            // О Finder section
            item {
                AnimatedVisibility(
                    visible = appear,
                    enter = fadeIn() + slideInVertically(
                        initialOffsetY = { 140 },
                        animationSpec = spring(stiffness = Spring.StiffnessLow, dampingRatio = 0.8f)
                    )
                ) {
                    SettingsSection(
                        title = LocalizationService.aboutFinder
                    ) {
                        SettingsValueRow(
                            icon = Icons.Filled.Info,
                            iconTint = Color(0xFF607D8B),
                            title = LocalizationService.localized("Версия", "Version"),
                            value = "1.0.0",
                            onClick = {}
                        )
                        HorizontalDivider(modifier = Modifier.padding(start = 56.dp))
                        SettingsValueRow(
                            icon = Icons.Filled.Info,
                            iconTint = Color(0xFF607D8B),
                            title = LocalizationService.localized("Сборка", "Build"),
                            value = "2026.04",
                            onClick = {}
                        )
                    }
                }
            }

            // Протокол Fenix danger button
            item {
                AnimatedVisibility(
                    visible = appear,
                    enter = fadeIn() + slideInVertically(
                        initialOffsetY = { 160 },
                        animationSpec = spring(stiffness = Spring.StiffnessLow, dampingRatio = 0.8f)
                    )
                ) {
                    Column(modifier = Modifier.padding(horizontal = 16.dp)) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .glassCard(cornerRadius = 16.dp)
                                .clickable(
                                    interactionSource = remember { MutableInteractionSource() },
                                    indication = null
                                ) {
                                    HapticService.mediumTap(haptic)
                                    showFenixDialog = true
                                }
                                .padding(vertical = 14.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Row(
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Filled.LocalFireDepartment,
                                    contentDescription = null,
                                    tint = colors.errorRed,
                                    modifier = Modifier.size(20.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    text = LocalizationService.fenixProtocol,
                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                    color = colors.errorRed
                                )
                            }
                        }
                    }
                }
            }

            // Выйти button
            item {
                AnimatedVisibility(
                    visible = appear,
                    enter = fadeIn() + slideInVertically(
                        initialOffsetY = { 180 },
                        animationSpec = spring(stiffness = Spring.StiffnessLow, dampingRatio = 0.8f)
                    )
                ) {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp)
                            .glassCard(cornerRadius = 16.dp)
                            .clickable(
                                interactionSource = remember { MutableInteractionSource() },
                                indication = null
                            ) {
                                HapticService.mediumTap(haptic)
                                showLogoutDialog = true
                            }
                            .padding(vertical = 14.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.Center
                        ) {
                            Icon(
                                imageVector = Icons.AutoMirrored.Filled.ExitToApp,
                                contentDescription = null,
                                tint = colors.warningOrange,
                                modifier = Modifier.size(20.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = LocalizationService.logout,
                                style = MaterialTheme.typography.titleMedium,
                                color = colors.warningOrange
                            )
                        }
                    }
                }
            }

            // Version footer
            item {
                Text(
                    text = "Finder v1.0.0",
                    style = MaterialTheme.typography.bodySmall,
                    color = colors.textTertiary,
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(top = 8.dp),
                    textAlign = TextAlign.Center
                )
            }
        }
    }

    // Fenix Protocol confirmation dialog
    if (showFenixDialog) {
        AlertDialog(
            onDismissRequest = { showFenixDialog = false },
            title = {
                Text(
                    text = LocalizationService.fenixProtocol,
                    color = colors.errorRed,
                    fontWeight = FontWeight.Bold
                )
            },
            text = {
                Text(
                    text = LocalizationService.localized(
                        "Все ваши данные будут безвозвратно удалены. Это действие НЕЛЬЗЯ отменить.",
                        "All your data will be permanently deleted. This action CANNOT be undone."
                    ),
                    style = MaterialTheme.typography.bodyMedium,
                    color = colors.textSecondary
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    showFenixDialog = false
                    HapticService.destructionPattern()
                    AuthService.executeFenixProtocol()
                }) {
                    Text(
                        text = LocalizationService.localized("Уничтожить", "Destroy"),
                        color = colors.errorRed,
                        fontWeight = FontWeight.Bold
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { showFenixDialog = false }) {
                    Text(LocalizationService.cancel)
                }
            }
        )
    }

    // Logout confirmation dialog
    if (showLogoutDialog) {
        AlertDialog(
            onDismissRequest = { showLogoutDialog = false },
            title = {
                Text(LocalizationService.localized("Выйти из аккаунта?", "Log out?"))
            },
            confirmButton = {
                TextButton(onClick = {
                    showLogoutDialog = false
                    HapticService.destructionPattern()
                    AuthService.logout()
                }) {
                    Text(
                        text = LocalizationService.logout,
                        color = colors.errorRed
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { showLogoutDialog = false }) {
                    Text(LocalizationService.cancel)
                }
            }
        )
    }
}

// ─── Profile Card ──────────────────────────────────────────────────────

@Composable
private fun ProfileCard(
    displayName: String,
    username: String,
    finderId: String
) {
    val colors = FinderTheme.colors

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp)
            .glassCard(cornerRadius = 16.dp)
            .padding(14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        // Avatar
        Box(
            modifier = Modifier
                .size(60.dp)
                .clip(RoundedCornerShape(30.dp))
                .background(
                    brush = Brush.linearGradient(
                        colors = listOf(colors.accentBlue, colors.accentCyan)
                    )
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Filled.Person,
                contentDescription = null,
                tint = Color.White,
                modifier = Modifier.size(28.dp)
            )
        }

        Spacer(modifier = Modifier.width(14.dp))

        Column {
            Text(
                text = displayName,
                style = MaterialTheme.typography.titleLarge,
                color = colors.textPrimary
            )
            Text(
                text = "@$username",
                style = MaterialTheme.typography.bodyMedium,
                color = colors.textSecondary
            )
            Text(
                text = finderId,
                style = MaterialTheme.typography.labelSmall.copy(
                    fontFamily = androidx.compose.ui.text.font.FontFamily.Monospace
                ),
                color = colors.accentCyan
            )
        }
    }
}

// ─── Settings Section Container ────────────────────────────────────────

@Composable
fun SettingsSection(
    title: String,
    iconTint: Color = FinderTheme.colors.textSecondary,
    content: @Composable () -> Unit
) {
    val colors = FinderTheme.colors

    Column(modifier = Modifier.padding(horizontal = 16.dp)) {
        Text(
            text = title,
            style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
            color = colors.textSecondary,
            modifier = Modifier.padding(start = 4.dp, bottom = 6.dp)
        )
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .glassCard(cornerRadius = 16.dp)
        ) {
            content()
        }
    }
}

// ─── Reusable Settings Row Components ──────────────────────────────────

@Composable
fun SettingsNavigationRow(
    icon: ImageVector,
    iconTint: Color,
    title: String,
    subtitle: String? = null,
    onClick: () -> Unit
) {
    val colors = FinderTheme.colors

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick
            )
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(32.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(iconTint.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = iconTint,
                modifier = Modifier.size(16.dp)
            )
        }
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                color = colors.textPrimary
            )
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = colors.textSecondary
                )
            }
        }
        Text(
            text = ">",
            style = MaterialTheme.typography.bodySmall,
            color = colors.textTertiary
        )
    }
}

@Composable
fun SettingsToggleRow(
    icon: ImageVector,
    iconTint: Color,
    title: String,
    subtitle: String? = null,
    isChecked: Boolean,
    onCheckedChange: (Boolean) -> Unit
) {
    val colors = FinderTheme.colors

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 14.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(32.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(iconTint.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = iconTint,
                modifier = Modifier.size(16.dp)
            )
        }
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                color = colors.textPrimary
            )
            if (subtitle != null) {
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.bodySmall,
                    color = colors.textSecondary
                )
            }
        }
        Switch(
            checked = isChecked,
            onCheckedChange = onCheckedChange,
            colors = SwitchDefaults.colors(
                checkedThumbColor = Color.White,
                checkedTrackColor = colors.accentBlue
            )
        )
    }
}

@Composable
fun SettingsValueRow(
    icon: ImageVector,
    iconTint: Color,
    title: String,
    value: String,
    onClick: () -> Unit
) {
    val colors = FinderTheme.colors

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick
            )
            .padding(horizontal = 14.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(32.dp)
                .clip(RoundedCornerShape(8.dp))
                .background(iconTint.copy(alpha = 0.15f)),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = iconTint,
                modifier = Modifier.size(16.dp)
            )
        }
        Spacer(modifier = Modifier.width(12.dp))
        Text(
            text = title,
            style = MaterialTheme.typography.bodyLarge,
            color = colors.textPrimary,
            modifier = Modifier.weight(1f)
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            color = colors.textSecondary
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = ">",
            style = MaterialTheme.typography.bodySmall,
            color = colors.textTertiary
        )
    }
}
