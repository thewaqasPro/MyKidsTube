package com.mykidstube.android.ui

import android.content.pm.ActivityInfo
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.lifecycle.lifecycleScope
import androidx.navigation.compose.rememberNavController
import com.mykidstube.android.data.repository.KidsTubeRepository
import com.mykidstube.android.data.store.SecurityService
import com.mykidstube.android.data.store.SettingsDataStore
import com.mykidstube.android.domain.model.AppOrientationMode
import com.mykidstube.android.ui.navigation.AppNavHost
import com.mykidstube.android.ui.navigation.NavRoutes
import com.mykidstube.android.ui.theme.KidColors
import com.mykidstube.android.ui.theme.KidsTubeTheme
import com.mykidstube.android.worker.DownloadManager
import dagger.hilt.android.AndroidEntryPoint
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject

@AndroidEntryPoint
class MainActivity : ComponentActivity() {

    @Inject
    lateinit var settingsDataStore: SettingsDataStore

    @Inject
    lateinit var repository: KidsTubeRepository

    @Inject
    lateinit var securityService: SecurityService

    @Inject
    lateinit var downloadManager: DownloadManager

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        // Observe and apply orientation preference
        lifecycleScope.launch {
            settingsDataStore.orientationMode.collect { mode ->
                requestedOrientation = when (mode) {
                    AppOrientationMode.PORTRAIT -> ActivityInfo.SCREEN_ORIENTATION_PORTRAIT
                    AppOrientationMode.LANDSCAPE -> ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
                    AppOrientationMode.AUTO -> ActivityInfo.SCREEN_ORIENTATION_UNSPECIFIED
                }
            }
        }

        setContent {
            KidsTubeTheme {
                var isPairedState by remember { mutableStateOf<Boolean?>(null) }

                LaunchedEffect(Unit) {
                    val paired = settingsDataStore.isDevicePaired.first()
                    isPairedState = paired
                }

                if (isPairedState == null) {
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .background(KidColors.bgDark),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(color = KidColors.primary)
                    }
                } else {
                    val navController = rememberNavController()
                    val startDestination = if (isPairedState == true) NavRoutes.HOME else NavRoutes.PAIRING

                    AppNavHost(
                        navController = navController,
                        startDestination = startDestination,
                        repository = repository,
                        securityService = securityService,
                        downloadManager = downloadManager
                    )
                }
            }
        }
    }
}
