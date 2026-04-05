package com.finder.app.ui.screens.onboarding

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.finder.app.ui.theme.FinderTheme
import kotlinx.coroutines.launch

// ============================================================
// Localization helper (shared across auth screens)
// ============================================================

internal fun localized(isRussian: Boolean, ru: String, en: String): String =
    if (isRussian) ru else en

// ============================================================
// Onboarding page model
// ============================================================

private data class OnboardingPageData(
    val icon: ImageVector,
    val iconColor: Color,
    val titleRu: String,
    val titleEn: String,
    val descriptionRu: String,
    val descriptionEn: String,
    val showLogo: Boolean = false,
    val showFingerprint: Boolean = false
)

private val onboardingPages = listOf(
    OnboardingPageData(
        icon = Icons.Filled.Shield,
        iconColor = Color(0xFF007AFF),
        titleRu = "Добро пожаловать\nв Finder",
        titleEn = "Welcome\nto Finder",
        descriptionRu = "Мессенджер нового поколения\nс максимальной конфиденциальностью",
        descriptionEn = "Next-generation messenger\nwith maximum privacy",
        showLogo = true
    ),
    OnboardingPageData(
        icon = Icons.Filled.Lock,
        iconColor = Color(0xFF34C759),
        titleRu = "Шифрование\nот начала до конца",
        titleEn = "End-to-End\nEncryption",
        descriptionRu = "Все сообщения защищены\nсквозным шифрованием.\nНикто не может прочитать ваши данные",
        descriptionEn = "All messages are protected\nwith end-to-end encryption.\nNo one can read your data"
    ),
    OnboardingPageData(
        icon = Icons.Filled.VisibilityOff,
        iconColor = Color(0xFF8B5CF6),
        titleRu = "Ghost Mode",
        titleEn = "Ghost Mode",
        descriptionRu = "Станьте невидимым.\nНикто не узнает, что вы онлайн,\nчитаете сообщения или печатаете",
        descriptionEn = "Become invisible.\nNo one will know you're online,\nreading messages, or typing"
    ),
    OnboardingPageData(
        icon = Icons.Filled.Message,
        iconColor = Color(0xFFFF9500),
        titleRu = "Фантомные\nсообщения",
        titleEn = "Phantom\nMessages",
        descriptionRu = "Сообщения, которые исчезают\nпосле прочтения.\nНе оставляйте следов",
        descriptionEn = "Messages that disappear\nafter reading.\nLeave no trace"
    ),
    OnboardingPageData(
        icon = Icons.Filled.LocalFireDepartment,
        iconColor = Color(0xFFFF3B30),
        titleRu = "Протокол Fenix",
        titleEn = "Fenix Protocol",
        descriptionRu = "Одно нажатие — и все ваши данные\nбудут безвозвратно удалены\nс наших серверов",
        descriptionEn = "One tap — and all your data\nwill be permanently deleted\nfrom our servers"
    ),
    OnboardingPageData(
        icon = Icons.Filled.Fingerprint,
        iconColor = Color(0xFF06B6D4),
        titleRu = "FinderID",
        titleEn = "FinderID",
        descriptionRu = "Никаких телефонов и почты.\nТолько ваш уникальный FinderID\nи PIN-код для входа",
        descriptionEn = "No phone numbers or emails.\nOnly your unique FinderID\nand PIN code for login",
        showFingerprint = true
    )
)

// ============================================================
// OnboardingScreen
// ============================================================

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun OnboardingScreen(
    onNavigateToSetup: () -> Unit
) {
    val colors = FinderTheme.colors
    val haptic = LocalHapticFeedback.current
    var isRussian by remember { mutableStateOf(true) }

    val pagerState = rememberPagerState(pageCount = { onboardingPages.size })
    val coroutineScope = rememberCoroutineScope()
    val totalPages = onboardingPages.size

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
    ) {
        Column(modifier = Modifier.fillMaxSize()) {

            // --- Top bar: Language + Theme toggles ---
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 12.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Language toggle
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = colors.glassCardBackground,
                    border = androidx.compose.foundation.BorderStroke(0.5.dp, colors.glassBorder),
                    modifier = Modifier.clickable {
                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                        isRussian = !isRussian
                    }
                ) {
                    Row(
                        modifier = Modifier.padding(horizontal = 14.dp, vertical = 8.dp),
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Language,
                            contentDescription = null,
                            tint = colors.textPrimary,
                            modifier = Modifier.size(18.dp)
                        )
                        Text(
                            text = if (isRussian) "EN" else "RU",
                            color = colors.textPrimary,
                            fontWeight = FontWeight.Medium,
                            fontSize = 14.sp
                        )
                    }
                }

                // Theme toggle (visual only -- actual theme is provided by FinderTheme wrapper)
                Surface(
                    shape = RoundedCornerShape(12.dp),
                    color = colors.glassCardBackground,
                    border = androidx.compose.foundation.BorderStroke(0.5.dp, colors.glassBorder),
                    modifier = Modifier.clickable {
                        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                    }
                ) {
                    Icon(
                        imageVector = if (colors.isDark) Icons.Filled.LightMode else Icons.Filled.DarkMode,
                        contentDescription = null,
                        tint = colors.textPrimary,
                        modifier = Modifier
                            .padding(10.dp)
                            .size(22.dp)
                    )
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            // --- Horizontal pager ---
            HorizontalPager(
                state = pagerState,
                modifier = Modifier.weight(3f)
            ) { page ->
                OnboardingPageContent(
                    data = onboardingPages[page],
                    isRussian = isRussian
                )
            }

            Spacer(modifier = Modifier.weight(0.5f))

            // --- Page indicator dots ---
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 24.dp),
                horizontalArrangement = Arrangement.Center,
                verticalAlignment = Alignment.CenterVertically
            ) {
                repeat(totalPages) { index ->
                    val isSelected = pagerState.currentPage == index
                    val widthFloat by animateFloatAsState(
                        targetValue = if (isSelected) 24f else 8f,
                        animationSpec = spring(dampingRatio = 0.7f, stiffness = 300f),
                        label = "dotWidth"
                    )
                    val width = widthFloat.dp
                    Box(
                        modifier = Modifier
                            .padding(horizontal = 4.dp)
                            .height(8.dp)
                            .width(width)
                            .clip(RoundedCornerShape(4.dp))
                            .background(
                                if (isSelected) colors.accentBlue
                                else colors.textTertiary.copy(alpha = 0.3f)
                            )
                    )
                }
            }

            // --- Buttons ---
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 32.dp)
                    .padding(bottom = 40.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                if (pagerState.currentPage < totalPages - 1) {
                    // Next button
                    GlassActionButton(
                        text = localized(isRussian, "Далее", "Next"),
                        onClick = {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                            coroutineScope.launch {
                                pagerState.animateScrollToPage(pagerState.currentPage + 1)
                            }
                        }
                    )
                    // Skip (not on first page)
                    if (pagerState.currentPage > 0) {
                        TextButton(onClick = {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                            onNavigateToSetup()
                        }) {
                            Text(
                                text = localized(isRussian, "Пропустить", "Skip"),
                                color = colors.textSecondary,
                                fontSize = 14.sp
                            )
                        }
                    }
                } else {
                    // Start button on last page
                    GlassActionButton(
                        text = localized(isRussian, "Начать", "Start"),
                        onClick = {
                            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                            onNavigateToSetup()
                        }
                    )
                }
            }
        }
    }
}

// ============================================================
// Single onboarding page
// ============================================================

@Composable
private fun OnboardingPageContent(
    data: OnboardingPageData,
    isRussian: Boolean
) {
    val colors = FinderTheme.colors
    var appear by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) { appear = true }

    val scale by animateFloatAsState(
        targetValue = if (appear) 1f else 0.5f,
        animationSpec = spring(dampingRatio = 0.8f, stiffness = 300f),
        label = "iconScale"
    )
    val alpha by animateFloatAsState(
        targetValue = if (appear) 1f else 0f,
        animationSpec = tween(500),
        label = "alpha"
    )
    val offsetYFloat by animateFloatAsState(
        targetValue = if (appear) 0f else 20f,
        animationSpec = spring(dampingRatio = 0.8f, stiffness = 300f),
        label = "textOffset"
    )
    val offsetY = offsetYFloat.dp

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(horizontal = 32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Icon
        Box(
            modifier = Modifier.graphicsLayer {
                scaleX = scale; scaleY = scale; this.alpha = alpha
            },
            contentAlignment = Alignment.Center
        ) {
            when {
                data.showLogo -> {
                    Box(
                        modifier = Modifier
                            .size(100.dp)
                            .clip(CircleShape)
                            .background(
                                Brush.linearGradient(
                                    listOf(
                                        Color(0xFF007AFF),
                                        Color(0xFF06B6D4),
                                        Color(0xFF007AFF).copy(alpha = 0.6f)
                                    )
                                )
                            ),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = "F",
                            fontSize = 50.sp,
                            fontWeight = FontWeight.Bold,
                            color = Color.White
                        )
                    }
                }
                data.showFingerprint -> {
                    Box(
                        modifier = Modifier
                            .size(100.dp)
                            .clip(CircleShape)
                            .background(data.iconColor.copy(alpha = 0.15f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Filled.Fingerprint,
                            contentDescription = null,
                            tint = data.iconColor,
                            modifier = Modifier.size(52.dp)
                        )
                    }
                }
                else -> {
                    Box(
                        modifier = Modifier
                            .size(100.dp)
                            .clip(CircleShape)
                            .background(data.iconColor.copy(alpha = 0.15f)),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = data.icon,
                            contentDescription = null,
                            tint = data.iconColor,
                            modifier = Modifier.size(44.dp)
                        )
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(24.dp))

        Text(
            text = localized(isRussian, data.titleRu, data.titleEn),
            fontSize = 28.sp,
            fontWeight = FontWeight.Bold,
            color = colors.textPrimary,
            textAlign = TextAlign.Center,
            modifier = Modifier
                .graphicsLayer { this.alpha = alpha }
                .offset(y = offsetY)
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = localized(isRussian, data.descriptionRu, data.descriptionEn),
            fontSize = 16.sp,
            color = colors.textSecondary,
            textAlign = TextAlign.Center,
            lineHeight = 22.sp,
            modifier = Modifier
                .graphicsLayer { this.alpha = alpha }
                .offset(y = offsetY)
        )
    }
}

// ============================================================
// Reusable glass action button (used across auth screens)
// ============================================================

@Composable
internal fun GlassActionButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    enabled: Boolean = true
) {
    val colors = FinderTheme.colors
    Surface(
        shape = RoundedCornerShape(16.dp),
        color = colors.glassButtonBackground,
        border = androidx.compose.foundation.BorderStroke(0.5.dp, colors.glassBorder),
        modifier = modifier
            .fillMaxWidth()
            .graphicsLayer { alpha = if (enabled) 1f else 0.5f }
            .clickable(enabled = enabled, onClick = onClick)
    ) {
        Box(
            modifier = Modifier.padding(vertical = 16.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = text,
                fontWeight = FontWeight.SemiBold,
                fontSize = 17.sp,
                color = Color.White
            )
        }
    }
}
