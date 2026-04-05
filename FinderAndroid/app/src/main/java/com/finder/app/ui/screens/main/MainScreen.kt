package com.finder.app.ui.screens.main

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.selection.selectableGroup
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.ChatBubble
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.outlined.Call
import androidx.compose.material.icons.outlined.ChatBubbleOutline
import androidx.compose.material.icons.outlined.PersonOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.finder.app.models.CallRecord
import com.finder.app.models.Chat
import com.finder.app.ui.theme.FinderTheme
import java.util.UUID

data class MainTab(
    val title: String,
    val selectedIcon: ImageVector,
    val unselectedIcon: ImageVector,
    val badgeCount: Int = 0
)

@Composable
fun MainScreen(
    chats: List<Chat> = emptyList(),
    callHistory: List<CallRecord> = emptyList(),
    currentUserId: UUID = UUID.randomUUID(),
    onChatSelected: (Chat) -> Unit = {},
    onCreateChat: () -> Unit = {},
    onCallBack: (CallRecord) -> Unit = {},
    onEditProfile: () -> Unit = {},
    onOpenSettings: () -> Unit = {}
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current
    var selectedTab by remember { mutableIntStateOf(0) }

    val totalUnread = chats.sumOf { it.unreadCount }

    val tabs = remember(totalUnread) {
        listOf(
            MainTab(
                title = "Чаты",
                selectedIcon = Icons.Filled.ChatBubble,
                unselectedIcon = Icons.Outlined.ChatBubbleOutline,
                badgeCount = totalUnread
            ),
            MainTab(
                title = "Звонки",
                selectedIcon = Icons.Filled.Call,
                unselectedIcon = Icons.Outlined.Call
            ),
            MainTab(
                title = "Профиль",
                selectedIcon = Icons.Filled.Person,
                unselectedIcon = Icons.Outlined.PersonOutline
            )
        )
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        // Content area
        AnimatedContent(
            targetState = selectedTab,
            transitionSpec = {
                fadeIn(tween(200)) togetherWith fadeOut(tween(200))
            },
            modifier = Modifier.fillMaxSize(),
            label = "main_tab_content"
        ) { tab ->
            when (tab) {
                0 -> ChatListScreen(
                    chats = chats,
                    currentUserId = currentUserId,
                    onChatSelected = onChatSelected,
                    onCreateChat = onCreateChat
                )
                1 -> CallsScreen(
                    callHistory = callHistory,
                    onCallBack = onCallBack
                )
                2 -> ProfileScreen(
                    onEditProfile = onEditProfile,
                    onOpenSettings = onOpenSettings
                )
            }
        }

        // Glass tab bar at bottom
        Box(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .fillMaxWidth()
                .windowInsetsPadding(WindowInsets.navigationBars)
        ) {
            // Glass background layer
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(64.dp)
                    .blur(20.dp)
                    .background(colors.glassBackground)
            )

            // Tab bar content
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(64.dp)
                    .background(
                        brush = Brush.verticalGradient(
                            colors = listOf(
                                colors.glassCardBackground,
                                colors.glassBackground
                            )
                        )
                    )
                    .border(
                        width = 0.5.dp,
                        color = colors.glassBorder,
                        shape = RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp)
                    )
                    .clip(RoundedCornerShape(topStart = 20.dp, topEnd = 20.dp))
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxSize()
                        .selectableGroup(),
                    horizontalArrangement = Arrangement.SpaceEvenly,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    tabs.forEachIndexed { index, tab ->
                        GlassTabItem(
                            tab = tab,
                            isSelected = selectedTab == index,
                            onClick = {
                                if (selectedTab != index) {
                                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                    selectedTab = index
                                }
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun GlassTabItem(
    tab: MainTab,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val colors = FinderTheme.colors

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(2.dp),
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .clickable(
                onClick = onClick,
                indication = null,
                interactionSource = remember { MutableInteractionSource() }
            )
            .padding(horizontal = 20.dp, vertical = 6.dp)
    ) {
        Box {
            Icon(
                imageVector = if (isSelected) tab.selectedIcon else tab.unselectedIcon,
                contentDescription = tab.title,
                tint = if (isSelected) colors.accentBlue else colors.textTertiary,
                modifier = Modifier.size(24.dp)
            )

            // Unread badge
            if (tab.badgeCount > 0) {
                Box(
                    modifier = Modifier
                        .offset(x = 10.dp, y = (-4).dp)
                        .size(if (tab.badgeCount > 9) 20.dp else 16.dp)
                        .background(colors.errorRed, CircleShape)
                        .align(Alignment.TopEnd),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = if (tab.badgeCount > 99) "99+" else tab.badgeCount.toString(),
                        color = Color.White,
                        fontSize = 9.sp,
                        fontWeight = FontWeight.Bold,
                        textAlign = TextAlign.Center
                    )
                }
            }
        }

        Text(
            text = tab.title,
            style = MaterialTheme.typography.labelSmall,
            color = if (isSelected) colors.accentBlue else colors.textTertiary,
            fontWeight = if (isSelected) FontWeight.SemiBold else FontWeight.Normal
        )
    }
}

@Composable
fun ProfileScreen(
    onEditProfile: () -> Unit = {},
    onOpenSettings: () -> Unit = {}
) {
    val colors = FinderTheme.colors

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(bottom = 64.dp),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .background(colors.glassCardBackground, CircleShape)
                    .border(1.dp, colors.glassBorder, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Filled.Person,
                    contentDescription = null,
                    tint = colors.accentBlue,
                    modifier = Modifier.size(40.dp)
                )
            }

            Text(
                text = "Профиль",
                style = MaterialTheme.typography.headlineMedium,
                color = colors.textPrimary
            )

            Text(
                text = "Настройки профиля и аккаунта",
                style = MaterialTheme.typography.bodyMedium,
                color = colors.textSecondary
            )

            Row(
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                GlassActionButton(
                    text = "Редактировать",
                    onClick = onEditProfile
                )
                GlassActionButton(
                    text = "Настройки",
                    onClick = onOpenSettings
                )
            }
        }
    }
}

@Composable
private fun GlassActionButton(
    text: String,
    onClick: () -> Unit
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current

    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(12.dp))
            .background(colors.glassButtonBackground)
            .border(0.5.dp, colors.glassBorder, RoundedCornerShape(12.dp))
            .clickable(
                onClick = {
                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    onClick()
                },
                indication = null,
                interactionSource = remember { MutableInteractionSource() }
            )
            .padding(horizontal = 20.dp, vertical = 10.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelLarge,
            color = colors.accentBlue
        )
    }
}
