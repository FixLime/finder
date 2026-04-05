package com.finder.app.ui.screens.calls

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CallEnd
import androidx.compose.material.icons.filled.MicOff
import androidx.compose.material.icons.filled.VolumeUp
import androidx.compose.material3.*
import androidx.compose.runtime.*
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
import com.finder.app.ui.theme.FinderTheme
import kotlinx.coroutines.delay

@Composable
fun ActiveCallScreen(
    onEndCall: () -> Unit
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current

    var isMuted by remember { mutableStateOf(false) }
    var isSpeaker by remember { mutableStateOf(false) }
    var callSeconds by remember { mutableIntStateOf(0) }
    var callStatus by remember { mutableStateOf("Вызов...") }

    // Simulate call connection stages
    LaunchedEffect(Unit) {
        delay(2000)
        callStatus = "Соединение..."
        delay(2000)
        callStatus = "Разговор"
    }

    // Call timer
    LaunchedEffect(callStatus) {
        if (callStatus == "Разговор") {
            while (true) {
                delay(1000)
                callSeconds++
            }
        }
    }

    val formattedTime = remember(callSeconds) {
        val minutes = callSeconds / 60
        val seconds = callSeconds % 60
        String.format("%02d:%02d", minutes, seconds)
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                Brush.verticalGradient(
                    listOf(
                        Color(0xFF0A0A1A),
                        Color(0xFF1A0A2E),
                        Color(0xFF0A0A1A)
                    )
                )
            )
    ) {
        // Blurred background circles for visual effect
        Box(
            modifier = Modifier
                .size(300.dp)
                .offset(x = (-50).dp, y = 100.dp)
                .blur(120.dp)
                .background(
                    colors.accentPurple.copy(alpha = 0.15f),
                    CircleShape
                )
        )
        Box(
            modifier = Modifier
                .size(250.dp)
                .offset(x = 150.dp, y = 400.dp)
                .blur(100.dp)
                .background(
                    colors.accentBlue.copy(alpha = 0.1f),
                    CircleShape
                )
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .statusBarsPadding()
                .navigationBarsPadding()
                .padding(horizontal = 32.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            Spacer(modifier = Modifier.height(60.dp))

            // User info section
            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                // Large avatar
                Box(
                    modifier = Modifier
                        .size(120.dp)
                        .clip(CircleShape)
                        .background(
                            Brush.linearGradient(
                                listOf(colors.accentPurple, colors.accentBlue)
                            )
                        )
                        .border(2.dp, colors.glassBorder, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = "A",
                        color = Color.White,
                        fontWeight = FontWeight.Bold,
                        fontSize = 48.sp
                    )
                }

                Spacer(modifier = Modifier.height(24.dp))

                // User name
                Text(
                    text = "Алексей Волков",
                    color = colors.textPrimary,
                    fontWeight = FontWeight.Bold,
                    fontSize = 24.sp,
                    textAlign = TextAlign.Center
                )

                Spacer(modifier = Modifier.height(8.dp))

                // Call status
                Text(
                    text = callStatus,
                    color = colors.textSecondary,
                    fontSize = 16.sp
                )

                // Timer
                if (callStatus == "Разговор") {
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = formattedTime,
                        color = colors.accentBlue,
                        fontWeight = FontWeight.Medium,
                        fontSize = 20.sp
                    )
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            // Bottom control buttons
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 48.dp),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Mute button
                CallActionButton(
                    icon = Icons.Default.MicOff,
                    label = "Микрофон",
                    isActive = isMuted,
                    activeColor = colors.glassButtonBackground,
                    onClick = {
                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        isMuted = !isMuted
                    }
                )

                // End call button (red, larger)
                Box(
                    modifier = Modifier
                        .size(72.dp)
                        .clip(CircleShape)
                        .background(colors.errorRed)
                        .clickable {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                            onEndCall()
                        },
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        Icons.Default.CallEnd,
                        contentDescription = "Завершить",
                        tint = Color.White,
                        modifier = Modifier.size(32.dp)
                    )
                }

                // Speaker button
                CallActionButton(
                    icon = Icons.Default.VolumeUp,
                    label = "Динамик",
                    isActive = isSpeaker,
                    activeColor = colors.glassButtonBackground,
                    onClick = {
                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        isSpeaker = !isSpeaker
                    }
                )
            }
        }
    }
}

@Composable
private fun CallActionButton(
    icon: ImageVector,
    label: String,
    isActive: Boolean,
    activeColor: Color,
    onClick: () -> Unit
) {
    val colors = FinderTheme.colors

    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Box(
            modifier = Modifier
                .size(56.dp)
                .clip(CircleShape)
                .background(
                    if (isActive) Color.White.copy(alpha = 0.2f)
                    else colors.glassCardBackground
                )
                .border(0.5.dp, colors.glassBorder, CircleShape)
                .clickable(onClick = onClick),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                icon,
                contentDescription = label,
                tint = if (isActive) Color.White else colors.textSecondary,
                modifier = Modifier.size(24.dp)
            )
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = label,
            color = colors.textTertiary,
            fontSize = 12.sp
        )
    }
}
