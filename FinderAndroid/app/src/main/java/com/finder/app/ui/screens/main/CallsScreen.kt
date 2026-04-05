package com.finder.app.ui.screens.main

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
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
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Call
import androidx.compose.material.icons.filled.CallMade
import androidx.compose.material.icons.filled.CallReceived
import androidx.compose.material.icons.filled.PhoneMissed
import androidx.compose.material.icons.filled.Verified
import androidx.compose.material.icons.filled.Videocam
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.finder.app.models.CallRecord
import com.finder.app.ui.theme.FinderTheme
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale

@Composable
fun CallsScreen(
    callHistory: List<CallRecord> = emptyList(),
    onCallBack: (CallRecord) -> Unit = {}
) {
    val colors = FinderTheme.colors

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .windowInsetsPadding(WindowInsets.statusBars)
            .padding(bottom = 64.dp)
    ) {
        // Header
        Text(
            text = "Звонки",
            style = MaterialTheme.typography.displayMedium,
            color = colors.textPrimary,
            modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)
        )

        if (callHistory.isEmpty()) {
            EmptyCallsState(
                modifier = Modifier
                    .fillMaxSize()
                    .weight(1f)
            )
        } else {
            LazyColumn(
                modifier = Modifier.fillMaxSize()
            ) {
                items(
                    items = callHistory,
                    key = { it.id }
                ) { call ->
                    CallHistoryItem(
                        call = call,
                        onCallBack = { onCallBack(call) }
                    )
                }
            }
        }
    }
}

@Composable
private fun CallHistoryItem(
    call: CallRecord,
    onCallBack: () -> Unit
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current

    Row(
        verticalAlignment = Alignment.CenterVertically,
        modifier = Modifier
            .fillMaxWidth()
            .clickable {
                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                onCallBack()
            }
            .padding(horizontal = 16.dp, vertical = 10.dp)
    ) {
        // Avatar
        AvatarView(
            user = call.user,
            size = 48.dp
        )

        Spacer(modifier = Modifier.width(12.dp))

        // Call info
        Column(modifier = Modifier.weight(1f)) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                Text(
                    text = call.user.displayName,
                    style = MaterialTheme.typography.titleMedium,
                    color = if (call.isMissed) colors.errorRed else colors.textPrimary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    fontWeight = FontWeight.Medium
                )

                if (call.user.isVerified) {
                    Spacer(modifier = Modifier.width(4.dp))
                    Icon(
                        imageVector = Icons.Filled.Verified,
                        contentDescription = "Верифицирован",
                        tint = colors.accentBlue,
                        modifier = Modifier.size(16.dp)
                    )
                }

                if (call.user.isUntrusted) {
                    Spacer(modifier = Modifier.width(4.dp))
                    Icon(
                        imageVector = Icons.Filled.Warning,
                        contentDescription = "Не доверенный",
                        tint = colors.warningOrange,
                        modifier = Modifier.size(16.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.height(2.dp))

            Row(verticalAlignment = Alignment.CenterVertically) {
                // Call direction icon
                Icon(
                    imageVector = when {
                        call.isMissed -> Icons.Filled.PhoneMissed
                        call.isOutgoing -> Icons.Filled.CallMade
                        else -> Icons.Filled.CallReceived
                    },
                    contentDescription = null,
                    tint = when {
                        call.isMissed -> colors.errorRed
                        call.isOutgoing -> colors.onlineGreen
                        else -> colors.accentBlue
                    },
                    modifier = Modifier.size(14.dp)
                )

                Spacer(modifier = Modifier.width(4.dp))

                // Call type label
                Text(
                    text = when {
                        call.isMissed && call.isOutgoing -> "Не отвечено"
                        call.isMissed -> "Пропущенный"
                        call.isOutgoing -> "Исходящий"
                        else -> "Входящий"
                    },
                    style = MaterialTheme.typography.bodySmall,
                    color = if (call.isMissed) colors.errorRed else colors.textTertiary
                )

                // Duration
                if (call.duration != null && !call.isMissed) {
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(
                        text = formatCallDuration(call.duration),
                        style = MaterialTheme.typography.bodySmall,
                        color = colors.textTertiary
                    )
                }

                Spacer(modifier = Modifier.width(8.dp))

                // Timestamp
                Text(
                    text = formatCallTimestamp(call.timestamp),
                    style = MaterialTheme.typography.bodySmall,
                    color = colors.textTertiary
                )
            }
        }

        // Video/audio indicator and callback button
        IconButton(
            onClick = {
                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                onCallBack()
            }
        ) {
            Icon(
                imageVector = if (call.isVideo) Icons.Filled.Videocam else Icons.Filled.Call,
                contentDescription = if (call.isVideo) "Видеозвонок" else "Голосовой звонок",
                tint = colors.accentBlue,
                modifier = Modifier.size(22.dp)
            )
        }
    }
}

@Composable
private fun EmptyCallsState(modifier: Modifier = Modifier) {
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
                imageVector = Icons.Filled.Call,
                contentDescription = null,
                tint = colors.textTertiary,
                modifier = Modifier.size(36.dp)
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Нет звонков",
            style = MaterialTheme.typography.headlineMedium,
            color = colors.textPrimary
        )

        Spacer(modifier = Modifier.height(8.dp))

        Text(
            text = "Здесь будет история ваших звонков",
            style = MaterialTheme.typography.bodyMedium,
            color = colors.textSecondary,
            textAlign = TextAlign.Center
        )
    }
}

private fun formatCallDuration(seconds: Int): String {
    val minutes = seconds / 60
    val secs = seconds % 60
    return if (minutes > 0) {
        "${minutes} мин ${secs} сек"
    } else {
        "${secs} сек"
    }
}

private fun formatCallTimestamp(date: Date): String {
    val now = Calendar.getInstance()
    val callCal = Calendar.getInstance().apply { time = date }

    return when {
        now.get(Calendar.DATE) == callCal.get(Calendar.DATE) &&
            now.get(Calendar.MONTH) == callCal.get(Calendar.MONTH) &&
            now.get(Calendar.YEAR) == callCal.get(Calendar.YEAR) -> {
            SimpleDateFormat("HH:mm", Locale.getDefault()).format(date)
        }
        now.get(Calendar.DATE) - callCal.get(Calendar.DATE) == 1 &&
            now.get(Calendar.MONTH) == callCal.get(Calendar.MONTH) &&
            now.get(Calendar.YEAR) == callCal.get(Calendar.YEAR) -> {
            "Вчера"
        }
        now.get(Calendar.YEAR) == callCal.get(Calendar.YEAR) -> {
            SimpleDateFormat("d MMM", Locale("ru")).format(date)
        }
        else -> {
            SimpleDateFormat("dd.MM.yy", Locale.getDefault()).format(date)
        }
    }
}
