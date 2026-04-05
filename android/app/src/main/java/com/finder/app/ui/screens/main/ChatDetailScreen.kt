package com.finder.app.ui.screens.main

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.FastOutSlowInEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectHorizontalDragGestures
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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.ime
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBars
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Reply
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.Close
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.ScreenshotMonitor
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalConfiguration
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.finder.app.models.Chat
import com.finder.app.models.FinderUser
import com.finder.app.models.Message
import com.finder.app.models.MessageType
import com.finder.app.ui.theme.FinderTheme
import kotlinx.coroutines.delay
import java.text.SimpleDateFormat
import java.util.Locale
import java.util.UUID

@Composable
fun ChatDetailScreen(
    chat: Chat,
    currentUserId: UUID,
    messages: List<Message> = chat.messages,
    onBack: () -> Unit = {},
    onVoiceCall: () -> Unit = {},
    onVideoCall: () -> Unit = {},
    onSendMessage: (String) -> Unit = {},
    onSendVoice: () -> Unit = {},
    onAttach: () -> Unit = {},
    onReply: (Message) -> Unit = {},
    showScreenshotWarning: Boolean = false,
    onDismissScreenshotWarning: () -> Unit = {}
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current
    val listState = rememberLazyListState()
    var inputText by remember { mutableStateOf("") }
    var replyingTo by remember { mutableStateOf<Message?>(null) }
    val otherUser = chat.otherUser(currentUserId)

    val sortedMessages = remember(messages) {
        messages.sortedByDescending { it.timestamp }
    }

    // Scroll to bottom on new messages
    LaunchedEffect(messages.size) {
        if (sortedMessages.isNotEmpty()) {
            listState.animateScrollToItem(0)
        }
    }

    // Auto-dismiss screenshot warning
    var internalScreenshotWarning by remember { mutableStateOf(showScreenshotWarning) }
    LaunchedEffect(showScreenshotWarning) {
        internalScreenshotWarning = showScreenshotWarning
        if (showScreenshotWarning) {
            delay(5000)
            onDismissScreenshotWarning()
        }
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
        ) {
            // Encryption banner
            EncryptionBanner()

            // Top bar
            ChatTopBar(
                chat = chat,
                currentUserId = currentUserId,
                otherUser = otherUser,
                onBack = onBack,
                onVoiceCall = onVoiceCall,
                onVideoCall = onVideoCall
            )

            // Messages list
            LazyColumn(
                state = listState,
                reverseLayout = true,
                contentPadding = PaddingValues(horizontal = 12.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp),
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
            ) {
                items(
                    items = sortedMessages,
                    key = { it.id }
                ) { message ->
                    val isFromMe = message.isFromCurrentUser(currentUserId)
                    val sender = if (!isFromMe && (chat.isGroup || chat.isChannel)) {
                        chat.participants.find { it.id == message.senderId }
                    } else null

                    when (message.messageType) {
                        MessageType.SYSTEM -> SystemMessageBubble(message = message)
                        else -> MessageBubble(
                            message = message,
                            isFromMe = isFromMe,
                            sender = sender,
                            isGroup = chat.isGroup || chat.isChannel,
                            replyMessage = message.replyToId?.let { replyId ->
                                messages.find { it.id == replyId }
                            },
                            onSwipeToReply = {
                                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                replyingTo = message
                            },
                            onTapReply = {
                                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                replyingTo = message
                            }
                        )
                    }
                }
            }

            // Reply bar
            AnimatedVisibility(
                visible = replyingTo != null,
                enter = slideInVertically(initialOffsetY = { it }) + fadeIn(),
                exit = slideOutVertically(targetOffsetY = { it }) + fadeOut()
            ) {
                replyingTo?.let { msg ->
                    ReplyBar(
                        message = msg,
                        currentUserId = currentUserId,
                        participants = chat.participants,
                        onDismiss = { replyingTo = null }
                    )
                }
            }

            // Input bar
            ChatInputBar(
                text = inputText,
                onTextChange = { inputText = it },
                onSend = {
                    if (inputText.isNotBlank()) {
                        haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                        onSendMessage(inputText)
                        inputText = ""
                        replyingTo = null
                    }
                },
                onVoice = {
                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                    onSendVoice()
                },
                onAttach = {
                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                    onAttach()
                }
            )
        }

        // Screenshot warning overlay
        if (showScreenshotWarning) {
            ScreenshotWarningOverlay(onDismiss = onDismissScreenshotWarning)
        }
    }
}

@Composable
private fun EncryptionBanner() {
    val colors = FinderTheme.colors

    Row(
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.Center,
        modifier = Modifier
            .fillMaxWidth()
            .background(colors.glassBackground)
            .padding(vertical = 4.dp)
    ) {
        Icon(
            imageVector = Icons.Filled.Lock,
            contentDescription = null,
            tint = colors.accentCyan,
            modifier = Modifier.size(12.dp)
        )
        Spacer(modifier = Modifier.width(4.dp))
        Text(
            text = "Сквозное шифрование",
            style = MaterialTheme.typography.labelSmall,
            color = colors.accentCyan,
            fontSize = 10.sp
        )
    }
}

@Composable
private fun ChatTopBar(
    chat: Chat,
    currentUserId: UUID,
    otherUser: FinderUser?,
    onBack: () -> Unit,
    onVoiceCall: () -> Unit,
    onVideoCall: () -> Unit
) {
    val colors = FinderTheme.colors

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .background(colors.glassCardBackground)
            .border(
                width = 0.5.dp,
                color = colors.glassBorder,
                shape = RoundedCornerShape(0.dp)
            )
            .padding(horizontal = 4.dp, vertical = 8.dp)
    ) {
        IconButton(onClick = onBack) {
            Icon(
                imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                contentDescription = "Назад",
                tint = colors.accentBlue
            )
        }

        // Avatar
        AvatarView(
            user = otherUser,
            isSupport = chat.isSupport,
            isGroup = chat.isGroup || chat.isChannel,
            size = 40.dp
        )

        Spacer(modifier = Modifier.width(10.dp))

        // Name and status
        Column(modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = chat.displayName(currentUserId),
                    style = MaterialTheme.typography.titleMedium,
                    color = colors.textPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )

                if (otherUser?.isVerified == true || chat.isSupport) {
                    Spacer(modifier = Modifier.width(4.dp))
                    Icon(
                        imageVector = Icons.Filled.Verified,
                        contentDescription = "Верифицирован",
                        tint = colors.accentBlue,
                        modifier = Modifier.size(16.dp)
                    )
                }

                if (otherUser?.isUntrusted == true) {
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
                text = when {
                    otherUser?.isOnline == true -> "в сети"
                    chat.isGroup || chat.isChannel -> "${chat.participants.size} участников"
                    else -> "не в сети"
                },
                style = MaterialTheme.typography.labelSmall,
                color = if (otherUser?.isOnline == true) colors.onlineGreen else colors.textTertiary
            )
        }

        // Call buttons
        if (!chat.isChannel) {
            IconButton(onClick = onVoiceCall) {
                Icon(
                    imageVector = Icons.Filled.Call,
                    contentDescription = "Голосовой звонок",
                    tint = colors.accentBlue,
                    modifier = Modifier.size(22.dp)
                )
            }

            IconButton(onClick = onVideoCall) {
                Icon(
                    imageVector = Icons.Filled.Videocam,
                    contentDescription = "Видеозвонок",
                    tint = colors.accentBlue,
                    modifier = Modifier.size(22.dp)
                )
            }
        }
    }
}

@Composable
private fun MessageBubble(
    message: Message,
    isFromMe: Boolean,
    sender: FinderUser?,
    isGroup: Boolean,
    replyMessage: Message?,
    onSwipeToReply: () -> Unit,
    onTapReply: () -> Unit
) {
    val colors = FinderTheme.colors
    val screenWidth = LocalConfiguration.current.screenWidthDp.dp
    var swipeOffset by remember { mutableFloatStateOf(0f) }

    Column(
        horizontalAlignment = if (isFromMe) Alignment.End else Alignment.Start,
        modifier = Modifier
            .fillMaxWidth()
            .offset(x = swipeOffset.dp)
            .pointerInput(Unit) {
                detectHorizontalDragGestures(
                    onDragEnd = {
                        if (kotlin.math.abs(swipeOffset) > 40f) {
                            onSwipeToReply()
                        }
                        swipeOffset = 0f
                    },
                    onHorizontalDrag = { _, dragAmount ->
                        val newOffset = swipeOffset + dragAmount * 0.5f
                        swipeOffset = newOffset.coerceIn(-80f, 80f)
                    }
                )
            }
    ) {
        // Sender name for group chats
        if (!isFromMe && isGroup && sender != null) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.padding(start = 12.dp, bottom = 2.dp)
            ) {
                Text(
                    text = sender.displayName,
                    style = MaterialTheme.typography.labelSmall,
                    color = sender.avatarColor.color,
                    fontWeight = FontWeight.SemiBold
                )

                if (sender.isUntrusted) {
                    Spacer(modifier = Modifier.width(4.dp))
                    Icon(
                        imageVector = Icons.Filled.Warning,
                        contentDescription = "Не доверенный",
                        tint = colors.warningOrange,
                        modifier = Modifier.size(12.dp)
                    )
                }
            }
        }

        // Message bubble
        Column(
            modifier = Modifier
                .widthIn(max = screenWidth * 0.75f)
                .clip(
                    RoundedCornerShape(
                        topStart = 18.dp,
                        topEnd = 18.dp,
                        bottomStart = if (isFromMe) 18.dp else 4.dp,
                        bottomEnd = if (isFromMe) 4.dp else 18.dp
                    )
                )
                .background(
                    if (isFromMe) colors.accentBlue
                    else colors.glassCardBackground
                )
                .then(
                    if (!isFromMe) Modifier.border(
                        0.5.dp,
                        colors.glassBorder,
                        RoundedCornerShape(
                            topStart = 18.dp,
                            topEnd = 18.dp,
                            bottomStart = 4.dp,
                            bottomEnd = 18.dp
                        )
                    ) else Modifier
                )
                .clickable { onTapReply() }
                .padding(horizontal = 14.dp, vertical = 8.dp)
        ) {
            // Reply quote
            if (replyMessage != null) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(8.dp))
                        .background(
                            if (isFromMe) Color.White.copy(alpha = 0.15f)
                            else colors.glassBackground
                        )
                        .padding(8.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .width(3.dp)
                            .height(32.dp)
                            .background(
                                if (isFromMe) Color.White else colors.accentBlue,
                                RoundedCornerShape(2.dp)
                            )
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Column {
                        Text(
                            text = "Ответ",
                            style = MaterialTheme.typography.labelSmall,
                            color = if (isFromMe) Color.White.copy(alpha = 0.8f) else colors.accentBlue,
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = replyMessage.text,
                            style = MaterialTheme.typography.bodySmall,
                            color = if (isFromMe) Color.White.copy(alpha = 0.7f) else colors.textSecondary,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis
                        )
                    }
                }
                Spacer(modifier = Modifier.height(4.dp))
            }

            // Message text
            Text(
                text = message.text,
                style = MaterialTheme.typography.bodyMedium,
                color = if (isFromMe) Color.White else colors.textPrimary
            )

            // Timestamp and status
            Row(
                horizontalArrangement = Arrangement.End,
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 2.dp)
            ) {
                if (message.isEdited) {
                    Text(
                        text = "ред. ",
                        style = MaterialTheme.typography.labelSmall,
                        color = if (isFromMe) Color.White.copy(alpha = 0.5f) else colors.textTertiary,
                        fontSize = 9.sp
                    )
                }
                Text(
                    text = SimpleDateFormat("HH:mm", Locale.getDefault()).format(message.timestamp),
                    style = MaterialTheme.typography.labelSmall,
                    color = if (isFromMe) Color.White.copy(alpha = 0.6f) else colors.textTertiary,
                    fontSize = 10.sp
                )
                if (isFromMe) {
                    Spacer(modifier = Modifier.width(2.dp))
                    Text(
                        text = if (message.isRead) "\u2713\u2713" else "\u2713",
                        color = if (message.isRead) Color.White else Color.White.copy(alpha = 0.6f),
                        fontSize = 11.sp
                    )
                }
            }
        }
    }
}

@Composable
private fun SystemMessageBubble(message: Message) {
    val colors = FinderTheme.colors

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = message.text,
            style = MaterialTheme.typography.labelSmall,
            color = colors.textTertiary,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .clip(RoundedCornerShape(12.dp))
                .background(colors.glassBackground)
                .padding(horizontal = 16.dp, vertical = 6.dp)
        )
    }
}

@Composable
private fun ReplyBar(
    message: Message,
    currentUserId: UUID,
    participants: List<FinderUser>,
    onDismiss: () -> Unit
) {
    val colors = FinderTheme.colors
    val senderName = if (message.senderId == currentUserId) {
        "Вы"
    } else {
        participants.find { it.id == message.senderId }?.displayName ?: "Пользователь"
    }

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .background(colors.glassCardBackground)
            .border(0.5.dp, colors.glassBorder, RoundedCornerShape(0.dp))
            .padding(horizontal = 12.dp, vertical = 8.dp)
    ) {
        Icon(
            imageVector = Icons.AutoMirrored.Filled.Reply,
            contentDescription = null,
            tint = colors.accentBlue,
            modifier = Modifier.size(20.dp)
        )

        Spacer(modifier = Modifier.width(8.dp))

        Box(
            modifier = Modifier
                .width(3.dp)
                .height(32.dp)
                .background(colors.accentBlue, RoundedCornerShape(2.dp))
        )

        Spacer(modifier = Modifier.width(8.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = senderName,
                style = MaterialTheme.typography.labelSmall,
                color = colors.accentBlue,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                text = message.text,
                style = MaterialTheme.typography.bodySmall,
                color = colors.textSecondary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
        }

        IconButton(onClick = onDismiss, modifier = Modifier.size(32.dp)) {
            Icon(
                imageVector = Icons.Filled.Close,
                contentDescription = "Отменить ответ",
                tint = colors.textTertiary,
                modifier = Modifier.size(18.dp)
            )
        }
    }
}

@Composable
private fun ChatInputBar(
    text: String,
    onTextChange: (String) -> Unit,
    onSend: () -> Unit,
    onVoice: () -> Unit,
    onAttach: () -> Unit
) {
    val colors = FinderTheme.colors

    Row(
        verticalAlignment = Alignment.Bottom,
        modifier = Modifier
            .fillMaxWidth()
            .background(colors.glassCardBackground)
            .border(0.5.dp, colors.glassBorder, RoundedCornerShape(0.dp))
            .windowInsetsPadding(WindowInsets.navigationBars)
            .windowInsetsPadding(WindowInsets.ime)
            .padding(horizontal = 8.dp, vertical = 8.dp)
    ) {
        // Attach button
        IconButton(
            onClick = onAttach,
            modifier = Modifier.size(40.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.Add,
                contentDescription = "Прикрепить",
                tint = colors.accentBlue,
                modifier = Modifier.size(24.dp)
            )
        }

        // Text field
        BasicTextField(
            value = text,
            onValueChange = onTextChange,
            textStyle = MaterialTheme.typography.bodyMedium.copy(
                color = colors.textPrimary
            ),
            cursorBrush = SolidColor(colors.accentBlue),
            maxLines = 5,
            decorationBox = { innerTextField ->
                Box(
                    modifier = Modifier
                        .heightIn(min = 40.dp)
                        .clip(RoundedCornerShape(20.dp))
                        .background(colors.glassTextFieldBackground)
                        .border(0.5.dp, colors.glassBorder, RoundedCornerShape(20.dp))
                        .padding(horizontal = 16.dp, vertical = 10.dp),
                    contentAlignment = Alignment.CenterStart
                ) {
                    if (text.isEmpty()) {
                        Text(
                            text = "Сообщение...",
                            style = MaterialTheme.typography.bodyMedium,
                            color = colors.textTertiary
                        )
                    }
                    innerTextField()
                }
            },
            modifier = Modifier.weight(1f)
        )

        Spacer(modifier = Modifier.width(4.dp))

        // Send or voice button
        IconButton(
            onClick = {
                if (text.isNotBlank()) onSend() else onVoice()
            },
            modifier = Modifier
                .size(40.dp)
                .background(
                    if (text.isNotBlank()) colors.accentBlue else Color.Transparent,
                    CircleShape
                )
        ) {
            Icon(
                imageVector = if (text.isNotBlank()) Icons.AutoMirrored.Filled.Send else Icons.Filled.Mic,
                contentDescription = if (text.isNotBlank()) "Отправить" else "Голосовое сообщение",
                tint = if (text.isNotBlank()) Color.White else colors.accentBlue,
                modifier = Modifier.size(22.dp)
            )
        }
    }
}

@Composable
private fun ScreenshotWarningOverlay(onDismiss: () -> Unit) {
    val colors = FinderTheme.colors
    val infiniteTransition = rememberInfiniteTransition(label = "screenshot_pulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.08f,
        animationSpec = infiniteRepeatable(
            animation = tween(800, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulse_scale"
    )

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black.copy(alpha = 0.6f))
            .clickable(onClick = onDismiss),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            modifier = Modifier
                .scale(pulseScale)
                .padding(32.dp)
                .clip(RoundedCornerShape(24.dp))
                .background(
                    brush = Brush.verticalGradient(
                        colors = listOf(
                            colors.glassCardBackground,
                            colors.glassBackground
                        )
                    )
                )
                .border(1.dp, colors.errorRed.copy(alpha = 0.5f), RoundedCornerShape(24.dp))
                .padding(32.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.ScreenshotMonitor,
                contentDescription = null,
                tint = colors.errorRed,
                modifier = Modifier.size(48.dp)
            )

            Spacer(modifier = Modifier.height(16.dp))

            Text(
                text = "Скриншот обнаружен!",
                style = MaterialTheme.typography.headlineMedium,
                color = colors.errorRed,
                fontWeight = FontWeight.Bold,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Собеседник получил уведомление о том, что вы сделали скриншот этого чата.",
                style = MaterialTheme.typography.bodyMedium,
                color = colors.textSecondary,
                textAlign = TextAlign.Center
            )

            Spacer(modifier = Modifier.height(20.dp))

            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(12.dp))
                    .background(colors.errorRed)
                    .clickable(onClick = onDismiss)
                    .padding(horizontal = 32.dp, vertical = 12.dp),
                contentAlignment = Alignment.Center
            ) {
                Text(
                    text = "Понятно",
                    style = MaterialTheme.typography.labelLarge,
                    color = Color.White,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }
}
