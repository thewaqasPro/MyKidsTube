package com.mykidstube.android.ui.screens

import android.app.Activity
import android.net.Uri
import android.view.ViewGroup
import android.view.WindowManager
import androidx.annotation.OptIn
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.pager.VerticalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.media3.common.MediaItem
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import com.mykidstube.android.data.repository.KidsTubeRepository
import com.mykidstube.android.domain.model.VideoItem
import com.mykidstube.android.ui.components.AmbientBlurBackground
import com.mykidstube.android.ui.components.KidEmbedPlayer
import com.mykidstube.android.ui.components.ShortsActionRail
import com.mykidstube.android.ui.components.TouchLockOverlay
import com.mykidstube.android.ui.theme.KidColors
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.File

@OptIn(UnstableApi::class)
@Composable
fun KidShortsFeedScreen(
    initialVideo: VideoItem,
    onNavigateBack: () -> Unit,
    onNavigateToRegularPlayer: (VideoItem) -> Unit,
    repository: KidsTubeRepository
) {
    val context = LocalContext.current
    val activity = context as? Activity
    val scope = rememberCoroutineScope()

    val allVideos by repository.allVideos.collectAsState(initial = emptyList())
    val favoriteIds by repository.favoriteIds.collectAsState(initial = emptySet())

    val shorts = remember(allVideos, initialVideo) {
        val filtered = allVideos.filter { it.isShort }
        if (filtered.isNotEmpty()) filtered else listOf(initialVideo)
    }

    val initialIndex = remember(shorts, initialVideo) {
        val idx = shorts.indexOfFirst { it.id == initialVideo.id }
        if (idx >= 0) idx else 0
    }

    val pagerState = rememberPagerState(initialPage = initialIndex, pageCount = { shorts.size })

    var isLocked by remember { mutableStateOf(false) }
    var isMuted by remember { mutableStateOf(false) }
    var autoAdvance by remember { mutableStateOf(true) }

    // If initial video wasn't a short, redirect to standard player
    LaunchedEffect(initialVideo) {
        if (!initialVideo.isShort) {
            onNavigateToRegularPlayer(initialVideo)
        }
    }

    // Keep screen on
    DisposableEffect(Unit) {
        activity?.window?.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        onDispose {
            activity?.window?.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    val currentShort = shorts.getOrNull(pagerState.currentPage) ?: initialVideo
    val isFavorite = favoriteIds.contains(currentShort.id)

    // Watch Time Tracker
    var accumulatedSeconds by remember { mutableIntStateOf(0) }
    LaunchedEffect(currentShort.id) {
        accumulatedSeconds = 0
        while (true) {
            delay(1000)
            accumulatedSeconds++
            if (accumulatedSeconds >= 300) {
                repository.recordWatchSession(
                    videoId = currentShort.id,
                    videoTitle = currentShort.title,
                    categoryId = currentShort.categoryId,
                    secondsWatched = accumulatedSeconds,
                    videoDuration = currentShort.duration,
                    isCompleted = false,
                    isSkipped = false
                )
                accumulatedSeconds = 0
            }
        }
    }

    DisposableEffect(currentShort.id) {
        onDispose {
            if (accumulatedSeconds > 0) {
                val secs = accumulatedSeconds
                val duration = currentShort.duration
                val isCompleted = duration > 0 && secs >= (duration * 0.75).toInt()
                val isSkipped = secs < 10
                scope.launch {
                    repository.recordWatchSession(
                        videoId = currentShort.id,
                        videoTitle = currentShort.title,
                        categoryId = currentShort.categoryId,
                        secondsWatched = secs,
                        videoDuration = duration,
                        isCompleted = isCompleted,
                        isSkipped = isSkipped
                    )
                }
            }
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(Color.Black)
    ) {
        VerticalPager(
            state = pagerState,
            modifier = Modifier.fillMaxSize(),
            userScrollEnabled = !isLocked
        ) { pageIndex ->
            val pageVideo = shorts.getOrNull(pageIndex) ?: return@VerticalPager
            val isCurrentPage = pagerState.currentPage == pageIndex

            ShortPageItem(
                video = pageVideo,
                isActive = isCurrentPage,
                isMuted = isMuted,
                autoAdvance = autoAdvance,
                onVideoEnded = {
                    if (autoAdvance && pageIndex < shorts.size - 1) {
                        scope.launch {
                            pagerState.animateScrollToPage(pageIndex + 1)
                        }
                    }
                }
            )
        }

        // Top Navigation Header (Back button)
        if (!isLocked) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(top = 28.dp, start = 16.dp, end = 16.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                IconButton(
                    onClick = onNavigateBack,
                    modifier = Modifier.background(Color.Black.copy(alpha = 0.45f), CircleShape)
                ) {
                    Icon(imageVector = Icons.Rounded.ArrowBack, contentDescription = "Back", tint = Color.White)
                }

                Text(
                    text = "Shorts",
                    color = Color.White,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.Bold
                )

                Spacer(modifier = Modifier.size(40.dp))
            }
        }

        // Action Rail on the right
        if (!isLocked) {
            ShortsActionRail(
                isFavorite = isFavorite,
                onToggleFavorite = { scope.launch { repository.toggleFavorite(currentShort.id) } },
                isMuted = isMuted,
                onToggleMute = { isMuted = !isMuted },
                autoAdvance = autoAdvance,
                onToggleAutoAdvance = { autoAdvance = !autoAdvance },
                onLock = { isLocked = true },
                modifier = Modifier.align(Alignment.BottomEnd)
            )
        }

        // Video Info at bottom left
        if (!isLocked) {
            Column(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(start = 16.dp, bottom = 32.dp, end = 80.dp),
                verticalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Text(
                    text = currentShort.title,
                    color = Color.White,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold,
                    maxLines = 2
                )
                Text(
                    text = currentShort.channelName,
                    color = KidColors.textMuted,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium
                )
            }
        }

        // Toddler Touch Lock Overlay
        TouchLockOverlay(
            isLocked = isLocked,
            onLock = { isLocked = true },
            onUnlock = { isLocked = false },
            showLockButton = false
        )
    }
}

@OptIn(UnstableApi::class)
@Composable
private fun ShortPageItem(
    video: VideoItem,
    isActive: Boolean,
    isMuted: Boolean,
    autoAdvance: Boolean,
    onVideoEnded: () -> Unit
) {
    val context = LocalContext.current
    var useEmbedFallback by remember { mutableStateOf(false) }

    val exoPlayer = remember(video, useEmbedFallback) {
        if (useEmbedFallback || video.needsEmbed) {
            null
        } else {
            val loadControl = androidx.media3.exoplayer.DefaultLoadControl.Builder()
                .setBufferDurationsMs(
                    15_000,
                    50_000,
                    500, // Instant playback startup
                    1_000
                )
                .build()

            ExoPlayer.Builder(context)
                .setLoadControl(loadControl)
                .build().apply {
                val mediaSourceUri = if (video.isOfflineReady && video.localFilePath != null) {
                    Uri.fromFile(File(video.localFilePath!!))
                } else {
                    Uri.parse(video.streamUrl)
                }

                setMediaItem(MediaItem.fromUri(mediaSourceUri))
                repeatMode = if (autoAdvance) Player.REPEAT_MODE_OFF else Player.REPEAT_MODE_ONE
                prepare()

                addListener(object : Player.Listener {
                    override fun onPlaybackStateChanged(playbackState: Int) {
                        if (playbackState == Player.STATE_ENDED) {
                            onVideoEnded()
                        }
                    }
                })
            }
        }
    }

    LaunchedEffect(isActive, isMuted) {
        exoPlayer?.let { player ->
            player.volume = if (isMuted) 0f else 1f
            if (isActive) {
                player.playWhenReady = true
                player.play()
            } else {
                player.pause()
            }
        }
    }

    DisposableEffect(exoPlayer) {
        onDispose {
            exoPlayer?.release()
        }
    }

    Box(modifier = Modifier.fillMaxSize()) {
        // Soft ambient blurred background
        AmbientBlurBackground(imageUrl = video.thumbnailUrl)

        if (useEmbedFallback || video.needsEmbed) {
            KidEmbedPlayer(
                youtubeId = video.effectiveYoutubeId,
                autoPlay = isActive,
                modifier = Modifier.fillMaxSize()
            )
        } else if (exoPlayer != null) {
            AndroidView(
                factory = { ctx ->
                    PlayerView(ctx).apply {
                        layoutParams = ViewGroup.LayoutParams(
                            ViewGroup.LayoutParams.MATCH_PARENT,
                            ViewGroup.LayoutParams.MATCH_PARENT
                        )
                        player = exoPlayer
                        useController = false
                        resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
                    }
                },
                update = { playerView ->
                    playerView.player = exoPlayer
                },
                modifier = Modifier.fillMaxSize()
            )
        }
    }
}
