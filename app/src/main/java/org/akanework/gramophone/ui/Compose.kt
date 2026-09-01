package org.akanework.gramophone.ui

import android.content.SharedPreferences
import android.os.Build
import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.LocalContentColor
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.contentColorFor
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.lifecycle.lifecycleScope
import androidx.preference.PreferenceManager
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.channels.trySendBlocking
import kotlinx.coroutines.flow.SharingStarted.Companion.WhileSubscribed
import kotlinx.coroutines.flow.callbackFlow
import kotlinx.coroutines.flow.stateIn
import org.akanework.gramophone.logic.enableEdgeToEdgeProperly
import org.akanework.gramophone.logic.getBooleanStrict

abstract class BaseComposeActivity : AppCompatActivity() {
    private lateinit var prefs: SharedPreferences
    val pureDarkFlow by lazy {
        callbackFlow {
            val cb = SharedPreferences.OnSharedPreferenceChangeListener { _, key ->
                if (key == "pureDark") {
                    trySendBlocking(prefs.getBooleanStrict("pureDark", false))
                }
            }
            prefs.registerOnSharedPreferenceChangeListener(cb)
            awaitClose {
                prefs.unregisterOnSharedPreferenceChangeListener(cb)
            }
        }.stateIn(
            lifecycleScope, WhileSubscribed(),
            prefs.getBooleanStrict("pureDark", false)
        )
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        prefs = PreferenceManager.getDefaultSharedPreferences(applicationContext)
        super.onCreate(savedInstanceState)
        enableEdgeToEdgeProperly()
    }
}

@Composable
fun BaseComposeActivity.GramophoneTheme(
    useDarkTheme: Boolean = isSystemInDarkTheme(),
    content: @Composable () -> Unit
) {
    val pureDark by pureDarkFlow.collectAsState()
    GramophoneTheme(useDarkTheme, pureDark, content)
}

@Composable
fun GramophoneTheme(
    useDarkTheme: Boolean = isSystemInDarkTheme(),
    pureDark: Boolean,
    content: @Composable () -> Unit
) {
    // Liquid Glass: iOS-26 style palette, static by design.
    val liquidDark = darkColorScheme(
        primary = Color(0xFF0A84FF),
        onPrimary = Color.White,
        primaryContainer = Color(0xFF004B7C),
        onPrimaryContainer = Color(0xFFB8DCFF),
        secondary = Color(0xFF8AB4D8),
        onSecondary = Color(0xFF0E2439),
        secondaryContainer = Color(0xFF24384C),
        onSecondaryContainer = Color(0xFFD2E4FF),
        tertiary = Color(0xFF4DD5CC),
        onTertiary = Color(0xFF003735),
        tertiaryContainer = Color(0xFF004F4B),
        onTertiaryContainer = Color(0xFF9AE8E2),
        error = Color(0xFFFF453A),
        onError = Color.White,
        errorContainer = Color(0xFF5C0B05),
        onErrorContainer = Color(0xFFFFDAD4),
        background = Color(0xFF000000),
        onBackground = Color(0xFFF2F2F7),
        surface = Color(0xFF000000),
        onSurface = Color(0xFFF2F2F7),
        surfaceVariant = Color(0xFF26262A),
        onSurfaceVariant = Color(0xFFA8A8AE),
        outline = Color(0xFF545458),
        outlineVariant = Color(0xFF38383A),
        inverseSurface = Color(0xFFF2F2F7),
        inverseOnSurface = Color(0xFF1C1C1E),
        inversePrimary = Color(0xFF0066CC),
        surfaceDim = Color(0xFF000000),
        surfaceBright = Color(0xFF2A2A2E),
        surfaceContainerLowest = Color(0xFF0A0A0C),
        surfaceContainerLow = Color(0xFF131315),
        surfaceContainer = Color(0xFF1C1C1E),
        surfaceContainerHigh = Color(0xFF242426),
        surfaceContainerHighest = Color(0xFF2C2C2E),
    )
    val liquidLight = lightColorScheme(
        primary = Color(0xFF007AFF),
        onPrimary = Color.White,
        primaryContainer = Color(0xFFD6EBFF),
        onPrimaryContainer = Color(0xFF00304F),
        secondary = Color(0xFF5A7EA2),
        onSecondary = Color.White,
        secondaryContainer = Color(0xFFE2E8F0),
        onSecondaryContainer = Color(0xFF1A2A3B),
        tertiary = Color(0xFF00C7BE),
        onTertiary = Color.White,
        tertiaryContainer = Color(0xFFCCF5F2),
        onTertiaryContainer = Color(0xFF003431),
        error = Color(0xFFFF3B30),
        onError = Color.White,
        errorContainer = Color(0xFFFFE0DD),
        onErrorContainer = Color(0xFF3A0002),
        background = Color(0xFFF2F2F7),
        onBackground = Color(0xFF1C1C1E),
        surface = Color(0xFFFBFBFD),
        onSurface = Color(0xFF1C1C1E),
        surfaceVariant = Color(0xFFE5E5EA),
        onSurfaceVariant = Color(0xFF3A3A3C),
        outline = Color(0xFF8E8E93),
        outlineVariant = Color(0xFFD1D1D6),
        inverseSurface = Color(0xFF2C2C2E),
        inverseOnSurface = Color(0xFFF2F2F7),
        inversePrimary = Color(0xFF64B5FF),
        surfaceDim = Color(0xFFD8D8DC),
        surfaceBright = Color(0xFFFBFBFD),
        surfaceContainerLowest = Color(0xFFFFFFFF),
        surfaceContainerLow = Color(0xFFF7F7FA),
        surfaceContainer = Color(0xFFF1F1F4),
        surfaceContainerHigh = Color(0xFFEBEBEF),
        surfaceContainerHighest = Color(0xFFE5E5E9),
    )
    MaterialTheme(
        colorScheme = ((if (useDarkTheme) liquidDark else liquidLight).let {
                if (pureDark) {
                    it.copy(
                        background = Color.Black,
                        surface = Color.Black,
                        surfaceVariant = Color.Black,
                        surfaceContainerLowest = Color.Black,
                        surfaceContainerLow = Color.Black,
                        surfaceContainer = Color.Black,
                        surfaceContainerHigh = Color.Black,
                        surfaceContainerHighest = Color.Black,
                    )
                } else it
            }), content = {
            CompositionLocalProvider(
                LocalContentColor provides contentColorFor(MaterialTheme.colorScheme.surface),
            ) {
                content()
            }
        }
    )
}
