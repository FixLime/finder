package com.finder.app.ui.screens.profile

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.fadeIn
import androidx.compose.animation.slideInVertically
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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Flag
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.finder.app.models.AvatarColor
import com.finder.app.models.FinderUser
import com.finder.app.services.AdminService
import com.finder.app.services.HapticService
import com.finder.app.ui.theme.FinderTheme
import com.finder.app.ui.theme.glassCard
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import java.util.UUID

@Composable
fun UserProfileScreen(
    userId: String,
    onBack: () -> Unit,
    onStartChat: () -> Unit,
    onReport: () -> Unit
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current

    val verifiedUsernames by AdminService.verifiedUsernames.collectAsState()
    val untrustedUsernames by AdminService.untrustedUsernames.collectAsState()
    val bannedUsernames by AdminService.bannedUsernames.collectAsState()

    // Demo user based on userId
    val user = remember(userId, verifiedUsernames, untrustedUsernames, bannedUsernames) {
        FinderUser(
            id = try { UUID.fromString(userId) } catch (_: Exception) { UUID.randomUUID() },
            username = userId,
            displayName = userId.replaceFirstChar { it.uppercase() },
            avatarIcon = "person",
            avatarColor = AvatarColor.entries[userId.hashCode().mod(AvatarColor.entries.size).let { if (it < 0) it + AvatarColor.entries.size else it }],
            statusText = "\u0418\u0441\u043F\u043E\u043B\u044C\u0437\u0443\u044E Finder",
            isOnline = userId.hashCode() % 2 == 0,
            lastSeen = Date(),
            isVerified = verifiedUsernames.contains(userId),
            isUntrusted = untrustedUsernames.contains(userId),
            isBanned = bannedUsernames.contains(userId),
            isDeleted = false,
            finderID = "FID-${userId.hashCode().toUInt().toString(16).take(8).uppercase()}",
            joinDate = Date(System.currentTimeMillis() - (86400000L * 30)),
            privacySettings = com.finder.app.models.PrivacySettings.default
        )
    }

    var appear by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { appear = true }

    val dateFormat = remember { SimpleDateFormat("dd.MM.yyyy", Locale("ru")) }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        // Top bar
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 8.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = {
                HapticService.lightTap(haptic)
                onBack()
            }) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "\u041D\u0430\u0437\u0430\u0434",
                    tint = colors.textPrimary
                )
            }
            Text(
                text = "\u041F\u0440\u043E\u0444\u0438\u043B\u044C",
                style = MaterialTheme.typography.titleLarge,
                color = colors.textPrimary,
                fontWeight = FontWeight.Bold
            )
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(16.dp))

            // Untrusted warning banner
            if (user.isUntrusted) {
                AnimatedVisibility(
                    visible = appear,
                    enter = fadeIn() + slideInVertically(
                        animationSpec = spring(stiffness = Spring.StiffnessLow)
                    )
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(
                                colors.warningOrange.copy(alpha = 0.15f),
                                RoundedCornerShape(12.dp)
                            )
                            .border(
                                0.5.dp,
                                colors.warningOrange.copy(alpha = 0.3f),
                                RoundedCornerShape(12.dp)
                            )
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Warning,
                            contentDescription = null,
                            tint = colors.warningOrange,
                            modifier = Modifier.size(20.dp)
                        )
                        Spacer(modifier = Modifier.width(8.dp))
                        Text(
                            text = "\u042D\u0442\u043E\u0442 \u043F\u043E\u043B\u044C\u0437\u043E\u0432\u0430\u0442\u0435\u043B\u044C \u043E\u0442\u043C\u0435\u0447\u0435\u043D \u043A\u0430\u043A \u043D\u0435\u043D\u0430\u0434\u0451\u0436\u043D\u044B\u0439",
                            style = MaterialTheme.typography.bodyMedium,
                            color = colors.warningOrange,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
                Spacer(modifier = Modifier.height(20.dp))
            }

            // Avatar
            AnimatedVisibility(
                visible = appear,
                enter = fadeIn(animationSpec = spring(stiffness = Spring.StiffnessLow))
            ) {
                Box(
                    modifier = Modifier
                        .size(100.dp)
                        .clip(CircleShape)
                        .background(user.avatarColor.color),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Filled.Person,
                        contentDescription = null,
                        tint = Color.White,
                        modifier = Modifier.size(50.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Display name with badge
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                Text(
                    text = user.displayName,
                    style = MaterialTheme.typography.headlineMedium,
                    color = colors.textPrimary,
                    fontWeight = FontWeight.Bold
                )
                if (user.isVerified) {
                    Spacer(modifier = Modifier.width(6.dp))
                    Icon(
                        imageVector = Icons.Filled.CheckCircle,
                        contentDescription = "\u041F\u043E\u0434\u0442\u0432\u0435\u0440\u0436\u0434\u0451\u043D",
                        tint = colors.accentBlue,
                        modifier = Modifier.size(22.dp)
                    )
                }
                if (user.isUntrusted) {
                    Spacer(modifier = Modifier.width(6.dp))
                    Icon(
                        imageVector = Icons.Filled.Warning,
                        contentDescription = "\u041D\u0435\u043D\u0430\u0434\u0451\u0436\u043D\u044B\u0439",
                        tint = colors.warningOrange,
                        modifier = Modifier.size(22.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(4.dp))

            // Username
            Text(
                text = "@${user.username}",
                style = MaterialTheme.typography.bodyLarge,
                color = colors.textSecondary
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Online status
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.Center
            ) {
                Box(
                    modifier = Modifier
                        .size(8.dp)
                        .clip(CircleShape)
                        .background(
                            if (user.isOnline) colors.onlineGreen else colors.textTertiary
                        )
                )
                Spacer(modifier = Modifier.width(6.dp))
                Text(
                    text = if (user.isOnline) "\u0412 \u0441\u0435\u0442\u0438" else "\u041D\u0435 \u0432 \u0441\u0435\u0442\u0438",
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (user.isOnline) colors.onlineGreen else colors.textTertiary
                )
            }

            Spacer(modifier = Modifier.height(12.dp))

            // Status text
            if (user.statusText.isNotBlank()) {
                Text(
                    text = user.statusText,
                    style = MaterialTheme.typography.bodyMedium,
                    color = colors.textSecondary,
                    textAlign = TextAlign.Center
                )
                Spacer(modifier = Modifier.height(12.dp))
            }

            // Info card
            AnimatedVisibility(
                visible = appear,
                enter = fadeIn() + slideInVertically(
                    initialOffsetY = { it / 4 },
                    animationSpec = spring(stiffness = Spring.StiffnessLow)
                )
            ) {
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .glassCard()
                        .padding(16.dp)
                ) {
                    ProfileInfoRow(
                        label = "Finder ID",
                        value = user.finderID,
                        colors = colors
                    )
                    Spacer(modifier = Modifier.height(12.dp))
                    ProfileInfoRow(
                        label = "\u0414\u0430\u0442\u0430 \u0440\u0435\u0433\u0438\u0441\u0442\u0440\u0430\u0446\u0438\u0438",
                        value = dateFormat.format(user.joinDate),
                        colors = colors
                    )
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Action buttons
            AnimatedVisibility(
                visible = appear,
                enter = fadeIn() + slideInVertically(
                    initialOffsetY = { it / 3 },
                    animationSpec = spring(stiffness = Spring.StiffnessLow)
                )
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    ProfileActionButton(
                        icon = Icons.AutoMirrored.Filled.Chat,
                        label = "\u041D\u0430\u043F\u0438\u0441\u0430\u0442\u044C",
                        color = colors.accentBlue,
                        modifier = Modifier.weight(1f),
                        onClick = {
                            HapticService.mediumTap(haptic)
                            onStartChat()
                        }
                    )
                    ProfileActionButton(
                        icon = Icons.Filled.Call,
                        label = "\u041F\u043E\u0437\u0432\u043E\u043D\u0438\u0442\u044C",
                        color = colors.onlineGreen,
                        modifier = Modifier.weight(1f),
                        onClick = {
                            HapticService.mediumTap(haptic)
                        }
                    )
                    ProfileActionButton(
                        icon = Icons.Filled.Flag,
                        label = "\u041F\u043E\u0436\u0430\u043B\u043E\u0432\u0430\u0442\u044C\u0441\u044F",
                        color = colors.errorRed,
                        modifier = Modifier.weight(1f),
                        onClick = {
                            HapticService.mediumTap(haptic)
                            onReport()
                        }
                    )
                }
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
private fun ProfileInfoRow(
    label: String,
    value: String,
    colors: com.finder.app.ui.theme.FinderColorScheme
) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodyMedium,
            color = colors.textSecondary
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodyMedium,
            color = colors.textPrimary,
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
private fun ProfileActionButton(
    icon: ImageVector,
    label: String,
    color: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    val colors = FinderTheme.colors
    Column(
        modifier = modifier
            .glassCard()
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick
            )
            .padding(vertical = 16.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            tint = color,
            modifier = Modifier.size(24.dp)
        )
        Spacer(modifier = Modifier.height(6.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.labelMedium,
            color = colors.textSecondary
        )
    }
}
