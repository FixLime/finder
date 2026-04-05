package com.finder.app.ui.components

import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import com.finder.app.ui.theme.AccentBlue
import com.finder.app.ui.theme.AccentCyan
import com.finder.app.ui.theme.AccentPurple
import kotlin.math.cos
import kotlin.math.sin

private data class OrbConfig(
    val color: Color,
    val baseX: Float,       // 0..1 fraction of width
    val baseY: Float,       // 0..1 fraction of height
    val radiusFraction: Float, // fraction of min(width, height)
    val xAmplitude: Float,  // pixels of horizontal float
    val yAmplitude: Float,  // pixels of vertical float
    val durationMs: Int,
    val phaseOffset: Float  // radians
)

private val orbs = listOf(
    OrbConfig(
        color = AccentBlue.copy(alpha = 0.18f),
        baseX = 0.25f, baseY = 0.20f,
        radiusFraction = 0.35f,
        xAmplitude = 40f, yAmplitude = 30f,
        durationMs = 8000, phaseOffset = 0f
    ),
    OrbConfig(
        color = AccentPurple.copy(alpha = 0.15f),
        baseX = 0.75f, baseY = 0.45f,
        radiusFraction = 0.30f,
        xAmplitude = 35f, yAmplitude = 45f,
        durationMs = 10000, phaseOffset = 1.2f
    ),
    OrbConfig(
        color = AccentCyan.copy(alpha = 0.12f),
        baseX = 0.40f, baseY = 0.75f,
        radiusFraction = 0.28f,
        xAmplitude = 50f, yAmplitude = 25f,
        durationMs = 12000, phaseOffset = 2.5f
    ),
    OrbConfig(
        color = AccentPurple.copy(alpha = 0.10f),
        baseX = 0.15f, baseY = 0.60f,
        radiusFraction = 0.22f,
        xAmplitude = 30f, yAmplitude = 40f,
        durationMs = 9000, phaseOffset = 3.8f
    ),
    OrbConfig(
        color = AccentBlue.copy(alpha = 0.08f),
        baseX = 0.85f, baseY = 0.15f,
        radiusFraction = 0.25f,
        xAmplitude = 25f, yAmplitude = 35f,
        durationMs = 11000, phaseOffset = 5.0f
    )
)

/**
 * Animated background layer with floating colored orbs (blue, purple, cyan).
 * Uses radial gradients with low alpha to create a soft, diffused glow effect
 * that simulates the depth of the iOS liquid glass aesthetic.
 */
@Composable
fun FloatingOrbsBackground(
    modifier: Modifier = Modifier
) {
    val infiniteTransition = rememberInfiniteTransition(label = "orbs")

    // Create a single animation progress value from 0 to 2*PI
    val progress by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = (2 * Math.PI).toFloat(),
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 20000, easing = LinearEasing),
            repeatMode = RepeatMode.Restart
        ),
        label = "orbProgress"
    )

    // Individual orb animations with varying speeds
    val orbAnimations = orbs.map { orb ->
        val anim by infiniteTransition.animateFloat(
            initialValue = 0f,
            targetValue = (2 * Math.PI).toFloat(),
            animationSpec = infiniteRepeatable(
                animation = tween(durationMillis = orb.durationMs, easing = LinearEasing),
                repeatMode = RepeatMode.Restart
            ),
            label = "orb_${orb.baseX}_${orb.baseY}"
        )
        anim
    }

    Canvas(modifier = modifier.fillMaxSize()) {
        val w = size.width
        val h = size.height
        val minDim = minOf(w, h)

        orbs.forEachIndexed { index, orb ->
            val t = orbAnimations[index] + orb.phaseOffset

            val cx = orb.baseX * w + sin(t) * orb.xAmplitude
            val cy = orb.baseY * h + cos(t * 0.7f) * orb.yAmplitude
            val radius = orb.radiusFraction * minDim

            val gradient = Brush.radialGradient(
                colors = listOf(
                    orb.color,
                    orb.color.copy(alpha = orb.color.alpha * 0.5f),
                    Color.Transparent
                ),
                center = Offset(cx, cy),
                radius = radius
            )

            drawCircle(
                brush = gradient,
                radius = radius,
                center = Offset(cx, cy),
                blendMode = BlendMode.Screen
            )
        }
    }
}
