package com.finder.app.ui.screens.admin

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
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Block
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Restore
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextField
import androidx.compose.material3.TextFieldDefaults
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
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.finder.app.models.ReportCategory
import com.finder.app.models.UserReport
import com.finder.app.services.AdminService
import com.finder.app.services.HapticService
import com.finder.app.services.ReportService
import com.finder.app.ui.theme.FinderTheme
import com.finder.app.ui.theme.glassCard
import com.finder.app.ui.theme.glassTextField
import java.text.SimpleDateFormat
import java.util.Locale

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun AdminPanelScreen(
    onBack: () -> Unit
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current

    val reports by ReportService.reports.collectAsState()
    val verifiedUsernames by AdminService.verifiedUsernames.collectAsState()
    val bannedUsernames by AdminService.bannedUsernames.collectAsState()
    val untrustedUsernames by AdminService.untrustedUsernames.collectAsState()
    val deletedUsernames by AdminService.deletedUsernames.collectAsState()

    var targetUsername by remember { mutableStateOf("") }
    var appear by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) { appear = true }

    val dateFormat = remember { SimpleDateFormat("dd.MM.yyyy HH:mm", Locale("ru")) }

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
            Icon(
                imageVector = Icons.Filled.Shield,
                contentDescription = null,
                tint = colors.accentPurple,
                modifier = Modifier.size(22.dp)
            )
            Spacer(modifier = Modifier.width(8.dp))
            Text(
                text = "\u0410\u0434\u043C\u0438\u043D-\u043F\u0430\u043D\u0435\u043B\u044C",
                style = MaterialTheme.typography.titleLarge,
                color = colors.textPrimary,
                fontWeight = FontWeight.Bold
            )
        }

        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 20.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            // ---- User Actions Section ----
            item {
                AnimatedVisibility(
                    visible = appear,
                    enter = fadeIn() + slideInVertically(
                        initialOffsetY = { it / 4 },
                        animationSpec = spring(stiffness = Spring.StiffnessLow)
                    )
                ) {
                    Column {
                        Text(
                            text = "\u0414\u0435\u0439\u0441\u0442\u0432\u0438\u044F \u0441 \u043F\u043E\u043B\u044C\u0437\u043E\u0432\u0430\u0442\u0435\u043B\u044F\u043C\u0438",
                            style = MaterialTheme.typography.titleMedium,
                            color = colors.textPrimary,
                            fontWeight = FontWeight.SemiBold
                        )

                        Spacer(modifier = Modifier.height(10.dp))

                        // Username input
                        TextField(
                            value = targetUsername,
                            onValueChange = { targetUsername = it },
                            modifier = Modifier
                                .fillMaxWidth()
                                .glassTextField(),
                            placeholder = {
                                Text(
                                    text = "\u0418\u043C\u044F \u043F\u043E\u043B\u044C\u0437\u043E\u0432\u0430\u0442\u0435\u043B\u044F",
                                    color = colors.textTertiary
                                )
                            },
                            leadingIcon = {
                                Icon(
                                    imageVector = Icons.Filled.Person,
                                    contentDescription = null,
                                    tint = colors.textTertiary
                                )
                            },
                            singleLine = true,
                            colors = TextFieldDefaults.colors(
                                focusedTextColor = colors.textPrimary,
                                unfocusedTextColor = colors.textPrimary,
                                cursorColor = colors.accentBlue,
                                focusedContainerColor = Color.Transparent,
                                unfocusedContainerColor = Color.Transparent,
                                focusedIndicatorColor = Color.Transparent,
                                unfocusedIndicatorColor = Color.Transparent
                            )
                        )

                        Spacer(modifier = Modifier.height(12.dp))

                        // Action buttons grid
                        FlowRow(
                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                            verticalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            val isVerified = verifiedUsernames.contains(targetUsername)
                            val isBanned = bannedUsernames.contains(targetUsername)
                            val isUntrusted = untrustedUsernames.contains(targetUsername)
                            val isDeleted = deletedUsernames.contains(targetUsername)
                            val hasTarget = targetUsername.isNotBlank()

                            AdminActionChip(
                                label = if (isVerified) "\u0421\u043D\u044F\u0442\u044C \u0432\u0435\u0440\u0438\u0444." else "\u0412\u0435\u0440\u0438\u0444\u0438\u0446\u0438\u0440\u043E\u0432\u0430\u0442\u044C",
                                icon = Icons.Filled.CheckCircle,
                                color = colors.accentBlue,
                                enabled = hasTarget,
                                onClick = {
                                    HapticService.success(haptic)
                                    if (isVerified) AdminService.unverifyUser(targetUsername)
                                    else AdminService.verifyUser(targetUsername)
                                }
                            )
                            AdminActionChip(
                                label = if (isBanned) "\u0420\u0430\u0437\u0431\u0430\u043D\u0438\u0442\u044C" else "\u0417\u0430\u0431\u0430\u043D\u0438\u0442\u044C",
                                icon = Icons.Filled.Block,
                                color = colors.errorRed,
                                enabled = hasTarget,
                                onClick = {
                                    HapticService.warning()
                                    if (isBanned) AdminService.unbanUser(targetUsername)
                                    else AdminService.banUser(targetUsername)
                                }
                            )
                            AdminActionChip(
                                label = if (isDeleted) "\u0412\u043E\u0441\u0441\u0442\u0430\u043D\u043E\u0432\u0438\u0442\u044C" else "\u0423\u0434\u0430\u043B\u0438\u0442\u044C",
                                icon = if (isDeleted) Icons.Filled.Restore else Icons.Filled.Delete,
                                color = if (isDeleted) colors.onlineGreen else colors.errorRed,
                                enabled = hasTarget,
                                onClick = {
                                    HapticService.destructionPattern()
                                    if (isDeleted) AdminService.restoreUser(targetUsername)
                                    else AdminService.deleteUser(targetUsername)
                                }
                            )
                            AdminActionChip(
                                label = if (isUntrusted) "\u0414\u043E\u0432\u0435\u0440\u044F\u0442\u044C" else "\u041D\u0435\u043D\u0430\u0434\u0451\u0436\u043D\u044B\u0439",
                                icon = Icons.Filled.Warning,
                                color = colors.warningOrange,
                                enabled = hasTarget,
                                onClick = {
                                    HapticService.warning()
                                    if (isUntrusted) AdminService.trustUser(targetUsername)
                                    else AdminService.untrustUser(targetUsername)
                                }
                            )
                        }
                    }
                }
            }

            // ---- Reports Section ----
            item {
                Spacer(modifier = Modifier.height(8.dp))
                HorizontalDivider(color = colors.glassBorder)
                Spacer(modifier = Modifier.height(8.dp))

                Row(
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "\u0416\u0430\u043B\u043E\u0431\u044B",
                        style = MaterialTheme.typography.titleMedium,
                        color = colors.textPrimary,
                        fontWeight = FontWeight.SemiBold
                    )
                    if (reports.isNotEmpty()) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Box(
                            modifier = Modifier
                                .size(24.dp)
                                .background(colors.errorRed, CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = reports.size.toString(),
                                style = MaterialTheme.typography.labelSmall,
                                color = Color.White,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }
                }
            }

            if (reports.isEmpty()) {
                item {
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 40.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "\u041D\u0435\u0442 \u0436\u0430\u043B\u043E\u0431",
                            style = MaterialTheme.typography.bodyLarge,
                            color = colors.textTertiary
                        )
                    }
                }
            } else {
                itemsIndexed(
                    items = reports,
                    key = { _, report -> report.id.toString() }
                ) { index, report ->
                    AnimatedVisibility(
                        visible = appear,
                        enter = fadeIn() + slideInVertically(
                            initialOffsetY = { it / 3 },
                            animationSpec = spring(
                                stiffness = Spring.StiffnessLow,
                                dampingRatio = Spring.DampingRatioMediumBouncy
                            )
                        )
                    ) {
                        ReportCard(
                            report = report,
                            dateFormat = dateFormat,
                            onBan = {
                                HapticService.destructionPattern()
                                AdminService.banUser(report.reportedUsername)
                                ReportService.dismissReport(report.id)
                            },
                            onUntrust = {
                                HapticService.warning()
                                AdminService.untrustUser(report.reportedUsername)
                                ReportService.dismissReport(report.id)
                            },
                            onDismiss = {
                                HapticService.mediumTap(haptic)
                                ReportService.dismissReport(report.id)
                            }
                        )
                    }
                }
            }

            item { Spacer(modifier = Modifier.height(32.dp)) }
        }
    }
}

@Composable
private fun AdminActionChip(
    label: String,
    icon: ImageVector,
    color: Color,
    enabled: Boolean,
    onClick: () -> Unit
) {
    val colors = FinderTheme.colors
    val alpha = if (enabled) 1f else 0.4f

    Row(
        modifier = Modifier
            .background(
                color.copy(alpha = 0.1f * alpha),
                RoundedCornerShape(12.dp)
            )
            .border(
                0.5.dp,
                color.copy(alpha = 0.3f * alpha),
                RoundedCornerShape(12.dp)
            )
            .clickable(
                enabled = enabled,
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick
            )
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = color.copy(alpha = alpha),
            modifier = Modifier.size(16.dp)
        )
        Spacer(modifier = Modifier.width(6.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.labelLarge,
            color = color.copy(alpha = alpha),
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
private fun ReportCard(
    report: UserReport,
    dateFormat: SimpleDateFormat,
    onBan: () -> Unit,
    onUntrust: () -> Unit,
    onDismiss: () -> Unit
) {
    val colors = FinderTheme.colors
    val category = ReportCategory.fromString(report.category)

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .glassCard()
            .padding(14.dp)
    ) {
        // Header: reporter -> reported
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = "@${report.reporterUsername}",
                    style = MaterialTheme.typography.labelLarge,
                    color = colors.accentBlue,
                    fontWeight = FontWeight.Medium
                )
                Text(
                    text = " \u2192 ",
                    style = MaterialTheme.typography.labelLarge,
                    color = colors.textTertiary
                )
                Text(
                    text = "@${report.reportedUsername}",
                    style = MaterialTheme.typography.labelLarge,
                    color = colors.errorRed,
                    fontWeight = FontWeight.Medium
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Category tag
        Box(
            modifier = Modifier
                .background(category.color.copy(alpha = 0.15f), RoundedCornerShape(8.dp))
                .padding(horizontal = 8.dp, vertical = 3.dp)
        ) {
            Text(
                text = category.ruName,
                style = MaterialTheme.typography.labelSmall,
                color = category.color,
                fontWeight = FontWeight.SemiBold
            )
        }

        // Description
        if (report.description.isNotBlank()) {
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = report.description,
                style = MaterialTheme.typography.bodyMedium,
                color = colors.textSecondary,
                maxLines = 3,
                overflow = TextOverflow.Ellipsis
            )
        }

        Spacer(modifier = Modifier.height(6.dp))

        // Timestamp
        Text(
            text = dateFormat.format(report.timestamp),
            style = MaterialTheme.typography.labelSmall,
            color = colors.textTertiary
        )

        Spacer(modifier = Modifier.height(12.dp))

        // Action buttons
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            ReportActionButton(
                label = "\u0417\u0430\u0431\u0430\u043D\u0438\u0442\u044C",
                color = colors.errorRed,
                modifier = Modifier.weight(1f),
                onClick = onBan
            )
            ReportActionButton(
                label = "\u041D\u0435\u043D\u0430\u0434\u0451\u0436\u043D\u044B\u0439",
                color = colors.warningOrange,
                modifier = Modifier.weight(1f),
                onClick = onUntrust
            )
            ReportActionButton(
                label = "\u041E\u0442\u043A\u043B\u043E\u043D\u0438\u0442\u044C",
                color = colors.textTertiary,
                modifier = Modifier.weight(1f),
                onClick = onDismiss
            )
        }
    }
}

@Composable
private fun ReportActionButton(
    label: String,
    color: Color,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Box(
        modifier = modifier
            .clip(RoundedCornerShape(10.dp))
            .background(color.copy(alpha = 0.12f), RoundedCornerShape(10.dp))
            .border(0.5.dp, color.copy(alpha = 0.3f), RoundedCornerShape(10.dp))
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick
            )
            .padding(vertical = 8.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelMedium,
            color = color,
            fontWeight = FontWeight.SemiBold
        )
    }
}
