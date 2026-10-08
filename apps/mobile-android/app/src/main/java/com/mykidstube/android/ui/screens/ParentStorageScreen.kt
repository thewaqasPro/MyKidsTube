package com.mykidstube.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.mykidstube.android.domain.model.VideoItem
import com.mykidstube.android.ui.components.VideoTile
import com.mykidstube.android.ui.theme.KidColors
import com.mykidstube.android.worker.DownloadWorker
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ParentStorageScreen(
    onNavigateBack: () -> Unit,
    onPlayVideo: (VideoItem) -> Unit,
    viewModel: ParentViewModel = hiltViewModel()
) {
    val allVideos by viewModel.allVideos.collectAsState()
    val downloadedVideos by viewModel.downloadedVideos.collectAsState()
    val cachedBytes by viewModel.cachedBytes.collectAsState()
    val freeBytes by viewModel.freeBytes.collectAsState()

    var isDownloadingAll by remember { mutableStateOf(false) }
    var downloadAllStatus by remember { mutableStateOf<String?>(null) }
    var showClearConfirmDialog by remember { mutableStateOf(false) }
    var videoToDelete by remember { mutableStateOf<VideoItem?>(null) }

    val scope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        viewModel.refreshStorageMetrics()
    }

    Scaffold(
        containerColor = KidColors.bgDark,
        topBar = {
            TopAppBar(
                title = { Text("Storage & Downloads", color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(imageVector = Icons.Rounded.ArrowBackIosNew, contentDescription = "Back", tint = Color.White, modifier = Modifier.size(20.dp))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = KidColors.bgDark)
            )
        }
    ) { paddingValues ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .padding(horizontal = 20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // 1. Storage Gauge Card
            item {
                Card(
                    shape = RoundedCornerShape(18.dp),
                    colors = CardDefaults.cardColors(containerColor = KidColors.cardDark),
                    border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(KidColors.borderDark)),
                    modifier = Modifier.fillMaxWidth().padding(top = 10.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(18.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text("App Media Usage", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                            Text(
                                DownloadWorker.formatBytes(cachedBytes),
                                color = KidColors.sky,
                                fontSize = 16.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }

                        // Usage Progress Bar
                        val totalEstimated = (cachedBytes + freeBytes).coerceAtLeast(1L)
                        val fraction = (cachedBytes.toFloat() / totalEstimated.toFloat()).coerceIn(0f, 1f)
                        LinearProgressIndicator(
                            progress = { fraction },
                            color = KidColors.sky,
                            trackColor = KidColors.borderDark,
                            modifier = Modifier.fillMaxWidth().height(8.dp).clip(RoundedCornerShape(4.dp))
                        )

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween
                        ) {
                            Text("Free: ${DownloadWorker.formatBytes(freeBytes)}", color = KidColors.textMuted, fontSize = 12.sp)
                            Text("${downloadedVideos.size} / ${allVideos.size} offline", color = KidColors.textMuted, fontSize = 12.sp)
                        }
                    }
                }
            }

            // 2. Action Buttons (Download All, Clear Storage, Cache Reset)
            item {
                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                    if (downloadAllStatus != null) {
                        Text(
                            downloadAllStatus!!,
                            color = KidColors.accent,
                            fontSize = 12.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    }

                    Button(
                        onClick = {
                            isDownloadingAll = true
                            downloadAllStatus = "Enqueuing downloads..."
                            scope.launch {
                                val error = viewModel.downloadAllVideos { done, total ->
                                    downloadAllStatus = "Enqueued $done / $total videos..."
                                }
                                isDownloadingAll = false
                                downloadAllStatus = error ?: "All available videos queued for offline play!"
                            }
                        },
                        modifier = Modifier.fillMaxWidth().height(48.dp),
                        shape = RoundedCornerShape(14.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = KidColors.primary)
                    ) {
                        Icon(imageVector = Icons.Rounded.Download, contentDescription = null, modifier = Modifier.size(18.dp))
                        Spacer(modifier = Modifier.width(8.dp))
                        Text("Download All (${allVideos.size - downloadedVideos.size} Pending)", fontWeight = FontWeight.Bold)
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        OutlinedButton(
                            onClick = { showClearConfirmDialog = true },
                            modifier = Modifier.weight(1f).height(46.dp),
                            shape = RoundedCornerShape(14.dp),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = KidColors.red)
                        ) {
                            Icon(imageVector = Icons.Rounded.DeleteSweep, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Clear Media", fontSize = 12.sp)
                        }

                        OutlinedButton(
                            onClick = {
                                scope.launch { viewModel.resetCache() }
                            },
                            modifier = Modifier.weight(1f).height(46.dp),
                            shape = RoundedCornerShape(14.dp),
                            colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.White)
                        ) {
                            Icon(imageVector = Icons.Rounded.Refresh, contentDescription = null, modifier = Modifier.size(16.dp))
                            Spacer(modifier = Modifier.width(6.dp))
                            Text("Reset Cache", fontSize = 12.sp)
                        }
                    }
                }
            }

            // 3. Downloaded Videos List Section
            item {
                Text(
                    "Downloaded Files (${downloadedVideos.size})",
                    color = Color.White,
                    fontSize = 15.sp,
                    fontWeight = FontWeight.Bold
                )
            }

            if (downloadedVideos.isEmpty()) {
                item {
                    Text(
                        "No videos currently downloaded for offline play.",
                        color = KidColors.textMuted,
                        fontSize = 13.sp,
                        modifier = Modifier.padding(vertical = 12.dp)
                    )
                }
            } else {
                items(downloadedVideos, key = { it.id }) { video ->
                    VideoTile(
                        video = video,
                        onClick = { onPlayVideo(video) },
                        onDelete = { videoToDelete = video }
                    )
                }
            }

            item { Spacer(modifier = Modifier.height(20.dp)) }
        }
    }

    // Clear Storage Confirm Dialog
    if (showClearConfirmDialog) {
        AlertDialog(
            onDismissRequest = { showClearConfirmDialog = false },
            title = { Text("Clear Offline Storage?", color = Color.White) },
            text = { Text("This will delete all locally cached video and thumbnail files. They can be re-downloaded later.", color = KidColors.textMuted) },
            confirmButton = {
                Button(
                    onClick = {
                        scope.launch {
                            viewModel.clearAllStorage()
                            showClearConfirmDialog = false
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = KidColors.red)
                ) {
                    Text("Clear All")
                }
            },
            dismissButton = {
                TextButton(onClick = { showClearConfirmDialog = false }) {
                    Text("Cancel", color = Color.White)
                }
            },
            containerColor = KidColors.cardDark
        )
    }

    // Delete Single File Dialog
    videoToDelete?.let { video ->
        AlertDialog(
            onDismissRequest = { videoToDelete = null },
            title = { Text("Delete Downloaded Video?", color = Color.White) },
            text = { Text("Remove offline file for '${video.title}'?", color = KidColors.textMuted) },
            confirmButton = {
                Button(
                    onClick = {
                        scope.launch {
                            viewModel.deleteDownloadedVideo(video)
                            videoToDelete = null
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = KidColors.red)
                ) {
                    Text("Delete")
                }
            },
            dismissButton = {
                TextButton(onClick = { videoToDelete = null }) {
                    Text("Cancel", color = Color.White)
                }
            },
            containerColor = KidColors.cardDark
        )
    }
}
