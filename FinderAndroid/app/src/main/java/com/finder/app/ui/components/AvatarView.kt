package com.finder.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Note
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Warning
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.finder.app.models.FinderUser
import com.finder.app.ui.theme.AccentBlue
import com.finder.app.ui.theme.FinderTheme
import com.finder.app.ui.theme.OnlineGreen
import com.finder.app.ui.theme.WarningOrange

@Composable
fun AvatarView(
    user: FinderUser?,
    size: Dp = 44.dp,
    isGroup: Boolean = false,
    isNotes: Boolean = false,
    modifier: Modifier = Modifier
) {
    val colors = FinderTheme.colors
    val avatarColor = user?.avatarColor?.color ?: AccentBlue
    val iconSize = size * 0.5f
    val fontSize = (size.value * 0.4f).sp

    Box(
        modifier = modifier.size(size),
        contentAlignment = Alignment.Center
    ) {
        // Main circle
        Box(
            modifier = Modifier
                .size(size)
                .clip(CircleShape)
                .background(avatarColor),
            contentAlignment = Alignment.Center
        ) {
            when {
                isNotes -> {
                    Icon(
                        imageVector = Icons.Default.Note,
                        contentDescription = "Notes",
                        modifier = Modifier.size(iconSize),
                        tint = Color.White
                    )
                }
                isGroup -> {
                    Icon(
                        imageVector = Icons.Default.Group,
                        contentDescription = "Group",
                        modifier = Modifier.size(iconSize),
                        tint = Color.White
                    )
                }
                user != null -> {
                    val iconName = user.avatarIcon
                    if (iconName == "person" || iconName.isEmpty()) {
                        Icon(
                            imageVector = Icons.Default.Person,
                            contentDescription = "User avatar",
                            modifier = Modifier.size(iconSize),
                            tint = Color.White
                        )
                    } else {
                        // For custom display names, show the first character
                        Text(
                            text = user.displayName.take(1).uppercase(),
                            color = Color.White,
                            fontSize = fontSize,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
                else -> {
                    Icon(
                        imageVector = Icons.Default.Person,
                        contentDescription = "User avatar",
                        modifier = Modifier.size(iconSize),
                        tint = Color.White
                    )
                }
            }
        }

        // Online indicator
        if (user?.isOnline == true && !isGroup && !isNotes) {
            Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .offset(x = 1.dp, y = 1.dp)
                    .size(size * 0.28f)
                    .border(
                        width = 2.dp,
                        color = if (colors.isDark) Color(0xFF0A0A0F) else Color.White,
                        shape = CircleShape
                    )
                    .padding(2.dp)
                    .clip(CircleShape)
                    .background(OnlineGreen)
            )
        }

        // Verified badge
        if (user?.isVerified == true && !isGroup && !isNotes) {
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .offset(x = 2.dp, y = (-2).dp)
                    .size(size * 0.3f)
            ) {
                Icon(
                    imageVector = Icons.Default.CheckCircle,
                    contentDescription = "Verified",
                    modifier = Modifier.size(size * 0.3f),
                    tint = AccentBlue
                )
            }
        }

        // Untrusted badge
        if (user?.isUntrusted == true && !isGroup && !isNotes) {
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .offset(x = 2.dp, y = (-2).dp)
                    .size(size * 0.3f)
            ) {
                Icon(
                    imageVector = Icons.Default.Warning,
                    contentDescription = "Untrusted",
                    modifier = Modifier.size(size * 0.3f),
                    tint = WarningOrange
                )
            }
        }
    }
}
