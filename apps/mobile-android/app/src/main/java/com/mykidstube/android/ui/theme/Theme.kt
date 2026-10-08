package com.mykidstube.android.ui.theme

import android.app.Activity
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

private val DarkColorScheme = darkColorScheme(
    primary = KidColors.primary,
    onPrimary = KidColors.textLight,
    secondary = KidColors.accent,
    onSecondary = KidColors.bgDark,
    tertiary = KidColors.sky,
    background = KidColors.bgDark,
    onBackground = KidColors.textLight,
    surface = KidColors.surfaceDark,
    onSurface = KidColors.textLight,
    surfaceVariant = KidColors.cardElevated,
    onSurfaceVariant = KidColors.textMuted,
    outline = KidColors.borderDark
)

@Composable
fun KidsTubeTheme(
    content: @Composable () -> Unit
) {
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = KidColors.bgDark.toArgb()
            window.navigationBarColor = KidColors.bgDark.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = false
            WindowCompat.getInsetsController(window, view).isAppearanceLightNavigationBars = false
        }
    }

    MaterialTheme(
        colorScheme = DarkColorScheme,
        typography = Typography,
        content = content
    )
}
