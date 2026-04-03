package com.finder.app.ui.chat

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Send
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.finder.app.models.Chat
import com.finder.app.models.Message
import com.finder.app.services.ApiService
import com.finder.app.services.WebSocketService
import kotlinx.coroutines.launch
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ChatScreen(
    chat: Chat,
    onBack: () -> Unit,
    onCall: (Boolean) -> Unit // isVideo
) {
    var messageText by remember { mutableStateOf("") }
    var messages by remember { mutableStateOf(chat.messages.toList()) }
    val listState = rememberLazyListState()
    val currentUserId = ApiService.currentUserId ?: ""
    val scope = rememberCoroutineScope()

    // Listen for new messages
    LaunchedEffect(chat.id) {
        // Load messages from server
        try {
            val serverMessages = ApiService.getMessages(chat.id)
            messages = serverMessages.map { it.toMessage() }
        } catch (_: Exception) {}

        // Listen for real-time messages
        WebSocketService.messageReceived.collect { serverMsg ->
            if (serverMsg.chatId == chat.id) {
                val msg = serverMsg.toMessage()
                messages = messages + msg
                // Mark as read
                WebSocketService.sendRead(chat.id, msg.id)
            }
        }
    }

    // Auto-scroll to bottom on new messages
    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) {
            listState.animateScrollToItem(messages.size - 1)
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(verticalAlignment = Alignment.CenterVertically) {
                        Box(
                            modifier = Modifier
                                .size(36.dp)
                                .clip(CircleShape)
                                .background(Color(0xFF2196F3)),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                text = chat.displayName.take(1).uppercase(),
                                color = Color.White,
                                fontWeight = FontWeight.Bold,
                                fontSize = 14.sp
                            )
                        }
                        Spacer(modifier = Modifier.width(10.dp))
                        Column {
                            Text(
                                text = chat.displayName,
                                fontWeight = FontWeight.SemiBold,
                                fontSize = 16.sp
                            )
                            val otherUser = chat.otherUser
                            if (otherUser != null) {
                                Text(
                                    text = if (otherUser.isOnline) "в сети" else "не в сети",
                                    fontSize = 12.sp,
                                    color = if (otherUser.isOnline) Color(0xFF4CAF50) else Color.Gray
                                )
                            }
                        }
                    }
                },
                navigationIcon = {
                    IconButton(onClick = onBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Назад")
                    }
                },
                actions = {
                    IconButton(onClick = { onCall(false) }) {
                        Icon(Icons.Default.Call, contentDescription = "Аудиозвонок")
                    }
                    IconButton(onClick = { onCall(true) }) {
                        Icon(Icons.Default.Videocam, contentDescription = "Видеозвонок")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            // Messages
            LazyColumn(
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth()
                    .padding(horizontal = 8.dp),
                state = listState
            ) {
                items(messages.sortedBy { it.timestamp }) { message ->
                    MessageBubble(
                        message = message,
                        isFromCurrentUser = message.isFromCurrentUser(currentUserId)
                    )
                }
            }

            // Input
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                OutlinedTextField(
                    value = messageText,
                    onValueChange = {
                        messageText = it
                        WebSocketService.sendTyping(chat.id)
                    },
                    placeholder = { Text("Сообщение...") },
                    shape = RoundedCornerShape(24.dp),
                    modifier = Modifier.weight(1f),
                    maxLines = 4
                )

                Spacer(modifier = Modifier.width(8.dp))

                FloatingActionButton(
                    onClick = {
                        val text = messageText.trim()
                        if (text.isNotEmpty()) {
                            val chatId = chat.id
                            messageText = ""
                            // Send via WebSocket
                            WebSocketService.sendMessage(chatId, text)
                            // Also send via REST API for persistence
                            scope.launch {
                                try {
                                    ApiService.sendMessage(chatId, text)
                                } catch (_: Exception) {}
                            }
                            // Add locally
                            val msg = Message(
                                id = UUID.randomUUID().toString(),
                                chatId = chatId,
                                senderId = currentUserId,
                                text = text
                            )
                            messages = messages + msg
                        }
                    },
                    modifier = Modifier.size(48.dp),
                    containerColor = Color(0xFF2196F3),
                    shape = CircleShape
                ) {
                    Icon(
                        Icons.AutoMirrored.Filled.Send,
                        contentDescription = "Отправить",
                        tint = Color.White
                    )
                }
            }
        }
    }
}

@Composable
fun MessageBubble(message: Message, isFromCurrentUser: Boolean) {
    val dateFormat = remember { SimpleDateFormat("HH:mm", Locale.getDefault()) }

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 2.dp),
        horizontalArrangement = if (isFromCurrentUser) Arrangement.End else Arrangement.Start
    ) {
        Box(
            modifier = Modifier
                .widthIn(max = 280.dp)
                .clip(
                    RoundedCornerShape(
                        topStart = 16.dp,
                        topEnd = 16.dp,
                        bottomStart = if (isFromCurrentUser) 16.dp else 4.dp,
                        bottomEnd = if (isFromCurrentUser) 4.dp else 16.dp
                    )
                )
                .background(
                    if (isFromCurrentUser) Color(0xFF2196F3)
                    else MaterialTheme.colorScheme.surfaceVariant
                )
                .padding(horizontal = 12.dp, vertical = 8.dp)
        ) {
            Column {
                // Show sender name in groups
                if (!isFromCurrentUser && message.senderName != null) {
                    Text(
                        text = message.senderName,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.SemiBold,
                        color = Color(0xFF2196F3)
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                }

                Text(
                    text = message.text,
                    color = if (isFromCurrentUser) Color.White
                    else MaterialTheme.colorScheme.onSurface,
                    fontSize = 15.sp
                )

                Spacer(modifier = Modifier.height(2.dp))

                Text(
                    text = dateFormat.format(Date(message.timestamp)),
                    fontSize = 11.sp,
                    color = if (isFromCurrentUser) Color.White.copy(alpha = 0.7f)
                    else Color.Gray,
                    modifier = Modifier.align(Alignment.End)
                )
            }
        }
    }
}

private fun com.finder.app.models.ServerMessage.toMessage() = Message(
    id = id,
    chatId = chatId,
    senderId = senderId,
    text = text,
    messageType = messageType ?: "text",
    isEdited = isEdited ?: false,
    replyToId = replyToId,
    senderName = sender?.displayName,
    timestamp = try {
        java.text.SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss", java.util.Locale.US)
            .parse(createdAt ?: "")?.time ?: System.currentTimeMillis()
    } catch (_: Exception) { System.currentTimeMillis() }
)
