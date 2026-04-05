package com.finder.app.ui.screens.settings

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
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
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Badge
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.finder.app.services.AuthService
import com.finder.app.services.HapticService
import com.finder.app.services.LocalizationService
import com.finder.app.ui.theme.FinderTheme
import com.finder.app.ui.theme.glassCard
import com.finder.app.ui.theme.glassTextField

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AccountSettingsScreen(
    onBack: () -> Unit = {},
    onFenixProtocol: () -> Unit = {}
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current
    val displayName by AuthService.currentDisplayName.collectAsState()
    val username by AuthService.currentUsername.collectAsState()
    val finderId by AuthService.currentFinderID.collectAsState()

    var showEditNameDialog by remember { mutableStateOf(false) }
    var showChangePinDialog by remember { mutableStateOf(false) }
    var showFenixConfirmDialog by remember { mutableStateOf(false) }
    var editNameText by remember { mutableStateOf(displayName) }
    var newPinText by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        TopAppBar(
            title = {
                Text(
                    text = LocalizationService.localized("Аккаунт", "Account"),
                    style = MaterialTheme.typography.titleLarge
                )
            },
            navigationIcon = {
                IconButton(onClick = onBack) {
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
            // Account Info section
            item {
                SettingsSection(
                    title = LocalizationService.localized("Информация", "Information")
                ) {
                    AccountInfoRow(
                        icon = Icons.Filled.Person,
                        iconTint = colors.accentBlue,
                        label = LocalizationService.localized("Имя", "Name"),
                        value = displayName
                    )
                    HorizontalDivider(modifier = Modifier.padding(start = 56.dp))
                    AccountInfoRow(
                        icon = Icons.Filled.Edit,
                        iconTint = colors.accentCyan,
                        label = LocalizationService.username,
                        value = "@$username"
                    )
                    HorizontalDivider(modifier = Modifier.padding(start = 56.dp))
                    AccountInfoRow(
                        icon = Icons.Filled.Badge,
                        iconTint = Color(0xFF5C6BC0),
                        label = "Finder ID",
                        value = finderId,
                        isMonospaced = true
                    )
                }
            }

            // Management section
            item {
                SettingsSection(
                    title = LocalizationService.localized("Управление", "Management")
                ) {
                    SettingsNavigationRow(
                        icon = Icons.Filled.Edit,
                        iconTint = colors.accentBlue,
                        title = LocalizationService.localized("Изменить имя", "Change Display Name"),
                        onClick = {
                            HapticService.lightTap(haptic)
                            editNameText = displayName
                            showEditNameDialog = true
                        }
                    )
                    HorizontalDivider(modifier = Modifier.padding(start = 56.dp))
                    SettingsNavigationRow(
                        icon = Icons.Filled.Lock,
                        iconTint = Color(0xFF4CAF50),
                        title = LocalizationService.localized("Изменить PIN", "Change PIN"),
                        onClick = {
                            HapticService.lightTap(haptic)
                            newPinText = ""
                            showChangePinDialog = true
                        }
                    )
                }
            }

            // Danger Zone section
            item {
                Column(modifier = Modifier.padding(horizontal = 16.dp)) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.padding(start = 4.dp, bottom = 6.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Warning,
                            contentDescription = null,
                            tint = colors.errorRed,
                            modifier = Modifier.size(13.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(
                            text = LocalizationService.localized("Опасная зона", "Danger Zone"),
                            style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                            color = colors.errorRed
                        )
                    }

                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .glassCard(cornerRadius = 16.dp)
                            .border(
                                width = 1.dp,
                                color = colors.errorRed.copy(alpha = 0.15f),
                                shape = RoundedCornerShape(16.dp)
                            )
                    ) {
                        // Fenix Protocol
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable(
                                    interactionSource = remember { MutableInteractionSource() },
                                    indication = null
                                ) {
                                    HapticService.mediumTap(haptic)
                                    showFenixConfirmDialog = true
                                }
                                .padding(horizontal = 14.dp, vertical = 12.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(32.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(colors.errorRed.copy(alpha = 0.15f)),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Filled.LocalFireDepartment,
                                    contentDescription = null,
                                    tint = colors.errorRed,
                                    modifier = Modifier.size(16.dp)
                                )
                            }
                            Spacer(modifier = Modifier.width(12.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(
                                    text = LocalizationService.fenixProtocol,
                                    style = MaterialTheme.typography.bodyLarge.copy(fontWeight = FontWeight.Bold),
                                    color = colors.errorRed
                                )
                                Text(
                                    text = LocalizationService.localized(
                                        "Безвозвратное удаление всех данных",
                                        "Irreversible deletion of all data"
                                    ),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = colors.textSecondary
                                )
                            }
                            Text(
                                text = ">",
                                style = MaterialTheme.typography.bodySmall,
                                color = colors.textTertiary
                            )
                        }
                    }
                }
            }
        }
    }

    // Edit name dialog
    if (showEditNameDialog) {
        AlertDialog(
            onDismissRequest = { showEditNameDialog = false },
            title = {
                Text(LocalizationService.localized("Изменить имя", "Change Display Name"))
            },
            text = {
                BasicTextField(
                    value = editNameText,
                    onValueChange = { editNameText = it },
                    textStyle = MaterialTheme.typography.bodyLarge.copy(
                        color = colors.textPrimary
                    ),
                    cursorBrush = SolidColor(colors.accentBlue),
                    modifier = Modifier
                        .fillMaxWidth()
                        .glassTextField()
                        .padding(14.dp),
                    singleLine = true
                )
            },
            confirmButton = {
                TextButton(onClick = {
                    if (editNameText.isNotBlank()) {
                        // In a real app, update display name via service
                        HapticService.success(haptic)
                        showEditNameDialog = false
                    }
                }) {
                    Text(LocalizationService.save, color = colors.accentBlue)
                }
            },
            dismissButton = {
                TextButton(onClick = { showEditNameDialog = false }) {
                    Text(LocalizationService.cancel)
                }
            }
        )
    }

    // Change PIN dialog
    if (showChangePinDialog) {
        AlertDialog(
            onDismissRequest = { showChangePinDialog = false },
            title = {
                Text(LocalizationService.localized("Изменить PIN", "Change PIN"))
            },
            text = {
                Column {
                    Text(
                        text = LocalizationService.localized(
                            "Введите новый 4-значный PIN-код",
                            "Enter a new 4-digit PIN code"
                        ),
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.textSecondary
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    BasicTextField(
                        value = newPinText,
                        onValueChange = { if (it.length <= 4 && it.all { c -> c.isDigit() }) newPinText = it },
                        textStyle = MaterialTheme.typography.headlineMedium.copy(
                            color = colors.textPrimary,
                            textAlign = TextAlign.Center,
                            letterSpacing = MaterialTheme.typography.headlineMedium.letterSpacing * 3
                        ),
                        cursorBrush = SolidColor(colors.accentBlue),
                        modifier = Modifier
                            .fillMaxWidth()
                            .glassTextField()
                            .padding(14.dp),
                        singleLine = true
                    )
                }
            },
            confirmButton = {
                TextButton(
                    onClick = {
                        if (newPinText.length == 4) {
                            AuthService.setupPIN(newPinText)
                            HapticService.success(haptic)
                            showChangePinDialog = false
                        }
                    },
                    enabled = newPinText.length == 4
                ) {
                    Text(LocalizationService.save, color = if (newPinText.length == 4) colors.accentBlue else colors.textTertiary)
                }
            },
            dismissButton = {
                TextButton(onClick = { showChangePinDialog = false }) {
                    Text(LocalizationService.cancel)
                }
            }
        )
    }

    // Fenix Protocol confirmation
    if (showFenixConfirmDialog) {
        AlertDialog(
            onDismissRequest = { showFenixConfirmDialog = false },
            title = {
                Text(
                    text = LocalizationService.fenixProtocol,
                    color = colors.errorRed
                )
            },
            text = {
                Column {
                    Text(
                        text = LocalizationService.localized(
                            "Все ваши данные будут безвозвратно удалены. Это действие НЕЛЬЗЯ отменить.",
                            "All your data will be permanently deleted. This action CANNOT be undone."
                        ),
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.textSecondary
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    Text(
                        text = "Finder ID: $finderId",
                        style = MaterialTheme.typography.bodySmall.copy(
                            fontFamily = FontFamily.Monospace
                        ),
                        color = colors.accentCyan
                    )
                }
            },
            confirmButton = {
                TextButton(onClick = {
                    HapticService.destructionPattern()
                    AuthService.executeFenixProtocol()
                    showFenixConfirmDialog = false
                    onFenixProtocol()
                }) {
                    Text(
                        text = LocalizationService.localized("Уничтожить", "Destroy"),
                        color = colors.errorRed,
                        fontWeight = FontWeight.Bold
                    )
                }
            },
            dismissButton = {
                TextButton(onClick = { showFenixConfirmDialog = false }) {
                    Text(LocalizationService.cancel)
                }
            }
        )
    }
}

@Composable
private fun AccountInfoRow(
    icon: ImageVector,
    iconTint: Color,
    label: String,
    value: String,
    isMonospaced: Boolean = false
) {
    val colors = FinderTheme.colors

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 14.dp, vertical = 10.dp),
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
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = colors.textSecondary
        )
        Spacer(modifier = Modifier.weight(1f))
        Text(
            text = value,
            style = if (isMonospaced) {
                MaterialTheme.typography.bodyMedium.copy(fontFamily = FontFamily.Monospace)
            } else {
                MaterialTheme.typography.bodyMedium
            },
            color = colors.textPrimary
        )
    }
}
