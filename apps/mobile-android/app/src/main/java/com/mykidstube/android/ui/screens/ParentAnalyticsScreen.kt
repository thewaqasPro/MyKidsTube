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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.mykidstube.android.data.db.TopVideoRow
import com.mykidstube.android.ui.theme.KidColors
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ParentAnalyticsScreen(
    onNavigateBack: () -> Unit,
    viewModel: ParentViewModel = hiltViewModel()
) {
    val analyticsData by viewModel.analyticsData.collectAsState()
    val isSyncingCloud by viewModel.isSyncingCloud.collectAsState()
    var syncResultMsg by remember { mutableStateOf<String?>(null) }

    val scope = rememberCoroutineScope()

    LaunchedEffect(Unit) {
        viewModel.loadAnalytics()
    }

    val todaySecs = (analyticsData["today_seconds"] as? Number)?.toLong() ?: 0L
    val totalSecs = (analyticsData["total_seconds"] as? Number)?.toLong() ?: 0L
    val totalSessions = (analyticsData["total_sessions"] as? Number)?.toInt() ?: 0
    val completionRate = (analyticsData["completion_rate"] as? Number)?.toInt() ?: 0
    val skipRate = (analyticsData["skip_rate"] as? Number)?.toInt() ?: 0
    val unsyncedCount = (analyticsData["unsynced_count"] as? Number)?.toInt() ?: 0
    val lovedVideos = (analyticsData["loved_videos"] as? List<*>)?.filterIsInstance<TopVideoRow>() ?: emptyList()
    val skippedVideos = (analyticsData["skipped_videos"] as? List<*>)?.filterIsInstance<TopVideoRow>() ?: emptyList()

    fun formatSeconds(seconds: Long): String {
        if (seconds <= 0) return "0m"
        val hours = seconds / 3600
        val minutes = (seconds % 3600) / 60
        return if (hours > 0) "${hours}h ${minutes}m" else "${minutes}m"
    }

    Scaffold(
        containerColor = KidColors.bgDark,
        topBar = {
            TopAppBar(
                title = { Text("Screen Time & Analytics", color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(imageVector = Icons.Rounded.ArrowBackIosNew, contentDescription = "Back", tint = Color.White, modifier = Modifier.size(20.dp))
                    }
                },
                actions = {
                    IconButton(
                        onClick = {
                            scope.launch {
                                val (success, count) = viewModel.syncAnalyticsToCloud()
                                syncResultMsg = if (success) {
                                    if (count > 0) "Synced $count sessions to Cloudflare!" else "All sessions already synced!"
                                } else {
                                    "Cloud sync failed. Check server connection."
                                }
                            }
                        }
                    ) {
                        if (isSyncingCloud) {
                            CircularProgressIndicator(color = KidColors.sky, modifier = Modifier.size(18.dp), strokeWidth = 2.dp)
                        } else {
                            Icon(imageVector = Icons.Rounded.CloudUpload, contentDescription = "Sync", tint = KidColors.sky)
                        }
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
            if (syncResultMsg != null) {
                item {
                    Text(
                        syncResultMsg!!,
                        color = KidColors.mint,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.SemiBold,
                        modifier = Modifier.padding(top = 8.dp)
                    )
                }
            }

            // 1. KPI Cards Row 1: Today vs Total
            item {
                Row(
                    modifier = Modifier.fillMaxWidth().padding(top = 10.dp),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Card(
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = KidColors.cardDark),
                        border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(KidColors.borderDark)),
                        modifier = Modifier.weight(1f)
                    ) {
                        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text("Today's Watch Time", color = KidColors.textMuted, fontSize = 12.sp)
                            Text(formatSeconds(todaySecs), color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                            Text("Local tracking", color = KidColors.textTertiary, fontSize = 11.sp)
                        }
                    }

                    Card(
                        shape = RoundedCornerShape(16.dp),
                        colors = CardDefaults.cardColors(containerColor = KidColors.cardDark),
                        border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(KidColors.borderDark)),
                        modifier = Modifier.weight(1f)
                    ) {
                        Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                            Text("All-Time Watch Time", color = KidColors.textMuted, fontSize = 12.sp)
                            Text(formatSeconds(totalSecs), color = Color.White, fontSize = 22.sp, fontWeight = FontWeight.Bold)
                            Text("$totalSessions total sessions", color = KidColors.textTertiary, fontSize = 11.sp)
                        }
                    }
                }
            }

            // 2. Attention Funnel Card: Completion vs Skip Rate
            item {
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = KidColors.cardDark),
                    border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(KidColors.borderDark)),
                    modifier = Modifier.fillMaxWidth()
                ) {
                    Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        Text("Attention & Engagement Funnel", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)

                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Column {
                                Text("Completion Rate", color = KidColors.mint, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                                Text("$completionRate%", color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                            }
                            Column(horizontalAlignment = Alignment.End) {
                                Text("Skip Rate (<10s)", color = KidColors.red, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                                Text("$skipRate%", color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold)
                            }
                        }

                        LinearProgressIndicator(
                            progress = { (completionRate / 100f).coerceIn(0f, 1f) },
                            color = KidColors.mint,
                            trackColor = KidColors.red.copy(alpha = 0.5f),
                            modifier = Modifier.fillMaxWidth().height(8.dp)
                        )
                    }
                }
            }

            // 3. Most Loved Videos
            item {
                Text("Most Loved Videos (Finished)", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            }

            if (lovedVideos.isEmpty()) {
                item {
                    Text("No completed video sessions recorded yet.", color = KidColors.textMuted, fontSize = 13.sp)
                }
            } else {
                items(lovedVideos) { item ->
                    Card(
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = KidColors.cardDark),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth().padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Icon(Icons.Rounded.Favorite, contentDescription = null, tint = KidColors.primary, modifier = Modifier.size(20.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(item.videoTitle ?: item.videoId, color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Bold, maxLines = 1)
                                Text("Completed ${item.playCount} times (${formatSeconds(item.totalSecs)})", color = KidColors.textMuted, fontSize = 11.sp)
                            }
                        }
                    }
                }
            }

            // 4. Most Skipped Videos
            item {
                Text("Frequently Skipped Videos (<10s)", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            }

            if (skippedVideos.isEmpty()) {
                item {
                    Text("No skipped sessions recorded.", color = KidColors.textMuted, fontSize = 13.sp)
                }
            } else {
                items(skippedVideos) { item ->
                    Card(
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(containerColor = KidColors.cardDark),
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth().padding(12.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Icon(Icons.Rounded.FastForward, contentDescription = null, tint = KidColors.accent, modifier = Modifier.size(20.dp))
                            Column(modifier = Modifier.weight(1f)) {
                                Text(item.videoTitle ?: item.videoId, color = Color.White, fontSize = 13.sp, fontWeight = FontWeight.Bold, maxLines = 1)
                                Text("Skipped ${item.playCount} times early", color = KidColors.textMuted, fontSize = 11.sp)
                            }
                        }
                    }
                }
            }

            item { Spacer(modifier = Modifier.height(20.dp)) }
        }
    }
}
