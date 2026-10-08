package com.mykidstube.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.mykidstube.android.ui.theme.KidColors
import com.mykidstube.android.worker.DownloadWorker

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ParentDashboardScreen(
    onNavigateBack: () -> Unit,
    onNavigateToMediaLibrary: () -> Unit,
    onNavigateToStorage: () -> Unit,
    onNavigateToServer: () -> Unit,
    onNavigateToSecurity: () -> Unit,
    onNavigateToAnalytics: () -> Unit,
    viewModel: ParentViewModel = hiltViewModel()
) {
    val allVideos by viewModel.allVideos.collectAsState()
    val downloadedVideos by viewModel.downloadedVideos.collectAsState()
    val cachedBytes by viewModel.cachedBytes.collectAsState()
    val isServerOnline by viewModel.isServerOnline.collectAsState()
    val isSyncing by viewModel.isSyncing.collectAsState()
    val refreshNotice by viewModel.refreshNotice.collectAsState()
    val pendingPruneCount by viewModel.pendingPruneCount.collectAsState()
    val isUsingDefaultPin by viewModel.isUsingDefaultPin.collectAsState()

    LaunchedEffect(Unit) {
        viewModel.refreshStorageMetrics()
        viewModel.checkDefaultPin()
    }

    Scaffold(
        containerColor = KidColors.bgDark,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        "Parent Command Center",
                        color = KidColors.textLight,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(
                            imageVector = Icons.Rounded.ArrowBackIosNew,
                            contentDescription = "Back",
                            tint = Color.White,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                },
                actions = {
                    IconButton(onClick = { viewModel.syncCatalog() }) {
                        if (isSyncing) {
                            CircularProgressIndicator(
                                color = KidColors.primary,
                                strokeWidth = 2.dp,
                                modifier = Modifier.size(20.dp)
                            )
                        } else {
                            Icon(
                                imageVector = Icons.Rounded.Sync,
                                contentDescription = "Sync Catalog",
                                tint = KidColors.sky
                            )
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = KidColors.bgDark)
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(20.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            // 1. Mandatory Default PIN Warning
            if (isUsingDefaultPin) {
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = KidColors.red.copy(alpha = 0.15f)),
                    border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(KidColors.red.copy(alpha = 0.5f)))
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Rounded.Warning,
                                contentDescription = null,
                                tint = KidColors.red,
                                modifier = Modifier.size(24.dp)
                            )
                            Text(
                                text = "Default PIN (1234) Active",
                                color = KidColors.red,
                                fontSize = 15.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        Text(
                            text = "To protect kids from unauthorized setting modifications, please set a secure custom PIN immediately.",
                            color = KidColors.textMuted,
                            fontSize = 13.sp
                        )
                        Button(
                            onClick = onNavigateToSecurity,
                            shape = RoundedCornerShape(12.dp),
                            colors = ButtonDefaults.buttonColors(
                                containerColor = KidColors.red,
                                contentColor = Color.White
                            )
                        ) {
                            Text("Set Custom PIN Now", fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }

            // 2. Prune Guard Safety Cap Alert
            if (pendingPruneCount > 0 || refreshNotice != null) {
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = KidColors.accent.copy(alpha = 0.15f)),
                    border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(KidColors.accent.copy(alpha = 0.5f)))
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Text(
                            text = refreshNotice ?: "Catalog deletions held for parent confirmation.",
                            color = KidColors.accent,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                        if (pendingPruneCount > 0) {
                            Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                Button(
                                    onClick = { viewModel.confirmPendingPrune() },
                                    colors = ButtonDefaults.buttonColors(containerColor = KidColors.red)
                                ) {
                                    Text("Confirm Removal", fontSize = 12.sp)
                                }
                                OutlinedButton(
                                    onClick = { viewModel.dismissPendingPrune() }
                                ) {
                                    Text("Keep Local Videos", fontSize = 12.sp, color = Color.White)
                                }
                            }
                        } else {
                            TextButton(onClick = { viewModel.dismissRefreshNotice() }) {
                                Text("Dismiss", color = KidColors.accent)
                            }
                        }
                    }
                }
            }

            // 3. Executive KPI Dashboard Grid
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                KpiCard(
                    title = "Total Catalog",
                    value = "${allVideos.size}",
                    subtitle = "Curated videos",
                    icon = Icons.Rounded.VideoLibrary,
                    accentColor = KidColors.primary,
                    modifier = Modifier.weight(1f)
                )
                KpiCard(
                    title = "Offline Ready",
                    value = "${downloadedVideos.size}",
                    subtitle = DownloadWorker.formatBytes(cachedBytes),
                    icon = Icons.Rounded.DownloadDone,
                    accentColor = KidColors.mint,
                    modifier = Modifier.weight(1f)
                )
            }

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                KpiCard(
                    title = "Cloud Status",
                    value = if (isServerOnline) "Online" else "Offline",
                    subtitle = if (isServerOnline) "Edge synced" else "Offline playback",
                    icon = if (isServerOnline) Icons.Rounded.CloudDone else Icons.Rounded.CloudOff,
                    accentColor = if (isServerOnline) KidColors.sky else KidColors.red,
                    modifier = Modifier.weight(1f)
                )
                KpiCard(
                    title = "Disk Cache",
                    value = DownloadWorker.formatBytes(cachedBytes),
                    subtitle = "Safe on device",
                    icon = Icons.Rounded.Storage,
                    accentColor = KidColors.violet,
                    modifier = Modifier.weight(1f)
                )
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                "Management & Controls",
                color = KidColors.textLight,
                fontSize = 16.sp,
                fontWeight = FontWeight.Bold
            )

            // 4. Navigation Control Tiles
            ManagementTile(
                title = "Media Library & Ingest",
                subtitle = "Queue new YouTube URLs, search, and delete videos",
                icon = Icons.Rounded.PlayCircle,
                badgeColor = KidColors.primary,
                onClick = onNavigateToMediaLibrary
            )

            ManagementTile(
                title = "Storage & Downloads",
                subtitle = "Download All, inspect disk usage, clear offline cache",
                icon = Icons.Rounded.FolderSpecial,
                badgeColor = KidColors.mint,
                onClick = onNavigateToStorage
            )

            ManagementTile(
                title = "Parent Security & PIN",
                subtitle = "Change PIN, manage gate security policies",
                icon = Icons.Rounded.Lock,
                badgeColor = KidColors.accent,
                onClick = onNavigateToSecurity
            )

            ManagementTile(
                title = "Screen Time & Analytics",
                subtitle = "Inspect viewing trends, completion rates, loved videos",
                icon = Icons.Rounded.BarChart,
                badgeColor = KidColors.violet,
                onClick = onNavigateToAnalytics
            )

            ManagementTile(
                title = "Server & Pairing Configuration",
                subtitle = "Manage VPS API endpoint, ping latency, pairing code",
                icon = Icons.Rounded.Dns,
                badgeColor = KidColors.sky,
                onClick = onNavigateToServer
            )
        }
    }
}

@Composable
private fun KpiCard(
    title: String,
    value: String,
    subtitle: String,
    icon: ImageVector,
    accentColor: Color,
    modifier: Modifier = Modifier
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = KidColors.cardDark),
        border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(KidColors.borderDark)),
        modifier = modifier
    ) {
        Column(
            modifier = Modifier.padding(14.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(title, color = KidColors.textMuted, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
                Icon(imageVector = icon, contentDescription = null, tint = accentColor, modifier = Modifier.size(18.dp))
            }
            Text(value, color = Color.White, fontSize = 20.sp, fontWeight = FontWeight.Bold)
            Text(subtitle, color = KidColors.textTertiary, fontSize = 11.sp)
        }
    }
}

@Composable
private fun ManagementTile(
    title: String,
    subtitle: String,
    icon: ImageVector,
    badgeColor: Color,
    onClick: () -> Unit
) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = KidColors.cardDark),
        border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(KidColors.borderDark)),
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(44.dp)
                    .clip(RoundedCornerShape(12.dp))
                    .background(badgeColor.copy(alpha = 0.15f))
                    .border(1.dp, badgeColor.copy(alpha = 0.35f), RoundedCornerShape(12.dp)),
                contentAlignment = Alignment.Center
            ) {
                Icon(imageVector = icon, contentDescription = null, tint = badgeColor, modifier = Modifier.size(24.dp))
            }

            Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(3.dp)) {
                Text(title, color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                Text(subtitle, color = KidColors.textMuted, fontSize = 12.sp, lineHeight = 16.sp)
            }

            Icon(
                imageVector = Icons.Rounded.ChevronRight,
                contentDescription = null,
                tint = KidColors.textTertiary,
                modifier = Modifier.size(22.dp)
            )
        }
    }
}
