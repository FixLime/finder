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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.AttachFile
import androidx.compose.material.icons.filled.CreditCardOff
import androidx.compose.material.icons.filled.FrontHand
import androidx.compose.material.icons.filled.Mail
import androidx.compose.material.icons.filled.MoreHoriz
import androidx.compose.material.icons.filled.PersonOff
import androidx.compose.material.icons.filled.Shield
import androidx.compose.material.icons.filled.VisibilityOff
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
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
import androidx.compose.ui.unit.dp
import com.finder.app.models.ReportCategory
import com.finder.app.services.AuthService
import com.finder.app.services.HapticService
import com.finder.app.services.ReportService
import com.finder.app.ui.theme.FinderTheme
import com.finder.app.ui.theme.glassCard
import com.finder.app.ui.theme.glassTextField

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun ReportUserScreen(
    userId: String,
    onBack: () -> Unit
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current
    val currentUsername by AuthService.currentUsername.collectAsState()

    var selectedCategory by remember { mutableStateOf<ReportCategory?>(null) }
    var description by remember { mutableStateOf("") }
    var includeConversation by remember { mutableStateOf(false) }
    var isSubmitted by remember { mutableStateOf(false) }

    var appear by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) { appear = true }

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
                text = "\u041F\u043E\u0436\u0430\u043B\u043E\u0432\u0430\u0442\u044C\u0441\u044F",
                style = MaterialTheme.typography.titleLarge,
                color = colors.textPrimary,
                fontWeight = FontWeight.Bold
            )
        }

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp)
        ) {
            // Success state
            if (isSubmitted) {
                Spacer(modifier = Modifier.height(40.dp))
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Icon(
                        imageVector = Icons.AutoMirrored.Filled.Send,
                        contentDescription = null,
                        tint = colors.onlineGreen,
                        modifier = Modifier.size(48.dp)
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "\u0416\u0430\u043B\u043E\u0431\u0430 \u043E\u0442\u043F\u0440\u0430\u0432\u043B\u0435\u043D\u0430",
                        style = MaterialTheme.typography.headlineMedium,
                        color = colors.textPrimary,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "\u0421\u043F\u0430\u0441\u0438\u0431\u043E, \u043C\u044B \u0440\u0430\u0441\u0441\u043C\u043E\u0442\u0440\u0438\u043C \u0432\u0430\u0448\u0443 \u0436\u0430\u043B\u043E\u0431\u0443",
                        style = MaterialTheme.typography.bodyLarge,
                        color = colors.textSecondary
                    )
                }
                return@Column
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "\u0412\u044B\u0431\u0435\u0440\u0438\u0442\u0435 \u043F\u0440\u0438\u0447\u0438\u043D\u0443",
                style = MaterialTheme.typography.titleMedium,
                color = colors.textPrimary,
                fontWeight = FontWeight.SemiBold
            )

            Spacer(modifier = Modifier.height(12.dp))

            // Category grid
            AnimatedVisibility(
                visible = appear,
                enter = fadeIn() + slideInVertically(
                    initialOffsetY = { it / 4 },
                    animationSpec = spring(stiffness = Spring.StiffnessLow)
                )
            ) {
                FlowRow(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    ReportCategory.entries.forEach { category ->
                        val isSelected = selectedCategory == category
                        ReportCategoryCard(
                            category = category,
                            isSelected = isSelected,
                            onClick = {
                                HapticService.lightTap(haptic)
                                selectedCategory = category
                            }
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(20.dp))

            // Description field
            Text(
                text = "\u041E\u043F\u0438\u0441\u0430\u043D\u0438\u0435",
                style = MaterialTheme.typography.titleMedium,
                color = colors.textPrimary,
                fontWeight = FontWeight.SemiBold
            )

            Spacer(modifier = Modifier.height(8.dp))

            TextField(
                value = description,
                onValueChange = { description = it },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(120.dp)
                    .glassTextField(),
                placeholder = {
                    Text(
                        text = "\u041E\u043F\u0438\u0448\u0438\u0442\u0435 \u043F\u0440\u043E\u0431\u043B\u0435\u043C\u0443 \u043F\u043E\u0434\u0440\u043E\u0431\u043D\u0435\u0435...",
                        color = colors.textTertiary
                    )
                },
                colors = TextFieldDefaults.colors(
                    focusedTextColor = colors.textPrimary,
                    unfocusedTextColor = colors.textPrimary,
                    cursorColor = colors.accentBlue,
                    focusedContainerColor = Color.Transparent,
                    unfocusedContainerColor = Color.Transparent,
                    focusedIndicatorColor = Color.Transparent,
                    unfocusedIndicatorColor = Color.Transparent
                ),
                maxLines = 6
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Include conversation toggle
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .glassCard()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Filled.AttachFile,
                        contentDescription = null,
                        tint = colors.textSecondary,
                        modifier = Modifier.size(20.dp)
                    )
                    Spacer(modifier = Modifier.width(10.dp))
                    Text(
                        text = "\u041F\u0440\u0438\u043B\u043E\u0436\u0438\u0442\u044C \u043F\u0435\u0440\u0435\u043F\u0438\u0441\u043A\u0443",
                        style = MaterialTheme.typography.bodyLarge,
                        color = colors.textPrimary
                    )
                }
                Switch(
                    checked = includeConversation,
                    onCheckedChange = {
                        HapticService.lightTap(haptic)
                        includeConversation = it
                    },
                    colors = SwitchDefaults.colors(
                        checkedThumbColor = Color.White,
                        checkedTrackColor = colors.accentBlue,
                        uncheckedThumbColor = colors.textTertiary,
                        uncheckedTrackColor = colors.glassButtonBackground
                    )
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Submit button
            val canSubmit = selectedCategory != null
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(
                        if (canSubmit) colors.errorRed else colors.errorRed.copy(alpha = 0.3f),
                        RoundedCornerShape(16.dp)
                    )
                    .clickable(
                        enabled = canSubmit,
                        interactionSource = remember { MutableInteractionSource() },
                        indication = null
                    ) {
                        HapticService.mediumTap(haptic)
                        selectedCategory?.let { cat ->
                            ReportService.submitReport(
                                reporterUsername = currentUsername,
                                reportedUsername = userId,
                                category = cat.rawValue,
                                description = description,
                                includeConversation = includeConversation
                            )
                            isSubmitted = true
                        }
                    }
                    .padding(vertical = 16.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "\u041E\u0442\u043F\u0440\u0430\u0432\u0438\u0442\u044C \u0436\u0430\u043B\u043E\u0431\u0443",
                    style = MaterialTheme.typography.titleMedium,
                    color = Color.White,
                    fontWeight = FontWeight.Bold
                )
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
private fun ReportCategoryCard(
    category: ReportCategory,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val colors = FinderTheme.colors
    val icon = getCategoryIcon(category)

    val bgColor = if (isSelected) {
        category.color.copy(alpha = 0.15f)
    } else {
        colors.glassCardBackground
    }
    val borderColor = if (isSelected) {
        category.color.copy(alpha = 0.5f)
    } else {
        colors.glassBorder
    }

    Row(
        modifier = Modifier
            .background(bgColor, RoundedCornerShape(14.dp))
            .border(0.5.dp, borderColor, RoundedCornerShape(14.dp))
            .clickable(
                interactionSource = remember { MutableInteractionSource() },
                indication = null,
                onClick = onClick
            )
            .padding(horizontal = 14.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = category.color,
            modifier = Modifier.size(18.dp)
        )
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            text = category.ruName,
            style = MaterialTheme.typography.bodyMedium,
            color = if (isSelected) category.color else colors.textPrimary,
            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal
        )
    }
}

private fun getCategoryIcon(category: ReportCategory): ImageVector {
    return when (category) {
        ReportCategory.SPAM -> Icons.Filled.Mail
        ReportCategory.HARASSMENT -> Icons.Filled.FrontHand
        ReportCategory.INAPPROPRIATE_CONTENT -> Icons.Filled.VisibilityOff
        ReportCategory.SCAM -> Icons.Filled.CreditCardOff
        ReportCategory.FAKE_ACCOUNT -> Icons.Filled.PersonOff
        ReportCategory.VIOLENCE -> Icons.Filled.Warning
        ReportCategory.PUBLIC_SAFETY_THREAT -> Icons.Filled.Shield
        ReportCategory.OTHER -> Icons.Filled.MoreHoriz
    }
}
