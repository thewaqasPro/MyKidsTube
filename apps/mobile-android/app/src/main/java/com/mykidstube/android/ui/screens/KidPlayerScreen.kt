package com.mykidstube.android.ui.screens

import android.app.Activity
import android.net.Uri
import android.view.ViewGroup
import android.view.WindowManager
import androidx.annotation.OptIn
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.media3.common.MediaItem
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.ui.PlayerView
import com.mykidstube.android.data.repository.KidsTubeRepository
import com.mykidstube.android.domain.model.DownloadStatus
import com.mykidstube.android.domain.model.VideoItem
import com.mykidstube.android.ui.components.KidEmbedPlayer
import com.mykidstube.android.ui.components.TouchLockOverlay
import com.mykidstube.android.ui.components.VideoTile
import com.mykidstube.android.ui.theme.KidColors
import com.mykidstube.android.worker.DownloadManager
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.io.File

@OptIn(UnstableApi::class)
@Composable
fun KidPlayerScreen(
    video: VideoItem,
    onNavigateBack: () -> Unit,
    onOpenShorts: (VideoItem) -> Unit,
    repository: KidsTubeRepository,
    downloadManager: DownloadManager,
    viewModel: HomeViewModel = hiltViewModel()
) {
    val context = LocalContext.current
    val activity = context as? Activity
    val scope = rememberCoroutineScope()

    var currentVideo by remember { mutableStateOf(video) }
    var isLocked by remember { mutableStateOf(false) }
    var useEmbedFallback by remember { mutableStateOf(false) }
    var isPlaying by remember { mutableStateOf(true) }

    val allVideos by repository.allVideos.collectAsState(initial = emptyList())
    val favoriteIds by repository.favoriteIds.collectAsState(initial = emptySet())
    val downloadProgressMap by downloadManager.downloadProgressMap.collectAsState()

    val isFavorite = favoriteIds.contains(currentVideo.id)
    val downloadProgress = downloadProgressMap[currentVideo.id]

    // Related videos queue
    val relatedVideos = remember(allVideos, currentVideo) {
        allVideos.filter { it.id != currentVideo.id && !it.isShort }
    }

    // Keep-awake during playback
    DisposableEffect(Unit) {
        activity?.window?.addFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        onDispose {
            activity?.window?.clearFlags(WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON)
        }
    }

    // Redirect short video to shorts feed
    LaunchedEffect(currentVideo) {
        if (currentVideo.isShort) {
            onOpenShorts(currentVideo)
        }
    }

    // Watch Time Tracker
    var accumulatedSeconds by remember { mutableIntStateOf(0) }
    LaunchedEffect(currentVideo, isPlaying) {
        accumulatedSeconds = 0
        while (isPlaying) {
            delay(1000)
            accumulatedSeconds++
            if (accumulatedSeconds >= 300) {
                repository.recordWatchSession(
                    videoId = currentVideo.id,
                    videoTitle = currentVideo.title,
                    categoryId = currentVideo.categoryId,
                    secondsWatched = accumulatedSeconds,
                    videoDuration = currentVideo.duration,
                    isCompleted = false,
                    isSkipped = false
                )
                accumulatedSeconds = 0
            }
        }
    }

    // Flush watch session on exit or change
    DisposableEffect(currentVideo.id) {
        onDispose {
            if (accumulatedSeconds > 0) {
                val secs = accumulatedSeconds
                val duration = currentVideo.duration
                val isCompleted = duration > 0 && secs >= (duration * 0.75).toInt()
                val isSkipped = secs < 10
                scope.launch {
                    repository.recordWatchSession(
                        videoId = currentVideo.id,
                        videoTitle = currentVideo.title,
                        categoryId = currentVideo.categoryId,
                        secondsWatched = secs,
                        videoDuration = duration,
                        isCompleted = isCompleted,
                        isSkipped = isSkipped
                    )
                }
            }
        }
    }

    // Native ExoPlayer Controller
    val exoPlayer = remember(currentVideo, useEmbedFallback) {
        if (useEmbedFallback || currentVideo.needsEmbed) {
            null
        } else {
            ExoPlayer.Builder(context).build().apply {
                playWhenReady = true

                val mediaSourceUri = if (currentVideo.isOfflineReady && currentVideo.localFilePath != null) {
                    Uri.fromFile(File(currentVideo.localFilePath!!))
                } else {
                    Uri.parse(currentVideo.streamUrl)
                }

                setMediaItem(MediaItem.fromUri(mediaSourceUri))
                prepare()

                addListener(object : Player.Listener {
                    override fun onPlayerError(error: PlaybackException) {
                        // On stream / native error, immediately fallback to sandboxed embed player
                        useEmbedFallback = true
                    }

                    override fun onIsPlayingChanged(playing: Boolean) {
                        isPlaying = playing
                    }
                })
            }
        }
    }

    DisposableEffect(exoPlayer) {
        onDispose {
            exoPlayer?.release()
        }
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(KidColors.bgDark)
    ) {
        Column(modifier = Modifier.fillMaxSize()) {
            // 1. Video Player Area (16:9)
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .aspectRatio(16f / 9f)
                    .background(Color.Black)
            ) {
                if (useEmbedFallback || currentVideo.needsEmbed) {
                    KidEmbedPlayer(
                        youtubeId = currentVideo.effectiveYoutubeId,
                        autoPlay = true,
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
                                useController = !isLocked
                            }
                        },
                        update = { playerView ->
                            playerView.player = exoPlayer
                            playerView.useController = !isLocked
                        },
                        modifier = Modifier.fillMaxSize()
                    )
                }

                // Top Back Button (only when not locked)
                if (!isLocked) {
                    IconButton(
                        onClick = onNavigateBack,
                        modifier = Modifier
                            .align(Alignment.TopStart)
                            .padding(8.dp)
                            .background(Color.Black.copy(alpha = 0.5f), CircleShape)
                    ) {
                        Icon(
                            imageVector = Icons.Rounded.ArrowBack,
                            contentDescription = "Back",
                            tint = Color.White
                        )
                    }
                }
            }

            // 2. Video Info & Actions
            LazyColumn(
                modifier = Modifier
                    .fillMaxWidth()
                    .weight(1f)
                    .padding(horizontal = 16.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                item {
                    Column(
                        modifier = Modifier.padding(top = 14.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        Text(
                            text = currentVideo.title,
                            color = Color.White,
                            fontSize = 17.sp,
                            fontWeight = FontWeight.Bold
                        )

                        Text(
                            text = "${currentVideo.channelName} • ${currentVideo.durationFormatted}",
                            color = KidColors.textMuted,
                            fontSize = 13.sp
                        )

                        // Action Buttons Bar
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 8.dp),
                            horizontalArrangement = Arrangement.SpaceAround,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            // Favorite Button
                            IconButton(
                                onClick = { scope.launch { repository.toggleFavorite(currentVideo.id) } },
                                modifier = Modifier
                                    .clip(RoundedCornerShape(20.dp))
                                    .background(KidColors.cardDark)
                                    .padding(horizontal = 12.dp, vertical = 6.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    Icon(
                                        imageVector = if (isFavorite) Icons.Rounded.Star else Icons.Rounded.StarBorder,
                                        contentDescription = "Favorite",
                                        tint = if (isFavorite) KidColors.accent else Color.White,
                                        modifier = Modifier.size(18.dp)
                                    )
                                    Text(
                                        if (isFavorite) "Favorited" else "Favorite",
                                        color = Color.White,
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                }
                            }

                            // Download Button
                            IconButton(
                                onClick = {
                                    if (!currentVideo.isOfflineReady) {
                                        scope.launch { downloadManager.enqueueDownload(currentVideo) }
                                    }
                                },
                                modifier = Modifier
                                    .clip(RoundedCornerShape(20.dp))
                                    .background(KidColors.cardDark)
                                    .padding(horizontal = 12.dp, vertical = 6.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    if (currentVideo.isOfflineReady) {
                                        Icon(
                                            imageVector = Icons.Rounded.CheckCircle,
                                            contentDescription = "Downloaded",
                                            tint = KidColors.mint,
                                            modifier = Modifier.size(18.dp)
                                        )
                                        Text("Saved", color = KidColors.mint, fontSize = 12.sp, fontWeight = FontWeight.Bold)
                                    } else if (downloadProgress?.status == DownloadStatus.DOWNLOADING) {
                                        CircularProgressIndicator(
                                            progress = { downloadProgress.progress },
                                            color = KidColors.sky,
                                            strokeWidth = 2.dp,
                                            modifier = Modifier.size(16.dp)
                                        )
                                        Text("${(downloadProgress.progress * 100).toInt()}%", color = Color.White, fontSize = 12.sp)
                                    } else {
                                        Icon(
                                            imageVector = Icons.Rounded.Download,
                                            contentDescription = "Download",
                                            tint = Color.White,
                                            modifier = Modifier.size(18.dp)
                                        )
                                        Text("Download", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                                    }
                                }
                            }

                            // Toddler Lock Button
                            IconButton(
                                onClick = { isLocked = true },
                                modifier = Modifier
                                    .clip(RoundedCornerShape(20.dp))
                                    .background(KidColors.cardDark)
                                    .padding(horizontal = 12.dp, vertical = 6.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    Icon(
                                        imageVector = Icons.Rounded.Lock,
                                        contentDescription = "Lock Screen",
                                        tint = KidColors.accent,
                                        modifier = Modifier.size(18.dp)
                                    )
                                    Text("Lock", color = Color.White, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                                }
                            }
                        }

                        Divider(color = KidColors.borderDark, thickness = 1.dp)
                    }
                }

                // Related Videos Queue
                item {
                    Text(
                        "Up Next",
                        color = Color.White,
                        fontSize = 15.sp,
                        fontWeight = FontWeight.Bold
                    )
                }

                items(relatedVideos, key = { it.id }) { relVideo ->
                    VideoTile(
                        video = relVideo,
                        onClick = {
                            currentVideo = relVideo
                            useEmbedFallback = false
                        }
                    )
                }

                item { Spacer(modifier = Modifier.height(20.dp)) }
            }
        }

        // 3. Toddler Touch Lock Overlay
        TouchLockOverlay(
            isLocked = isLocked,
            onLock = { isLocked = true },
            onUnlock = { isLocked = false },
            showLockButton = false
        )
    }
}
