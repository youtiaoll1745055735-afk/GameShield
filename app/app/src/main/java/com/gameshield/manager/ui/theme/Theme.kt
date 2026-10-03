package com.gameshield.manager.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.ui.graphics.Color

object StudioColors {
    val Accent = Color(0xFF22D3EE)
    val AccentDim = Color(0x2E22D3EE)
    val Blue = Color(0xFF3B82F6)
    val Green = Color(0xFF4ADE80)
    val BgDark = Color(0xFF0B0F14)
    val Surface = Color(0xFF141A22)
    val Surface2 = Color(0xFF1A222C)
    val TextPrimary = Color(0xFFE6EDF3)
    val TextSecondary = Color(0xFF8A97A5)
    val Outline = Color(0xFF252F3A)
    val Danger = Color(0xFFF87171)
    val Warning = Color(0xFFFBBF24)
    val BgPreviewDark = Color(0xFF0D1218)
    val BgPreviewLight = Color(0xFFE9EDF2)
}

private val DarkScheme = darkColorScheme(
    primary = StudioColors.Accent,
    onPrimary = Color(0xFF00343C),
    secondary = StudioColors.Blue,
    tertiary = StudioColors.Green,
    background = StudioColors.BgDark,
    onBackground = StudioColors.TextPrimary,
    surface = StudioColors.Surface,
    onSurface = StudioColors.TextPrimary,
    surfaceVariant = StudioColors.Surface2,
    onSurfaceVariant = StudioColors.TextSecondary,
    outline = StudioColors.Outline,
    error = StudioColors.Danger,
)

@Composable
fun CrosshairStudioTheme(amoled: Boolean = false, content: @Composable () -> Unit) {
    val scheme = if (amoled) {
        DarkScheme.copy(background = Color.Black, surface = Color(0xFF0A0E12))
    } else {
        DarkScheme
    }
    MaterialTheme(colorScheme = scheme, content = content)
}
