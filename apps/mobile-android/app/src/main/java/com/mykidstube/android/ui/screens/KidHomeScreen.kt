package com.mykidstube.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.mykidstube.android.data.repository.KidsTubeRepository
import com.mykidstube.android.data.store.SecurityService
import com.mykidstube.android.domain.model.VideoItem
import com.mykidstube.android.ui.components.ChildAvatar
import com.mykidstube.android.ui.components.OrientationModeSwitch
import com.mykidstube.android.ui.components.VideoCard
import com.mykidstube.android.ui.theme.KidColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun KidHomeScreen(
    onPlayVideo: (VideoItem) -> Unit,
    onOpenShorts: (VideoItem) -> Unit,
    onNavigateToParentDashboard: () -> Unit,
    onNavigateToParentSecurity: (isForceChange: Boolean) -> Unit,
    securityService: SecurityService,
    repository: KidsTubeRepository,
    viewModel: HomeViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    var showProfileSheet by remember { mutableStateOf(false) }
    var showParentGate by remember { mutableStateOf(false) }

    // Filter videos based on category, search, and offline-only mode
    val sourceVideos = if (uiState.isOfflineOnly) uiState.downloadedVideos else uiState.allVideos

    val filteredVideos = remember(sourceVideos, uiState.selectedCategoryId, uiState.searchQuery, uiState.favoriteIds) {
        sourceVideos.filter { video ->
            val matchesCategory = when (uiState.selectedCategoryId) {
                "all" -> true
                "favorites" -> uiState.favoriteIds.contains(video.id)
                "shorts" -> video.isShort
                else -> video.categoryId == uiState.selectedCategoryId
            }
            val matchesSearch = uiState.searchQuery.isEmpty() ||
                    video.title.contains(uiState.searchQuery, ignoreCase = true) ||
                    video.channelName.contains(uiState.searchQuery, ignoreCase = true)
            matchesCategory && matchesSearch
        }
    }

    val shortsList = remember(sourceVideos) {
        sourceVideos.filter { it.isShort }
    }

    Scaffold(
        containerColor = KidColors.bgDark,
        topBar = {
            if (uiState.isSearchOpen) {
                TopAppBar(
                    title = {
                        OutlinedTextField(
                            value = uiState.searchQuery,
                            onValueChange = { viewModel.setSearchQuery(it) },
                            placeholder = { Text("Search fun videos...", color = KidColors.textMuted) },
                            singleLine = true,
                            modifier = Modifier.fillMaxWidth(),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedTextColor = Color.White,
                                unfocusedTextColor = Color.White,
                                focusedBorderColor = Color.Transparent,
                                unfocusedBorderColor = Color.Transparent
                            )
                        )
                    },
                    navigationIcon = {
                        IconButton(onClick = { viewModel.toggleSearch(false) }) {
                            Icon(imageVector = Icons.Rounded.ArrowBack, contentDescription = "Close Search", tint = Color.White)
                        }
                    },
                    actions = {
                        if (uiState.searchQuery.isNotEmpty()) {
                            IconButton(onClick = { viewModel.setSearchQuery("") }) {
                                Icon(imageVector = Icons.Rounded.Close, contentDescription = "Clear", tint = KidColors.textMuted)
                            }
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = KidColors.bgDark)
                )
            } else {
                TopAppBar(
                    title = {
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            // Logo Badge
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(
                                        Brush.linearGradient(
                                            listOf(KidColors.primary, KidColors.accent)
                                        )
                                    )
                                    .padding(horizontal = 7.dp, vertical = 4.dp),
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(
                                    imageVector = Icons.Rounded.PlayArrow,
                                    contentDescription = null,
                                    tint = Color.White,
                                    modifier = Modifier.size(16.dp)
                                )
                            }
                            Text(
                                "KidsTube",
                                color = Color.White,
                                fontSize = 18.sp,
                                fontWeight = FontWeight.ExtraBold,
                                letterSpacing = (-0.3).sp
                            )
                        }
                    },
                    actions = {
                        // Profile Avatar Pill
                        uiState.activeProfile?.let { prof ->
                            Box(
                                modifier = Modifier
                                    .clip(RoundedCornerShape(20.dp))
                                    .background(KidColors.cardDark)
                                    .border(1.dp, KidColors.borderDark, RoundedCornerShape(20.dp))
                                    .clickable { showProfileSheet = true }
                                    .padding(horizontal = 8.dp, vertical = 4.dp)
                            ) {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    ChildAvatar(avatarIcon = prof.avatarIcon, size = 22.dp)
                                    Text(
                                        text = prof.name,
                                        color = Color.White,
                                        fontSize = 12.sp,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                }
                            }
                        }

                        // Search Button
                        IconButton(onClick = { viewModel.toggleSearch(true) }) {
                            Icon(imageVector = Icons.Rounded.Search, contentDescription = "Search", tint = Color.White)
                        }

                        // Offline Mode Toggle
                        IconButton(onClick = { viewModel.toggleOfflineOnly() }) {
                            Icon(
                                imageVector = if (uiState.isOfflineOnly) Icons.Rounded.CloudOff else Icons.Rounded.CloudDone,
                                contentDescription = "Offline Mode",
                                tint = if (uiState.isOfflineOnly) KidColors.accent else KidColors.textMuted
                            )
                        }

                        // Grown-Ups Gate Lock
                        IconButton(onClick = { showParentGate = true }) {
                            Icon(imageVector = Icons.Rounded.Lock, contentDescription = "Parent Gate", tint = KidColors.primary)
                        }
                    },
                    colors = TopAppBarDefaults.topAppBarColors(containerColor = KidColors.bgDark)
                )
            }
        }
    ) { paddingValues ->
        PullToRefreshBox(
            isRefreshing = uiState.isSyncing,
            onRefresh = { viewModel.syncCatalog() },
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // 1. Refresh Notice Banner
                if (uiState.refreshNotice != null) {
                    item {
                        Card(
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(containerColor = KidColors.accent.copy(alpha = 0.15f)),
                            border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(KidColors.accent.copy(alpha = 0.5f))),
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 16.dp, vertical = 4.dp)
                        ) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(12.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(
                                    text = uiState.refreshNotice!!,
                                    color = KidColors.accent,
                                    fontSize = 12.sp,
                                    modifier = Modifier.weight(1f)
                                )
                                TextButton(onClick = { viewModel.dismissNotice() }) {
                                    Text("Dismiss", color = KidColors.accent, fontSize = 11.sp)
                                }
                            }
                        }
                    }
                }

                // 2. Horizontal Category Filter Chips Bar
                item {
                    LazyRow(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 16.dp),
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        item {
                            CategoryFilterPill(
                                title = "All",
                                isSelected = uiState.selectedCategoryId == "all",
                                onClick = { viewModel.selectCategory("all") }
                            )
                        }

                        item {
                            CategoryFilterPill(
                                title = "⚡ Shorts",
                                isSelected = uiState.selectedCategoryId == "shorts",
                                onClick = { viewModel.selectCategory("shorts") }
                            )
                        }

                        item {
                            CategoryFilterPill(
                                title = "★ Favorites",
                                isSelected = uiState.selectedCategoryId == "favorites",
                                onClick = { viewModel.selectCategory("favorites") }
                            )
                        }

                        items(uiState.categories) { cat ->
                            CategoryFilterPill(
                                title = cat.name,
                                isSelected = uiState.selectedCategoryId == cat.id,
                                onClick = { viewModel.selectCategory(cat.id) }
                            )
                        }
                    }
                }

                // 3. Horizontal Shorts Shelf (shown on "all" or "shorts" view when shorts exist)
                if ((uiState.selectedCategoryId == "all" || uiState.selectedCategoryId == "shorts") && shortsList.isNotEmpty()) {
                    item {
                        Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 16.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(8.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Rounded.FlashOn,
                                    contentDescription = null,
                                    tint = KidColors.red,
                                    modifier = Modifier.size(20.dp)
                                )
                                Text(
                                    text = "Shorts",
                                    color = Color.White,
                                    fontSize = 16.sp,
                                    fontWeight = FontWeight.ExtraBold
                                )
                            }

                            LazyRow(
                                modifier = Modifier.fillMaxWidth(),
                                contentPadding = PaddingValues(horizontal = 16.dp),
                                horizontalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                items(shortsList, key = { "short_${it.id}" }) { shortVideo ->
                                    ShortsShelfCard(
                                        video = shortVideo,
                                        onClick = { onOpenShorts(shortVideo) }
                                    )
                                }
                            }
                        }
                    }
                }

                // 4. Main Videos Feed
                if (filteredVideos.isEmpty()) {
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 48.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Column(
                                horizontalAlignment = Alignment.CenterHorizontally,
                                verticalArrangement = Arrangement.spacedBy(12.dp)
                            ) {
                                Icon(
                                    imageVector = Icons.Rounded.VideoLibrary,
                                    contentDescription = null,
                                    tint = KidColors.textTertiary,
                                    modifier = Modifier.size(54.dp)
                                )
                                Text(
                                    text = if (uiState.isOfflineOnly) "No offline videos downloaded yet" else "No videos found in this shelf",
                                    color = KidColors.textMuted,
                                    fontSize = 14.sp,
                                    fontWeight = FontWeight.Medium
                                )
                                Button(
                                    onClick = { viewModel.syncCatalog() },
                                    colors = ButtonDefaults.buttonColors(containerColor = KidColors.primary),
                                    shape = RoundedCornerShape(16.dp)
                                ) {
                                    Icon(imageVector = Icons.Rounded.Refresh, contentDescription = null, modifier = Modifier.size(16.dp))
                                    Spacer(modifier = Modifier.width(6.dp))
                                    Text("Refresh Catalog")
                                }
                            }
                        }
                    }
                } else {
                    items(filteredVideos, key = { it.id }) { video ->
                        Box(modifier = Modifier.padding(horizontal = 16.dp)) {
                            VideoCard(
                                video = video,
                                onClick = { onPlayVideo(video) },
                                onToggleFavorite = { viewModel.toggleFavorite(video.id) },
                                isFavorite = uiState.favoriteIds.contains(video.id),
                                downloadProgress = uiState.downloadProgressMap[video.id]
                            )
                        }
                    }
                }

                item { Spacer(modifier = Modifier.height(24.dp)) }
            }
        }
    }

    // Profile Switcher Sheet
    if (showProfileSheet) {
        KidProfileSwitcherSheet(
            activeProfile = uiState.activeProfile,
            profiles = uiState.profiles,
            onSelectProfile = { viewModel.switchProfile(it) },
            onAddProfile = { name, avatar -> viewModel.addProfile(name, avatar) },
            onOpenParentGate = { showParentGate = true },
            onDismiss = { showProfileSheet = false }
        )
    }

    // Grown-Ups Gate Dialog
    if (showParentGate) {
        ParentGateDialog(
            onDismiss = { showParentGate = false },
            onSuccess = { isForceChange ->
                showParentGate = false
                if (isForceChange) {
                    onNavigateToParentSecurity(true)
                } else {
                    onNavigateToParentDashboard()
                }
            },
            securityService = securityService,
            repository = repository
        )
    }
}

@Composable
private fun CategoryFilterPill(
    title: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(18.dp))
            .background(if (isSelected) KidColors.sky else KidColors.cardDark)
            .border(1.dp, if (isSelected) KidColors.sky else KidColors.borderDark, RoundedCornerShape(18.dp))
            .clickable(onClick = onClick)
            .padding(horizontal = 14.dp, vertical = 7.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = title,
            color = if (isSelected) KidColors.bgDark else KidColors.textMuted,
            fontSize = 13.sp,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
        )
    }
}

@Composable
private fun ShortsShelfCard(
    video: VideoItem,
    onClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .width(135.dp)
            .height(220.dp)
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = KidColors.cardDark),
        border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(KidColors.borderDark))
    ) {
        Box(modifier = Modifier.fillMaxSize()) {
            AsyncImage(
                model = video.thumbnailUrl,
                contentDescription = video.title,
                contentScale = ContentScale.Crop,
                modifier = Modifier.fillMaxSize()
            )

            // Gradient scrim
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(
                        Brush.verticalGradient(
                            listOf(Color.Transparent, Color.Black.copy(alpha = 0.85f)),
                            startY = 120f
                        )
                    )
            )

            // Title at bottom
            Column(
                modifier = Modifier
                    .align(Alignment.BottomStart)
                    .padding(10.dp),
                verticalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Text(
                    text = video.title,
                    color = Color.White,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }
    }
}
