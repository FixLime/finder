package com.finder.app.ui.call

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.finder.app.services.ApiService
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
fun CallScreen(
    chatId: String,
    callerName: String,
    isVideo: Boolean,
    isIncoming: Boolean,
    onEnd: () -> Unit
) {
    var callDuration by remember { mutableIntStateOf(0) }
    var isMuted by remember { mutableStateOf(false) }
    var isSpeaker by remember { mutableStateOf(false) }
    var isConnected by remember { mutableStateOf(!isIncoming) }
    val scope = rememberCoroutineScope()

    // Start call on server
    LaunchedEffect(chatId) {
        if (!isIncoming) {
            try {
                ApiService.startCall(chatId, isVideo)
            } catch (_: Exception) {}
        }
    }

    // Timer
    LaunchedEffect(isConnected) {
        if (isConnected) {
            while (true) {
                delay(1000)
                callDuration++
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    colors = listOf(
                        Color(0xFF1A1A2E),
                        Color(0xFF16213E),
                        Color(0xFF0F3460)
                    )
                )
            ),
        contentAlignment = Alignment.Center
    ) {
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween,
            modifier = Modifier.fillMaxSize().padding(32.dp)
        ) {
            Spacer(modifier = Modifier.height(48.dp))

            // Caller info
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Box(
                    modifier = Modifier
                        .size(100.dp)
                        .clip(CircleShape)
                        .background(Color(0xFF2196F3)),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = callerName.take(1).uppercase(),
                        color = Color.White,
                        fontSize = 40.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                Spacer(modifier = Modifier.height(20.dp))

                Text(
                    text = callerName,
                    color = Color.White,
                    fontSize = 24.sp,
                    fontWeight = FontWeight.Bold
                )

                Spacer(modifier = Modifier.height(8.dp))

                Text(
                    text = when {
                        !isConnected && isIncoming -> "Входящий ${if (isVideo) "видео" else "аудио"}звонок..."
                        !isConnected -> "Вызов..."
                        else -> formatDuration(callDuration)
                    },
                    color = Color.White.copy(alpha = 0.7f),
                    fontSize = 16.sp
                )

                if (isVideo) {
                    Spacer(modifier = Modifier.height(8.dp))
                    Icon(
                        Icons.Default.Videocam,
                        contentDescription = null,
                        tint = Color.White.copy(alpha = 0.5f),
                        modifier = Modifier.size(24.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            // Controls
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                if (isIncoming && !isConnected) {
                    // Accept/Reject
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(48.dp)
                    ) {
                        // Reject
                        IconButton(
                            onClick = onEnd,
                            modifier = Modifier
                                .size(64.dp)
                                .clip(CircleShape)
                                .background(Color(0xFFEF5350))
                        ) {
                            Icon(
                                Icons.Default.CallEnd,
                                contentDescription = "Отклонить",
                                tint = Color.White,
                                modifier = Modifier.size(32.dp)
                            )
                        }
                        // Accept
                        IconButton(
                            onClick = { isConnected = true },
                            modifier = Modifier
                                .size(64.dp)
                                .clip(CircleShape)
                                .background(Color(0xFF4CAF50))
                        ) {
                            Icon(
                                Icons.Default.Call,
                                contentDescription = "Принять",
                                tint = Color.White,
                                modifier = Modifier.size(32.dp)
                            )
                        }
                    }
                } else {
                    // In-call controls
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(24.dp)
                    ) {
                        // Mute
                        IconButton(
                            onClick = { isMuted = !isMuted },
                            modifier = Modifier
                                .size(56.dp)
                                .clip(CircleShape)
                                .background(if (isMuted) Color.White.copy(alpha = 0.3f) else Color.White.copy(alpha = 0.1f))
                        ) {
                            Icon(
                                if (isMuted) Icons.Default.MicOff else Icons.Default.Mic,
                                contentDescription = "Микрофон",
                                tint = Color.White,
                                modifier = Modifier.size(28.dp)
                            )
                        }

                        // Speaker
                        IconButton(
                            onClick = { isSpeaker = !isSpeaker },
                            modifier = Modifier
                                .size(56.dp)
                                .clip(CircleShape)
                                .background(if (isSpeaker) Color.White.copy(alpha = 0.3f) else Color.White.copy(alpha = 0.1f))
                        ) {
                            Icon(
                                if (isSpeaker) Icons.Default.VolumeUp else Icons.Default.VolumeDown,
                                contentDescription = "Динамик",
                                tint = Color.White,
                                modifier = Modifier.size(28.dp)
                            )
                        }

                        // End call
                        IconButton(
                            onClick = onEnd,
                            modifier = Modifier
                                .size(56.dp)
                                .clip(CircleShape)
                                .background(Color(0xFFEF5350))
                        ) {
                            Icon(
                                Icons.Default.CallEnd,
                                contentDescription = "Завершить",
                                tint = Color.White,
                                modifier = Modifier.size(28.dp)
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

private fun formatDuration(seconds: Int): String {
    val m = seconds / 60
    val s = seconds % 60
    return "%02d:%02d".format(m, s)
}
