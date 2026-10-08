package com.mykidstube.android.ui.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.mykidstube.android.data.repository.KidsTubeRepository
import com.mykidstube.android.data.store.SecurityService
import com.mykidstube.android.domain.model.VideoItem
import com.mykidstube.android.ui.screens.*
import com.mykidstube.android.worker.DownloadManager

@Composable
fun AppNavHost(
    navController: NavHostController,
    startDestination: String,
    repository: KidsTubeRepository,
    securityService: SecurityService,
    downloadManager: DownloadManager
) {
    val allVideos by repository.allVideos.collectAsState(initial = emptyList())

    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        composable(NavRoutes.PAIRING) {
            DevicePairingScreen(
                onPaired = { isDefaultPin ->
                    if (isDefaultPin) {
                        navController.navigate(NavRoutes.parentSecurity(forceChange = true)) {
                            popUpTo(NavRoutes.PAIRING) { inclusive = true }
                        }
                    } else {
                        navController.navigate(NavRoutes.HOME) {
                            popUpTo(NavRoutes.PAIRING) { inclusive = true }
                        }
                    }
                }
            )
        }

        composable(NavRoutes.HOME) {
            KidHomeScreen(
                onPlayVideo = { video ->
                    if (video.isShort) {
                        navController.navigate(NavRoutes.shorts(video.id))
                    } else {
                        navController.navigate(NavRoutes.player(video.id))
                    }
                },
                onOpenShorts = { video ->
                    navController.navigate(NavRoutes.shorts(video.id))
                },
                onNavigateToParentDashboard = {
                    navController.navigate(NavRoutes.PARENT_DASHBOARD)
                },
                onNavigateToParentSecurity = { isForce ->
                    navController.navigate(NavRoutes.parentSecurity(isForce))
                },
                securityService = securityService,
                repository = repository
            )
        }

        composable(
            route = NavRoutes.PLAYER,
            arguments = listOf(navArgument("videoId") { type = NavType.StringType })
        ) { backStackEntry ->
            val videoId = backStackEntry.arguments?.getString("videoId") ?: ""
            val video = allVideos.firstOrNull { it.id == videoId }
                ?: VideoItem(id = videoId, title = "Video")

            KidPlayerScreen(
                video = video,
                onNavigateBack = { navController.popBackStack() },
                onOpenShorts = { shortVideo ->
                    navController.navigate(NavRoutes.shorts(shortVideo.id)) {
                        popUpTo(NavRoutes.PLAYER) { inclusive = true }
                    }
                },
                repository = repository,
                downloadManager = downloadManager
            )
        }

        composable(
            route = NavRoutes.SHORTS,
            arguments = listOf(navArgument("videoId") { type = NavType.StringType })
        ) { backStackEntry ->
            val videoId = backStackEntry.arguments?.getString("videoId") ?: ""
            val video = allVideos.firstOrNull { it.id == videoId }
                ?: VideoItem(id = videoId, title = "Short Video", duration = 30)

            KidShortsFeedScreen(
                initialVideo = video,
                onNavigateBack = { navController.popBackStack() },
                onNavigateToRegularPlayer = { regularVideo ->
                    navController.navigate(NavRoutes.player(regularVideo.id)) {
                        popUpTo(NavRoutes.SHORTS) { inclusive = true }
                    }
                },
                repository = repository
            )
        }

        composable(NavRoutes.PARENT_DASHBOARD) {
            ParentDashboardScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToMediaLibrary = { navController.navigate(NavRoutes.PARENT_MEDIA) },
                onNavigateToStorage = { navController.navigate(NavRoutes.PARENT_STORAGE) },
                onNavigateToServer = { navController.navigate(NavRoutes.PARENT_SERVER) },
                onNavigateToSecurity = { navController.navigate(NavRoutes.parentSecurity(false)) },
                onNavigateToAnalytics = { navController.navigate(NavRoutes.PARENT_ANALYTICS) }
            )
        }

        composable(
            route = NavRoutes.PARENT_SECURITY,
            arguments = listOf(navArgument("force") {
                type = NavType.BoolType
                defaultValue = false
            })
        ) { backStackEntry ->
            val isForceChange = backStackEntry.arguments?.getBoolean("force") ?: false
            ParentSecurityScreen(
                onNavigateBack = { navController.popBackStack() },
                isForceChange = isForceChange,
                onSuccess = {
                    if (isForceChange) {
                        navController.navigate(NavRoutes.HOME) {
                            popUpTo(0) { inclusive = true }
                        }
                    } else {
                        navController.popBackStack()
                    }
                }
            )
        }

        composable(NavRoutes.PARENT_MEDIA) {
            ParentMediaLibraryScreen(
                onNavigateBack = { navController.popBackStack() },
                onPlayVideo = { video ->
                    if (video.isShort) {
                        navController.navigate(NavRoutes.shorts(video.id))
                    } else {
                        navController.navigate(NavRoutes.player(video.id))
                    }
                }
            )
        }

        composable(NavRoutes.PARENT_STORAGE) {
            ParentStorageScreen(
                onNavigateBack = { navController.popBackStack() },
                onPlayVideo = { video ->
                    if (video.isShort) {
                        navController.navigate(NavRoutes.shorts(video.id))
                    } else {
                        navController.navigate(NavRoutes.player(video.id))
                    }
                }
            )
        }

        composable(NavRoutes.PARENT_SERVER) {
            ParentServerScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(NavRoutes.PARENT_ANALYTICS) {
            ParentAnalyticsScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }
    }
}
