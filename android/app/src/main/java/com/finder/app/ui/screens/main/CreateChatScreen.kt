package com.finder.app.ui.screens.main

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
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
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.Campaign
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PersonAdd
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.TabRowDefaults
import androidx.compose.material3.TabRowDefaults.tabIndicatorOffset
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.derivedStateOf
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateListOf
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.finder.app.models.FinderUser
import com.finder.app.ui.theme.FinderTheme

data class CreateChatTab(
    val title: String,
    val icon: ImageVector
)

@Composable
fun CreateChatScreen(
    users: List<FinderUser> = emptyList(),
    onBack: () -> Unit = {},
    onStartChat: (FinderUser) -> Unit = {},
    onCreateGroup: (String, List<FinderUser>) -> Unit = { _, _ -> },
    onCreateChannel: (String, String) -> Unit = { _, _ -> }
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current
    var selectedTab by remember { mutableIntStateOf(0) }
    var searchQuery by remember { mutableStateOf("") }

    val tabs = remember {
        listOf(
            CreateChatTab("Новый чат", Icons.Filled.PersonAdd),
            CreateChatTab("Группа", Icons.Filled.Group),
            CreateChatTab("Канал", Icons.Filled.Campaign)
        )
    }

    val filteredUsers by remember(users, searchQuery) {
        derivedStateOf {
            if (searchQuery.isBlank()) users
            else users.filter {
                it.displayName.contains(searchQuery, ignoreCase = true) ||
                    it.username.contains(searchQuery, ignoreCase = true)
            }
        }
    }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .windowInsetsPadding(WindowInsets.statusBars)
    ) {
        // Top bar
        Row(
            verticalAlignment = Alignment.CenterVertically,
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 4.dp, vertical = 8.dp)
        ) {
            IconButton(onClick = onBack) {
                Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Назад",
                    tint = colors.accentBlue
                )
            }

            Text(
                text = "Создать",
                style = MaterialTheme.typography.headlineMedium,
                color = colors.textPrimary,
                modifier = Modifier.weight(1f)
            )
        }

        // Tab row
        TabRow(
            selectedTabIndex = selectedTab,
            containerColor = Color.Transparent,
            contentColor = colors.accentBlue,
            indicator = { tabPositions ->
                TabRowDefaults.SecondaryIndicator(
                    modifier = Modifier.tabIndicatorOffset(tabPositions[selectedTab]),
                    color = colors.accentBlue,
                    height = 2.dp
                )
            },
            divider = {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(0.5.dp)
                        .background(colors.glassBorder)
                )
            }
        ) {
            tabs.forEachIndexed { index, tab ->
                Tab(
                    selected = selectedTab == index,
                    onClick = {
                        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                        selectedTab = index
                    },
                    text = {
                        Text(
                            text = tab.title,
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = if (selectedTab == index) FontWeight.SemiBold else FontWeight.Normal
                        )
                    },
                    icon = {
                        Icon(
                            imageVector = tab.icon,
                            contentDescription = null,
                            modifier = Modifier.size(20.dp)
                        )
                    },
                    selectedContentColor = colors.accentBlue,
                    unselectedContentColor = colors.textTertiary
                )
            }
        }

        // Content
        when (selectedTab) {
            0 -> NewChatTab(
                users = filteredUsers,
                searchQuery = searchQuery,
                onSearchChange = { searchQuery = it },
                onUserSelected = { user ->
                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    onStartChat(user)
                }
            )
            1 -> CreateGroupTab(
                users = filteredUsers,
                searchQuery = searchQuery,
                onSearchChange = { searchQuery = it },
                onCreateGroup = { name, members ->
                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                    onCreateGroup(name, members)
                }
            )
            2 -> CreateChannelTab(
                onCreateChannel = { name, description ->
                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                    onCreateChannel(name, description)
                }
            )
        }
    }
}

@Composable
private fun NewChatTab(
    users: List<FinderUser>,
    searchQuery: String,
    onSearchChange: (String) -> Unit,
    onUserSelected: (FinderUser) -> Unit
) {
    Column(modifier = Modifier.fillMaxSize()) {
        Spacer(modifier = Modifier.height(12.dp))

        GlassSearchBar(
            query = searchQuery,
            onQueryChange = onSearchChange,
            placeholder = "Поиск пользователей...",
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
        )

        Spacer(modifier = Modifier.height(8.dp))

        LazyColumn(
            contentPadding = PaddingValues(vertical = 4.dp)
        ) {
            items(
                items = users,
                key = { it.id }
            ) { user ->
                UserListItem(
                    user = user,
                    onClick = { onUserSelected(user) }
                )
            }

            if (users.isEmpty()) {
                item {
                    EmptySearchState(query = searchQuery)
                }
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun CreateGroupTab(
    users: List<FinderUser>,
    searchQuery: String,
    onSearchChange: (String) -> Unit,
    onCreateGroup: (String, List<FinderUser>) -> Unit
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current
    var groupName by remember { mutableStateOf("") }
    val selectedUsers = remember { mutableStateListOf<FinderUser>() }

    Column(modifier = Modifier.fillMaxSize()) {
        Spacer(modifier = Modifier.height(12.dp))

        // Group name input
        GlassTextField(
            value = groupName,
            onValueChange = { groupName = it },
            placeholder = "Название группы",
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
        )

        // Selected users chips
        if (selectedUsers.isNotEmpty()) {
            Spacer(modifier = Modifier.height(8.dp))
            FlowRow(
                horizontalArrangement = Arrangement.spacedBy(6.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp),
                modifier = Modifier.padding(horizontal = 16.dp)
            ) {
                selectedUsers.forEach { user ->
                    UserChip(
                        user = user,
                        onRemove = {
                            haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                            selectedUsers.remove(user)
                        }
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Create button
        if (groupName.isNotBlank() && selectedUsers.size >= 2) {
            CreateButton(
                text = "Создать группу (${selectedUsers.size})",
                onClick = { onCreateGroup(groupName, selectedUsers.toList()) },
                modifier = Modifier.padding(horizontal = 16.dp)
            )
            Spacer(modifier = Modifier.height(8.dp))
        }

        // Search
        GlassSearchBar(
            query = searchQuery,
            onQueryChange = onSearchChange,
            placeholder = "Добавить участников...",
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp)
        )

        Spacer(modifier = Modifier.height(8.dp))

        // User list with selection
        LazyColumn(
            contentPadding = PaddingValues(vertical = 4.dp)
        ) {
            items(
                items = users,
                key = { it.id }
            ) { user ->
                val isSelected = selectedUsers.contains(user)
                UserListItem(
                    user = user,
                    isSelected = isSelected,
                    onClick = {
                        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                        if (isSelected) selectedUsers.remove(user)
                        else selectedUsers.add(user)
                    }
                )
            }
        }
    }
}

@Composable
private fun CreateChannelTab(
    onCreateChannel: (String, String) -> Unit
) {
    val colors = FinderTheme.colors
    var channelName by remember { mutableStateOf("") }
    var channelDescription by remember { mutableStateOf("") }

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        Spacer(modifier = Modifier.height(12.dp))

        // Channel icon placeholder
        Box(
            modifier = Modifier
                .size(80.dp)
                .clip(CircleShape)
                .background(colors.glassCardBackground)
                .border(1.dp, colors.glassBorder, CircleShape)
                .align(Alignment.CenterHorizontally),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = Icons.Filled.Campaign,
                contentDescription = null,
                tint = colors.accentPurple,
                modifier = Modifier.size(36.dp)
            )
        }

        Spacer(modifier = Modifier.height(20.dp))

        GlassTextField(
            value = channelName,
            onValueChange = { channelName = it },
            placeholder = "Название канала"
        )

        Spacer(modifier = Modifier.height(12.dp))

        GlassTextField(
            value = channelDescription,
            onValueChange = { channelDescription = it },
            placeholder = "Описание канала (необязательно)",
            singleLine = false,
            minHeight = 80.dp
        )

        Spacer(modifier = Modifier.height(16.dp))

        if (channelName.isNotBlank()) {
            CreateButton(
                text = "Создать канал",
                onClick = { onCreateChannel(channelName, channelDescription) }
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Каналы -- это инструмент для трансляции сообщений большой аудитории. Только администраторы могут писать в канал.",
            style = MaterialTheme.typography.bodySmall,
            color = colors.textTertiary
        )
    }
}

@Composable
private fun UserListItem(
    user: FinderUser,
    isSelected: Boolean = false,
    onClick: () -> Unit
) {
    val colors = FinderTheme.colors

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .background(
                if (isSelected) colors.accentBlue.copy(alpha = 0.1f) else Color.Transparent
            )
            .padding(horizontal = 16.dp, vertical = 10.dp)
    ) {
        // Avatar
        AvatarView(
            user = user,
            size = 44.dp
        )

        Spacer(modifier = Modifier.width(12.dp))

        // User info
        Column(modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = user.displayName,
                    style = MaterialTheme.typography.titleMedium,
                    color = colors.textPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                if (user.isVerified) {
                    Spacer(modifier = Modifier.width(4.dp))
                    Icon(
                        imageVector = Icons.Filled.Verified,
                        contentDescription = "Верифицирован",
                        tint = colors.accentBlue,
                        modifier = Modifier.size(16.dp)
                    )
                }

                if (user.isUntrusted) {
                    Spacer(modifier = Modifier.width(4.dp))
                    Icon(
                        imageVector = Icons.Filled.Warning,
                        contentDescription = "Не доверенный",
                        tint = colors.warningOrange,
                        modifier = Modifier.size(16.dp)
                    )
                }
            }

            Text(
                text = "@${user.username}",
                style = MaterialTheme.typography.bodySmall,
                color = colors.textTertiary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }

        // Selection checkmark
        if (isSelected) {
            Box(
                modifier = Modifier
                    .size(24.dp)
                    .background(colors.accentBlue, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Filled.Check,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(16.dp)
                )
            }
        }
    }
}

@Composable
private fun UserChip(
    user: FinderUser,
    onRemove: () -> Unit
) {
    val colors = FinderTheme.colors

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .clip(RoundedCornerShape(20.dp))
            .background(colors.accentBlue.copy(alpha = 0.15f))
            .border(0.5.dp, colors.accentBlue.copy(alpha = 0.3f), RoundedCornerShape(20.dp))
            .padding(start = 4.dp, end = 8.dp, top = 4.dp, bottom = 4.dp)
    ) {
        AvatarView(
            user = user,
            size = 24.dp,
            showOnlineIndicator = false
        )

        Spacer(modifier = Modifier.width(6.dp))

        Text(
            text = user.displayName,
            style = MaterialTheme.typography.labelMedium,
            color = colors.accentBlue,
            maxLines = 1
        )

        Spacer(modifier = Modifier.width(4.dp))

        Icon(
            imageVector = Icons.Filled.Close,
            contentDescription = "Удалить",
            tint = colors.accentBlue,
            modifier = Modifier
                .size(16.dp)
                .clickable(onClick = onRemove)
        )
    }
}

@Composable
fun GlassTextField(
    value: String,
    onValueChange: (String) -> Unit,
    placeholder: String,
    modifier: Modifier = Modifier,
    singleLine: Boolean = true,
    minHeight: androidx.compose.ui.unit.Dp = 44.dp
) {
    val colors = FinderTheme.colors

    BasicTextField(
        value = value,
        onValueChange = onValueChange,
        singleLine = singleLine,
        textStyle = MaterialTheme.typography.bodyMedium.copy(
            color = colors.textPrimary
        ),
        cursorBrush = SolidColor(colors.accentBlue),
        decorationBox = { innerTextField ->
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(minHeight)
                    .clip(RoundedCornerShape(14.dp))
                    .background(colors.glassTextFieldBackground)
                    .border(0.5.dp, colors.glassBorder, RoundedCornerShape(14.dp))
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                contentAlignment = if (singleLine) Alignment.CenterStart else Alignment.TopStart
            ) {
                if (value.isEmpty()) {
                    Text(
                        text = placeholder,
                        style = MaterialTheme.typography.bodyMedium,
                        color = colors.textTertiary
                    )
                }
                innerTextField()
            }
        },
        modifier = modifier
    )
}

@Composable
private fun CreateButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current

    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(colors.accentBlue)
            .clickable {
                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                onClick()
            }
            .padding(vertical = 14.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.titleMedium,
            color = Color.White,
            fontWeight = FontWeight.SemiBold
        )
    }
}

@Composable
private fun EmptySearchState(query: String) {
    val colors = FinderTheme.colors

    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier
            .fillMaxWidth()
            .padding(32.dp)
    ) {
        Icon(
            imageVector = Icons.Filled.Person,
            contentDescription = null,
            tint = colors.textTertiary,
            modifier = Modifier.size(48.dp)
        )

        Spacer(modifier = Modifier.height(12.dp))

        Text(
            text = if (query.isBlank()) "Нет пользователей" else "Никого не найдено",
            style = MaterialTheme.typography.titleMedium,
            color = colors.textSecondary
        )

        if (query.isNotBlank()) {
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = "Попробуйте другой запрос",
                style = MaterialTheme.typography.bodySmall,
                color = colors.textTertiary
            )
        }
    }
}
