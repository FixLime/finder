package com.finder.app.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.finder.app.ui.theme.FinderTheme
import com.finder.app.ui.theme.GlassBorderDark
import com.finder.app.ui.theme.GlassBorderLight
import com.finder.app.ui.theme.GlassCardBackgroundDark
import com.finder.app.ui.theme.GlassCardBackgroundLight

/**
 * A composable container that renders its content with a glass morphism effect,
 * simulating the iOS liquid glass / ultra-thin material look on Android.
 *
 * Uses semi-transparent backgrounds, gradient borders, and elevation shadows
 * to approximate the frosted-glass aesthetic.
 */
@Composable
fun GlassCard(
    modifier: Modifier = Modifier,
    cornerRadius: Dp = 20.dp,
    content: @Composable BoxScope.() -> Unit
) {
    val colors = FinderTheme.colors
    val isDark = colors.isDark
    val shape = RoundedCornerShape(cornerRadius)

    val bgColor = if (isDark) GlassCardBackgroundDark else GlassCardBackgroundLight

    val borderBrush = Brush.linearGradient(
        colors = if (isDark) {
            listOf(
                GlassBorderDark.copy(alpha = GlassBorderDark.alpha * 1.8f),
                GlassBorderDark.copy(alpha = GlassBorderDark.alpha * 0.4f)
            )
        } else {
            listOf(
                GlassBorderLight.copy(alpha = GlassBorderLight.alpha * 1.5f),
                GlassBorderLight.copy(alpha = GlassBorderLight.alpha * 0.3f)
            )
        }
    )

    Box(
        modifier = modifier
            .shadow(
                elevation = if (isDark) 10.dp else 6.dp,
                shape = shape,
                ambientColor = Color.Black.copy(alpha = 0.2f),
                spotColor = Color.Black.copy(alpha = 0.12f)
            )
            .clip(shape)
            .background(bgColor, shape)
            .border(
                width = 0.5.dp,
                brush = borderBrush,
                shape = shape
            ),
        content = content
    )
}
