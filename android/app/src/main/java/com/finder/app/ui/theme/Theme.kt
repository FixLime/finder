package com.finder.app.ui.theme

import android.app.Activity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.material3.Typography
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = AccentBlue,
    secondary = AccentPurple,
    tertiary = AccentCyan,
    background = DarkBackground,
    surface = DarkSurface,
    onPrimary = Color.White,
    onSecondary = Color.White,
    onTertiary = Color.White,
    onBackground = TextPrimaryDark,
    onSurface = TextPrimaryDark,
    surfaceVariant = GlassCardBackgroundDark,
    outline = GlassBorderDark
)

private val LightColorScheme = lightColorScheme(
    primary = AccentBlue,
    secondary = AccentPurple,
    tertiary = AccentCyan,
    background = LightBackground,
    surface = LightSurface,
    onPrimary = Color.White,
    onSecondary = Color.White,
    onTertiary = Color.White,
    onBackground = TextPrimaryLight,
    onSurface = TextPrimaryLight,
    surfaceVariant = GlassCardBackgroundLight,
    outline = GlassBorderLight
)

data class FinderColorScheme(
    val glassBackground: Color,
    val glassBorder: Color,
    val glassOverlay: Color,
    val glassCardBackground: Color,
    val glassButtonBackground: Color,
    val glassTextFieldBackground: Color,
    val accentBlue: Color,
    val accentPurple: Color,
    val accentCyan: Color,
    val onlineGreen: Color,
    val warningOrange: Color,
    val errorRed: Color,
    val textPrimary: Color,
    val textSecondary: Color,
    val textTertiary: Color,
    val isDark: Boolean
) {
    /** Primary accent color alias (blue). */
    val accent: Color get() = accentBlue
    /** Error color alias (red). */
    val error: Color get() = errorRed
}

val LocalFinderColors = staticCompositionLocalOf {
    FinderColorScheme(
        glassBackground = GlassBackgroundDark,
        glassBorder = GlassBorderDark,
        glassOverlay = GlassOverlayDark,
        glassCardBackground = GlassCardBackgroundDark,
        glassButtonBackground = GlassButtonBackgroundDark,
        glassTextFieldBackground = GlassTextFieldBackgroundDark,
        accentBlue = AccentBlue,
        accentPurple = AccentPurple,
        accentCyan = AccentCyan,
        onlineGreen = OnlineGreen,
        warningOrange = WarningOrange,
        errorRed = ErrorRed,
        textPrimary = TextPrimaryDark,
        textSecondary = TextSecondaryDark,
        textTertiary = TextTertiaryDark,
        isDark = true
    )
}

private val FinderTypography = Typography(
    displayLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Bold,
        fontSize = 34.sp,
        lineHeight = 41.sp,
        letterSpacing = 0.25.sp
    ),
    displayMedium = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Bold,
        fontSize = 28.sp,
        lineHeight = 34.sp
    ),
    headlineLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.SemiBold,
        fontSize = 24.sp,
        lineHeight = 30.sp
    ),
    headlineMedium = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.SemiBold,
        fontSize = 20.sp,
        lineHeight = 26.sp
    ),
    titleLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.SemiBold,
        fontSize = 18.sp,
        lineHeight = 24.sp
    ),
    titleMedium = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Medium,
        fontSize = 16.sp,
        lineHeight = 22.sp
    ),
    bodyLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 16.sp,
        lineHeight = 22.sp
    ),
    bodyMedium = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 14.sp,
        lineHeight = 20.sp
    ),
    bodySmall = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Normal,
        fontSize = 12.sp,
        lineHeight = 16.sp
    ),
    labelLarge = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Medium,
        fontSize = 14.sp,
        lineHeight = 20.sp
    ),
    labelMedium = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Medium,
        fontSize = 12.sp,
        lineHeight = 16.sp
    ),
    labelSmall = TextStyle(
        fontFamily = FontFamily.Default,
        fontWeight = FontWeight.Medium,
        fontSize = 10.sp,
        lineHeight = 14.sp
    )
)

@Composable
fun FinderTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val colorScheme = if (darkTheme) DarkColorScheme else LightColorScheme

    val finderColors = if (darkTheme) {
        FinderColorScheme(
            glassBackground = FinderColors.Dark.glassBackground,
            glassBorder = FinderColors.Dark.glassBorder,
            glassOverlay = FinderColors.Dark.glassOverlay,
            glassCardBackground = FinderColors.Dark.glassCardBackground,
            glassButtonBackground = FinderColors.Dark.glassButtonBackground,
            glassTextFieldBackground = FinderColors.Dark.glassTextFieldBackground,
            accentBlue = FinderColors.Dark.accentBlue,
            accentPurple = FinderColors.Dark.accentPurple,
            accentCyan = FinderColors.Dark.accentCyan,
            onlineGreen = FinderColors.Dark.onlineGreen,
            warningOrange = FinderColors.Dark.warningOrange,
            errorRed = FinderColors.Dark.errorRed,
            textPrimary = FinderColors.Dark.textPrimary,
            textSecondary = FinderColors.Dark.textSecondary,
            textTertiary = FinderColors.Dark.textTertiary,
            isDark = true
        )
    } else {
        FinderColorScheme(
            glassBackground = FinderColors.Light.glassBackground,
            glassBorder = FinderColors.Light.glassBorder,
            glassOverlay = FinderColors.Light.glassOverlay,
            glassCardBackground = FinderColors.Light.glassCardBackground,
            glassButtonBackground = FinderColors.Light.glassButtonBackground,
            glassTextFieldBackground = FinderColors.Light.glassTextFieldBackground,
            accentBlue = FinderColors.Light.accentBlue,
            accentPurple = FinderColors.Light.accentPurple,
            accentCyan = FinderColors.Light.accentCyan,
            onlineGreen = FinderColors.Light.onlineGreen,
            warningOrange = FinderColors.Light.warningOrange,
            errorRed = FinderColors.Light.errorRed,
            textPrimary = FinderColors.Light.textPrimary,
            textSecondary = FinderColors.Light.textSecondary,
            textTertiary = FinderColors.Light.textTertiary,
            isDark = false
        )
    }

    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = Color.Transparent.toArgb()
            window.navigationBarColor = Color.Transparent.toArgb()
            WindowCompat.getInsetsController(window, view).apply {
                isAppearanceLightStatusBars = !darkTheme
                isAppearanceLightNavigationBars = !darkTheme
            }
        }
    }

    CompositionLocalProvider(LocalFinderColors provides finderColors) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = FinderTypography,
            content = content
        )
    }
}

object FinderTheme {
    val colors: FinderColorScheme
        @Composable
        get() = LocalFinderColors.current
}
