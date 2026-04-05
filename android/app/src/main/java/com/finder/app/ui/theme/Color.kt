package com.finder.app.ui.theme

import androidx.compose.ui.graphics.Color

// Primary accent colors
val AccentBlue = Color(0xFF007AFF)
val AccentPurple = Color(0xFF8B5CF6)
val AccentCyan = Color(0xFF06B6D4)

// Status colors
val OnlineGreen = Color(0xFF34C759)
val WarningOrange = Color(0xFFFF9500)
val ErrorRed = Color(0xFFFF3B30)

// Glass colors - Dark mode
val GlassBackgroundDark = Color(0x14FFFFFF)       // white 0.08 alpha
val GlassBorderDark = Color(0x1AFFFFFF)            // white 0.10 alpha
val GlassOverlayDark = Color(0x26FFFFFF)           // white 0.15 alpha
val GlassCardBackgroundDark = Color(0x1FFFFFFF)    // white 0.12 alpha
val GlassButtonBackgroundDark = Color(0x33FFFFFF)  // white 0.20 alpha
val GlassTextFieldBackgroundDark = Color(0x1AFFFFFF) // white 0.10 alpha

// Glass colors - Light mode
val GlassBackgroundLight = Color(0xCCFFFFFF)       // white 0.80 alpha
val GlassBorderLight = Color(0x33000000)           // black 0.20 alpha
val GlassOverlayLight = Color(0x99FFFFFF)          // white 0.60 alpha
val GlassCardBackgroundLight = Color(0xB3FFFFFF)   // white 0.70 alpha
val GlassButtonBackgroundLight = Color(0x99FFFFFF) // white 0.60 alpha
val GlassTextFieldBackgroundLight = Color(0xB3FFFFFF) // white 0.70 alpha

// Surface and background colors
val DarkBackground = Color(0xFF0A0A0F)
val DarkSurface = Color(0xFF1A1A2E)
val LightBackground = Color(0xFFF0F0F5)
val LightSurface = Color(0xFFFFFFFF)

// Text colors
val TextPrimaryDark = Color(0xFFFFFFFF)
val TextSecondaryDark = Color(0xB3FFFFFF)           // white 0.70 alpha
val TextTertiaryDark = Color(0x80FFFFFF)            // white 0.50 alpha

val TextPrimaryLight = Color(0xFF000000)
val TextSecondaryLight = Color(0xB3000000)          // black 0.70 alpha
val TextTertiaryLight = Color(0x80000000)           // black 0.50 alpha

object FinderColors {

    object Dark {
        val background = DarkBackground
        val surface = DarkSurface
        val textPrimary = TextPrimaryDark
        val textSecondary = TextSecondaryDark
        val textTertiary = TextTertiaryDark
        val glassBackground = GlassBackgroundDark
        val glassBorder = GlassBorderDark
        val glassOverlay = GlassOverlayDark
        val glassCardBackground = GlassCardBackgroundDark
        val glassButtonBackground = GlassButtonBackgroundDark
        val glassTextFieldBackground = GlassTextFieldBackgroundDark
        val accentBlue = AccentBlue
        val accentPurple = AccentPurple
        val accentCyan = AccentCyan
        val onlineGreen = OnlineGreen
        val warningOrange = WarningOrange
        val errorRed = ErrorRed
    }

    object Light {
        val background = LightBackground
        val surface = LightSurface
        val textPrimary = TextPrimaryLight
        val textSecondary = TextSecondaryLight
        val textTertiary = TextTertiaryLight
        val glassBackground = GlassBackgroundLight
        val glassBorder = GlassBorderLight
        val glassOverlay = GlassOverlayLight
        val glassCardBackground = GlassCardBackgroundLight
        val glassButtonBackground = GlassButtonBackgroundLight
        val glassTextFieldBackground = GlassTextFieldBackgroundLight
        val accentBlue = AccentBlue
        val accentPurple = AccentPurple
        val accentCyan = AccentCyan
        val onlineGreen = OnlineGreen
        val warningOrange = WarningOrange
        val errorRed = ErrorRed
    }
}
