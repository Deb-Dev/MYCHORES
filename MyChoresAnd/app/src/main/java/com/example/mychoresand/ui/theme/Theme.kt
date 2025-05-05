package com.example.mychoresand.ui.theme

import android.app.Activity
import android.os.Build
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.dynamicDarkColorScheme
import androidx.compose.material3.dynamicLightColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalView
import androidx.core.view.WindowCompat

// Light theme colors
private val LightColorScheme = lightColorScheme(
    primary = Primary,
    onPrimary = Color.White,
    primaryContainer = Color(0xFFD9E1FF),
    onPrimaryContainer = Color(0xFF001544),
    secondary = Secondary,
    onSecondary = Color.White,
    secondaryContainer = Color(0xFFEEDCFF),
    onSecondaryContainer = Color(0xFF270058),
    tertiary = Color(0xFF79747E),
    onTertiary = Color.White,
    tertiaryContainer = Color(0xFFE8DEF8),
    onTertiaryContainer = Color(0xFF1D1B20),
    error = Error,
    onError = Color.White,
    errorContainer = Color(0xFFFFDAD6),
    onErrorContainer = Color(0xFF410002),
    background = Background,
    onBackground = TextPrimary,
    surface = Background,
    onSurface = TextPrimary,
    outline = Color(0xFF79747E),
    surfaceVariant = Color(0xFFE7E0EC),
    onSurfaceVariant = Color(0xFF49454F)
)

// Dark theme colors
private val DarkColorScheme = darkColorScheme(
    primary = PrimaryDark,
    onPrimary = Color(0xFF002A77),
    primaryContainer = Color(0xFF3A4E98),
    onPrimaryContainer = Color(0xFFD9E1FF),
    secondary = SecondaryDark,
    onSecondary = Color(0xFF410085),
    secondaryContainer = Color(0xFF5C28A1),
    onSecondaryContainer = Color(0xFFEEDCFF),
    tertiary = Color(0xFFCBBFD9),
    onTertiary = Color(0xFF332D41),
    tertiaryContainer = Color(0xFF4A4458),
    onTertiaryContainer = Color(0xFFE8DEF8),
    error = ErrorDark,
    onError = Color(0xFF690005),
    errorContainer = Color(0xFF93000A),
    onErrorContainer = Color(0xFFFFDAD6),
    background = BackgroundDark,
    onBackground = TextPrimaryDark,
    surface = BackgroundDark,
    onSurface = TextPrimaryDark,
    outline = Color(0xFF948F99),
    surfaceVariant = Color(0xFF49454F),
    onSurfaceVariant = Color(0xFFCAC4CF)
)

// Custom color provider
data class CustomColors(
    val cardBackground: Color,
    val textSecondary: Color,
    val success: Color
)

val LocalCustomColors = staticCompositionLocalOf {
    CustomColors(
        cardBackground = CardBackground,
        textSecondary = TextSecondary,
        success = Success
    )
}

/**
 * MyChores theme composable function
 */
@Composable
fun MyChoresTheme(
    darkTheme: Boolean = isSystemInDarkTheme(),
    // Dynamic color is available on Android 12+
    dynamicColor: Boolean = false,
    content: @Composable () -> Unit
) {
    val colorScheme = when {
        dynamicColor && Build.VERSION.SDK_INT >= Build.VERSION_CODES.S -> {
            val context = LocalContext.current
            if (darkTheme) dynamicDarkColorScheme(context) else dynamicLightColorScheme(context)
        }
        darkTheme -> DarkColorScheme
        else -> LightColorScheme
    }
    
    // Custom colors based on theme
    val customColors = if (darkTheme) {
        CustomColors(
            cardBackground = CardBackgroundDark,
            textSecondary = TextSecondaryDark,
            success = SuccessDark
        )
    } else {
        CustomColors(
            cardBackground = CardBackground,
            textSecondary = TextSecondary,
            success = Success
        )
    }
    
    // Update status bar color
    val view = LocalView.current
    if (!view.isInEditMode) {
        SideEffect {
            val window = (view.context as Activity).window
            window.statusBarColor = colorScheme.primary.toArgb()
            WindowCompat.getInsetsController(window, view).isAppearanceLightStatusBars = !darkTheme
        }
    }
    
    CompositionLocalProvider(LocalCustomColors provides customColors) {
        MaterialTheme(
            colorScheme = colorScheme,
            typography = Typography,
            content = content
        )
    }
}