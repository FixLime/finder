package com.finder.app.ui.screens.main

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
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
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Archive
import androidx.compose.material.icons.filled.ChatBubble
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.DoneAll
import androidx.compose.material.icons.filled.HeadsetMic
import androidx.compose.material.icons.filled.NotificationsOff
import androidx.compose.material.icons.filled.NotificationsActive
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PushPin
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.DpOffset
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.finder.app.models.Chat
import com.finder.app.models.FinderUser
import com.finder.app.ui.theme.FinderTheme
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.UUID

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ChatListScreen(
    chats: List<Chat> = emptyList(),
    currentUserId: UUID = UUID.randomUUID(),
    onChatSelected: (Chat) -> Unit = {},
    onCreateChat: () -> Unit = {},
    onPinChat: (Chat) -> Unit = {},
    onMuteChat: (Chat) -> Unit = {},
    onMarkRead: (Chat) -> Unit = {},
    onArchiveChat: (Chat) -> Unit = {},
    onDeleteChat: (Chat) -> Unit = {}
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current
    var searchQuery by remember { mutableStateOf("") }

    val filteredChats by remember(chats, searchQuery) {
        derivedStateOf {
            if (searchQuery.isBlank()) chats
            else chats.filter {
                it.displayName(currentUserId).contains(searchQuery, ignoreCase = true) ||
                    (it.lastMessage?.text?.contains(searchQuery, ignoreCase = true) == true)
            }
        }
    }

    val pinnedChats by remember(filteredChats) {
        derivedStateOf { filteredChats.filter { it.isPinned && !it.isArchived } }
    }

    val regularChats by remember(filteredChats) {
        derivedStateOf { filteredChats.filter { !it.isPinned && !it.isArchived } }
    }

    // Always show support chat
    val supportChat by remember(filteredChats) {
        derivedStateOf { filteredChats.find { it.isSupport } }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .windowInsetsPadding(WindowInsets.statusBars)
                .padding(bottom = 64.dp)
        ) {
            // Header
            Text(
                text = "Чаты",
                style = MaterialTheme.typography.displayMedium,
                color = colors.textPrimary,
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
            )

            // Glass search bar
            GlassSearchBar(
                query = searchQuery,
                onQueryChange = { searchQuery = it },
                placeholder = "Поиск чатов...",
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp)
            )

            Spacer(modifier = Modifier.height(8.dp))

            if (filteredChats.isEmpty() && searchQuery.isBlank()) {
                // Empty state
                EmptyChatsState(
                    modifier = Modifier
                        .fillMaxSize()
                        .weight(1f)
                )
            } else {
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(vertical = 8.dp)
                ) {
                    // Pinned section
                    if (pinnedChats.isNotEmpty()) {
                        item {
                            SectionHeader(title = "Закреплённые")
                        }
                        items(
                            items = pinnedChats,
                            key = { it.id }
                        ) { chat ->
                            ChatListItem(
                                chat = chat,
                                currentUserId = currentUserId,
                                onClick = {
                                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                    onChatSelected(chat)
                                },
                                onPin = { onPinChat(chat) },
                                onMute = { onMuteChat(chat) },
                                onMarkRead = { onMarkRead(chat) },
                                onArchive = { onArchiveChat(chat) },
                                onDelete = { onDeleteChat(chat) },
                                modifier = Modifier.animateItemPlacement()
                            )
                        }
                    }

                    // Support chat (always visible)
                    if (supportChat != null && !pinnedChats.contains(supportChat)) {
                        item {
                            SectionHeader(title = "Поддержка")
                        }
                        item {
                            supportChat?.let { chat ->
                                ChatListItem(
                                    chat = chat,
                                    currentUserId = currentUserId,
                                    onClick = {
                                        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                        onChatSelected(chat)
                                    },
                                    onPin = { onPinChat(chat) },
                                    onMute = { onMuteChat(chat) },
                                    onMarkRead = { onMarkRead(chat) },
                                    onArchive = { onArchiveChat(chat) },
                                    onDelete = { onDeleteChat(chat) }
                                )
                            }
                        }
                    }

                    // Regular chats
                    if (regularChats.isNotEmpty()) {
                        if (pinnedChats.isNotEmpty()) {
                            item {
                                SectionHeader(title = "Все чаты")
                            }
                        }
                        items(
                            items = regularChats.filter { it.id != supportChat?.id },
                            key = { it.id }
                        ) { chat ->
                            ChatListItem(
                                chat = chat,
                                currentUserId = currentUserId,
                                onClick = {
                                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                    onChatSelected(chat)
                                },
                                onPin = { onPinChat(chat) },
                                onMute = { onMuteChat(chat) },
                                onMarkRead = { onMarkRead(chat) },
                                onArchive = { onArchiveChat(chat) },
                                onDelete = { onDeleteChat(chat) },
                                modifier = Modifier.animateItemPlacement()
                            )
                        }
                    }
                }
            }
        }

        // FAB
        FloatingActionButton(
            onClick = {
                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                onCreateChat()
            },
            containerColor = colors.accentBlue,
            contentColor = Color.White,
            shape = CircleShape,
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(end = 16.dp, bottom = 80.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.Add,
                contentDescription = "Новый чат"
            )
        }
    }
}

@Composable
fun GlassSearchBar(
    query: String,
    onQueryChange: (String) -> Unit,
    placeholder: String,
    modifier: Modifier = Modifier
) {
    val colors = FinderTheme.colors

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = modifier
            .height(44.dp)
            .clip(RoundedCornerShape(14.dp))
            .background(colors.glassTextFieldBackground)
            .border(0.5.dp, colors.glassBorder, RoundedCornerShape(14.dp))
            .padding(horizontal = 12.dp)
    ) {
        Icon(
            imageVector = Icons.Filled.Search,
            contentDescription = null,
            tint = colors.textTertiary,
            modifier = Modifier.size(20.dp)
        )

        Spacer(modifier = Modifier.width(8.dp))

        BasicTextField(
            value = query,
            onValueChange = onQueryChange,
            singleLine = true,
            textStyle = MaterialTheme.typography.bodyMedium.copy(
                color = colors.textPrimary
            ),
            cursorBrush = SolidColor(colors.accentBlue),
            decorationBox = { innerTextField ->
                Box(modifier = Modifier.fillMaxWidth()) {
                    if (query.isEmpty()) {
                        Text(
                            text = placeholder,
                            style = MaterialTheme.typography.bodyMedium,
                            color = colors.textTertiary
                        )
                    }
                    innerTextField()
                }
            },
            modifier = Modifier.weight(1f)
        )
    }
}

@Composable
private fun SectionHeader(title: String) {
    val colors = FinderTheme.colors

    Text(
        text = title.uppercase(),
        style = MaterialTheme.typography.labelMedium,
        color = colors.textTertiary,
        letterSpacing = 1.sp,
        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
    )
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun ChatListItem(
    chat: Chat,
    currentUserId: UUID,
    onClick: () -> Unit,
    onPin: () -> Unit,
    onMute: () -> Unit,
    onMarkRead: () -> Unit,
    onArchive: () -> Unit,
    onDelete: () -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current
    var showContextMenu by remember { mutableStateOf(false) }

    val displayName = chat.displayName(currentUserId)
    val otherUser = chat.otherUser(currentUserId)
    val lastMessage = chat.lastMessage
    val isVerified = otherUser?.isVerified == true || chat.isSupport
    val isUntrusted = otherUser?.isUntrusted == true

    Box(modifier = modifier) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .fillMaxWidth()
                .combinedClickable(
                    onClick = onClick,
                    onLongClick = {
                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        showContextMenu = true
                    }
                )
                .padding(horizontal = 16.dp, vertical = 10.dp)
        ) {
            // Avatar
            AvatarView(
                user = otherUser,
                isSupport = chat.isSupport,
                isGroup = chat.isGroup || chat.isChannel,
                size = 52.dp
            )

            Spacer(modifier = Modifier.width(12.dp))

            // Chat info
            Column(
                modifier = Modifier.weight(1f)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    // Name with badges
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        modifier = Modifier.weight(1f)
                    ) {
                        Text(
                            text = displayName,
                            style = MaterialTheme.typography.titleMedium,
                            color = colors.textPrimary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                            fontWeight = if (chat.unreadCount > 0) FontWeight.Bold else FontWeight.Medium
                        )

                        if (isVerified) {
                            Spacer(modifier = Modifier.width(4.dp))
                            Icon(
                                imageVector = Icons.Filled.Verified,
                                contentDescription = "Верифицирован",
                                tint = colors.accentBlue,
                                modifier = Modifier.size(16.dp)
                            )
                        }

                        if (isUntrusted) {
                            Spacer(modifier = Modifier.width(4.dp))
                            Icon(
                                imageVector = Icons.Filled.Warning,
                                contentDescription = "Не доверенный",
                                tint = colors.warningOrange,
                                modifier = Modifier.size(16.dp)
                            )
                        }

                        if (chat.isMuted) {
                            Spacer(modifier = Modifier.width(4.dp))
                            Icon(
                                imageVector = Icons.Filled.NotificationsOff,
                                contentDescription = "Без звука",
                                tint = colors.textTertiary,
                                modifier = Modifier.size(14.dp)
                            )
                        }
                    }

                    // Timestamp
                    if (lastMessage != null) {
                        Text(
                            text = formatChatTimestamp(lastMessage.timestamp),
                            style = MaterialTheme.typography.labelSmall,
                            color = if (chat.unreadCount > 0) colors.accentBlue else colors.textTertiary
                        )
                    }
                }

                Spacer(modifier = Modifier.height(2.dp))

                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    modifier = Modifier.fillMaxWidth()
                ) {
                    // Last message preview
                    Text(
                        text = lastMessage?.text ?: "Нет сообщений",
                        style = MaterialTheme.typography.bodyMedium,
                        color = if (chat.unreadCount > 0) colors.textSecondary else colors.textTertiary,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                        modifier = Modifier.weight(1f)
                    )

                    // Unread badge
                    if (chat.unreadCount > 0) {
                        Spacer(modifier = Modifier.width(8.dp))
                        Box(
                            modifier = Modifier
                                .size(if (chat.unreadCount > 9) 24.dp else 20.dp)
                                .background(colors.accentBlue, CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = if (chat.unreadCount > 99) "99+" else chat.unreadCount.toString(),
                                color = Color.White,
                                fontSize = 10.sp,
                                fontWeight = FontWeight.Bold,
                                textAlign = TextAlign.Center
                            )
                        }
                    }

                    // Pin indicator
                    if (chat.isPinned) {
                        Spacer(modifier = Modifier.width(4.dp))
                        Icon(
                            imageVector = Icons.Filled.PushPin,
                            contentDescription = null,
                            tint = colors.textTertiary,
                            modifier = Modifier.size(14.dp)
                        )
                    }
                }
            }
        }

        // Context menu
        DropdownMenu(
            expanded = showContextMenu,
            onDismissRequest = { showContextMenu = false },
            offset = DpOffset(60.dp, 0.dp)
        ) {
            DropdownMenuItem(
                text = { Text(if (chat.isPinned) "Открепить" else "Закрепить") },
                onClick = {
                    showContextMenu = false
                    onPin()
                },
                leadingIcon = {
                    Icon(Icons.Filled.PushPin, contentDescription = null)
                }
            )
            DropdownMenuItem(
                text = { Text(if (chat.isMuted) "Включить звук" else "Без звука") },
                onClick = {
                    showContextMenu = false
                    onMute()
                },
                leadingIcon = {
                    Icon(
                        if (chat.isMuted) Icons.Filled.NotificationsActive else Icons.Filled.NotificationsOff,
                        contentDescription = null
                    )
                }
            )
            if (chat.unreadCount > 0) {
                DropdownMenuItem(
                    text = { Text("Прочитано") },
                    onClick = {
                        showContextMenu = false
                        onMarkRead()
                    },
                    leadingIcon = {
                        Icon(Icons.Filled.DoneAll, contentDescription = null)
                    }
                )
            }
            DropdownMenuItem(
                text = { Text("Архивировать") },
                onClick = {
                    showContextMenu = false
                    onArchive()
                },
                leadingIcon = {
                    Icon(Icons.Filled.Archive, contentDescription = null)
                }
            )
            DropdownMenuItem(
                text = {
                    Text(
                        "Удалить",
                        color = FinderTheme.colors.errorRed
                    )
                },
                onClick = {
                    showContextMenu = false
                    onDelete()
                },
                leadingIcon = {
                    Icon(
                        Icons.Filled.Delete,
                        contentDescription = null,
                        tint = FinderTheme.colors.errorRed
                    )
                }
            )
        }
    }
}

@Composable
fun AvatarView(
    user: FinderUser?,
    isSupport: Boolean = false,
    isGroup: Boolean = false,
    size: androidx.compose.ui.unit.Dp = 48.dp,
    showOnlineIndicator: Boolean = true
) {
    val colors = FinderTheme.colors

    Box(modifier = Modifier.size(size)) {
        Box(
            modifier = Modifier
                .size(size)
                .clip(CircleShape)
                .background(
                    when {
                        isSupport -> colors.accentBlue
                        user != null -> user.avatarColor.color
                        isGroup -> colors.accentPurple
                        else -> colors.glassCardBackground
                    }
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = when {
                    isSupport -> Icons.Filled.HeadsetMic
                    isGroup -> Icons.Filled.Person
                    else -> Icons.Filled.Person
                },
                contentDescription = null,
                tint = Color.White.copy(alpha = 0.9f),
                modifier = Modifier.size(size * 0.5f)
            )
        }

        // Online indicator
        if (showOnlineIndicator && user?.isOnline == true && !isSupport) {
            Box(
                modifier = Modifier
                    .size(size * 0.25f)
                    .align(Alignment.BottomEnd)
                    .background(MaterialTheme.colorScheme.background, CircleShape)
                    .padding(2.dp)
                    .background(colors.onlineGreen, CircleShape)
            )
        }
    }
}

@Composable
private fun EmptyChatsState(modifier: Modifier = Modifier) {
    val colors = FinderTheme.colors

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center,
        modifier = modifier.padding(32.dp)
    ) {
        Box(
            modifier = Modifier
                .size(80.dp)
                .clip(CircleShape)
                .background(colors.glassCardBackground)
                .border(0.5.dp, colors.glassBorder, CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Filled.ChatBubble,
                contentDescription = null,
                tint = colors.textTertiary,
                modifier = Modifier.size(36.dp)
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Нет чатов",
            style = MaterialTheme.typography.headlineMedium,
            color = colors.textPrimary
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "Начните общение, нажав на кнопку +",
            style = MaterialTheme.typography.bodyMedium,
            color = colors.textSecondary,
            textAlign = TextAlign.Center
        )
    }
}

private fun formatChatTimestamp(date: Date): String {
    val now = Calendar.getInstance()
    val msgCal = Calendar.getInstance().apply { time = date }

    return when {
        now.get(Calendar.DATE) == msgCal.get(Calendar.DATE) &&
            now.get(Calendar.MONTH) == msgCal.get(Calendar.MONTH) &&
            now.get(Calendar.YEAR) == msgCal.get(Calendar.YEAR) -> {
            SimpleDateFormat("HH:mm", Locale.getDefault()).format(date)
        }
        now.get(Calendar.DATE) - msgCal.get(Calendar.DATE) == 1 &&
            now.get(Calendar.MONTH) == msgCal.get(Calendar.MONTH) &&
            now.get(Calendar.YEAR) == msgCal.get(Calendar.YEAR) -> {
            "Вчера"
        }
        now.get(Calendar.YEAR) == msgCal.get(Calendar.YEAR) -> {
            SimpleDateFormat("d MMM", Locale("ru")).format(date)
        }
        else -> {
            SimpleDateFormat("dd.MM.yy", Locale.getDefault()).format(date)
        }
    }
}
