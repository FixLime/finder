package com.finder.app.ui.theme

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Applies a glass card effect simulating iOS liquid glass / ultra-thin material.
 *
 * Since Android Compose does not have a native blur-material backdrop, we approximate
 * the look with semi-transparent backgrounds, subtle gradient borders, and shadow.
 */
@Composable
fun Modifier.glassCard(
    cornerRadius: Dp = 20.dp,
    isDarkMode: Boolean = FinderTheme.colors.isDark
): Modifier {
    val shape = RoundedCornerShape(cornerRadius)
    val bgColor = if (isDarkMode) GlassCardBackgroundDark else GlassCardBackgroundLight
    val borderColor = if (isDarkMode) GlassBorderDark else GlassBorderLight
    val borderBrush = Brush.linearGradient(
        colors = listOf(
            borderColor.copy(alpha = borderColor.alpha * 1.5f),
            borderColor.copy(alpha = borderColor.alpha * 0.5f)
        )
    )

    return this
        .shadow(
            elevation = if (isDarkMode) 8.dp else 4.dp,
            shape = shape,
            ambientColor = Color.Black.copy(alpha = 0.15f),
            spotColor = Color.Black.copy(alpha = 0.1f)
        )
        .clip(shape)
        .background(bgColor, shape)
        .border(
            width = 0.5.dp,
            brush = borderBrush,
            shape = shape
        )
}

/**
 * Applies a capsule-shaped glass button style.
 */
@Composable
fun Modifier.glassButton(
    isDarkMode: Boolean = FinderTheme.colors.isDark
): Modifier {
    val shape = CircleShape
    val bgColor = if (isDarkMode) GlassButtonBackgroundDark else GlassButtonBackgroundLight
    val borderColor = if (isDarkMode) {
        Color.White.copy(alpha = 0.15f)
    } else {
        Color.Black.copy(alpha = 0.1f)
    }

    return this
        .shadow(
            elevation = 4.dp,
            shape = shape,
            ambientColor = Color.Black.copy(alpha = 0.1f),
            spotColor = Color.Black.copy(alpha = 0.08f)
        )
        .clip(shape)
        .background(bgColor, shape)
        .border(
            width = 0.5.dp,
            color = borderColor,
            shape = shape
        )
}

/**
 * Applies a glass text field background style.
 */
@Composable
fun Modifier.glassTextField(
    cornerRadius: Dp = 12.dp,
    isDarkMode: Boolean = FinderTheme.colors.isDark
): Modifier {
    val shape = RoundedCornerShape(cornerRadius)
    val bgColor = if (isDarkMode) GlassTextFieldBackgroundDark else GlassTextFieldBackgroundLight
    val borderColor = if (isDarkMode) {
        Color.White.copy(alpha = 0.08f)
    } else {
        Color.Black.copy(alpha = 0.08f)
    }

    return this
        .clip(shape)
        .background(bgColor, shape)
        .border(
            width = 0.5.dp,
            color = borderColor,
            shape = shape
        )
}
