package com.mykidstube.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
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
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ParentMediaLibraryScreen(
    onNavigateBack: () -> Unit,
    onPlayVideo: (VideoItem) -> Unit,
    viewModel: ParentViewModel = hiltViewModel()
) {
    val allVideos by viewModel.allVideos.collectAsState()
    val categories by viewModel.categories.collectAsState()

    var showAddForm by remember { mutableStateOf(false) }
    var ingestUrl by remember { mutableStateOf("") }
    var selectedCategory by remember { mutableStateOf("cartoons") }
    var selectedQuality by remember { mutableStateOf("720p") }
    var isIngesting by remember { mutableStateOf(false) }
    var ingestMessage by remember { mutableStateOf<String?>(null) }

    var searchQuery by remember { mutableStateOf("") }
    var filterCategory by remember { mutableStateOf("all") }
    val selectedVideoIds = remember { mutableStateListOf<String>() }
    var videoToDelete by remember { mutableStateOf<VideoItem?>(null) }
    var showBulkDeleteDialog by remember { mutableStateOf(false) }

    val scope = rememberCoroutineScope()

    val filteredVideos = remember(allVideos, searchQuery, filterCategory) {
        allVideos.filter { video ->
            val matchesCategory = filterCategory == "all" || video.categoryId == filterCategory
            val matchesSearch = searchQuery.isEmpty() ||
                    video.title.contains(searchQuery, ignoreCase = true) ||
                    video.channelName.contains(searchQuery, ignoreCase = true)
            matchesCategory && matchesSearch
        }
    }

    Scaffold(
        containerColor = KidColors.bgDark,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        if (selectedVideoIds.isNotEmpty()) "${selectedVideoIds.size} Selected" else "Media Library",
                        color = Color.White,
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
                    if (selectedVideoIds.isNotEmpty()) {
                        IconButton(onClick = { showBulkDeleteDialog = true }) {
                            Icon(imageVector = Icons.Rounded.DeleteSweep, contentDescription = "Delete Selected", tint = KidColors.red)
                        }
                    } else {
                        IconButton(onClick = { showAddForm = !showAddForm }) {
                            Icon(
                                imageVector = if (showAddForm) Icons.Rounded.Close else Icons.Rounded.Add,
                                contentDescription = "Add Video",
                                tint = KidColors.primary
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
        ) {
            // 1. Ingest URL Drawer / Form
            if (showAddForm) {
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = KidColors.cardDark),
                    border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(KidColors.primary.copy(alpha = 0.5f))),
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp)
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Text("Add YouTube Video", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)

                        OutlinedTextField(
                            value = ingestUrl,
                            onValueChange = { ingestUrl = it },
                            label = { Text("YouTube URL (watch?v= or /shorts/)") },
                            singleLine = true,
                            modifier = Modifier.fillMaxWidth(),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedTextColor = Color.White,
                                unfocusedTextColor = Color.White,
                                focusedBorderColor = KidColors.primary,
                                unfocusedBorderColor = KidColors.borderDark
                            )
                        )

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.spacedBy(10.dp)
                        ) {
                            // Quality select
                            listOf("720p", "1080p", "480p").forEach { quality ->
                                val isSelected = selectedQuality == quality
                                FilterChip(
                                    selected = isSelected,
                                    onClick = { selectedQuality = quality },
                                    label = { Text(quality) },
                                    colors = FilterChipDefaults.filterChipColors(
                                        selectedContainerColor = KidColors.primary,
                                        selectedLabelColor = Color.White
                                    )
                                )
                            }
                        }

                        if (ingestMessage != null) {
                            Text(ingestMessage!!, color = KidColors.mint, fontSize = 12.sp)
                        }

                        Button(
                            onClick = {
                                if (ingestUrl.isNotEmpty()) {
                                    isIngesting = true
                                    scope.launch {
                                        val success = viewModel.submitIngestUrl(ingestUrl, selectedCategory, selectedQuality)
                                        isIngesting = false
                                        if (success) {
                                            ingestMessage = "Video queued! Downloading metadata..."
                                            ingestUrl = ""
                                        } else {
                                            ingestMessage = "Failed to queue video. Check server and URL."
                                        }
                                    }
                                }
                            },
                            modifier = Modifier.fillMaxWidth(),
                            colors = ButtonDefaults.buttonColors(containerColor = KidColors.primary)
                        ) {
                            if (isIngesting) {
                                CircularProgressIndicator(color = Color.White, modifier = Modifier.size(18.dp), strokeWidth = 2.dp)
                            } else {
                                Text("Queue Download", fontWeight = FontWeight.Bold)
                            }
                        }
                    }
                }
            }

            // 2. Search & Filter Bar
            OutlinedTextField(
                value = searchQuery,
                onValueChange = { searchQuery = it },
                placeholder = { Text("Search library...", color = KidColors.textMuted) },
                leadingIcon = { Icon(Icons.Rounded.Search, contentDescription = null, tint = KidColors.textMuted) },
                trailingIcon = {
                    if (searchQuery.isNotEmpty()) {
                        IconButton(onClick = { searchQuery = "" }) {
                            Icon(Icons.Rounded.Close, contentDescription = null, tint = KidColors.textMuted)
                        }
                    }
                },
                singleLine = true,
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 6.dp),
                shape = RoundedCornerShape(14.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White,
                    focusedBorderColor = KidColors.borderDark,
                    unfocusedBorderColor = KidColors.borderDark
                )
            )

            // Category Chips Row
            LazyRow(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 6.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                item {
                    val isSelected = filterCategory == "all"
                    FilterChip(
                        selected = isSelected,
                        onClick = { filterCategory = "all" },
                        label = { Text("All (${allVideos.size})") },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = KidColors.sky,
                            selectedLabelColor = KidColors.bgDark,
                            containerColor = KidColors.cardDark,
                            labelColor = KidColors.textMuted
                        )
                    )
                }

                items(categories) { cat ->
                    val isSelected = filterCategory == cat.id
                    FilterChip(
                        selected = isSelected,
                        onClick = { filterCategory = cat.id },
                        label = { Text(cat.name) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = KidColors.sky,
                            selectedLabelColor = KidColors.bgDark,
                            containerColor = KidColors.cardDark,
                            labelColor = KidColors.textMuted
                        )
                    )
                }
            }

            // 3. Videos List
            LazyColumn(
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                items(filteredVideos, key = { it.id }) { video ->
                    val isSelected = selectedVideoIds.contains(video.id)
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Checkbox(
                            checked = isSelected,
                            onCheckedChange = { checked ->
                                if (checked) selectedVideoIds.add(video.id) else selectedVideoIds.remove(video.id)
                            },
                            colors = CheckboxDefaults.colors(
                                checkedColor = KidColors.primary,
                                uncheckedColor = KidColors.textTertiary
                            )
                        )
                        Box(modifier = Modifier.weight(1f)) {
                            VideoTile(
                                video = video,
                                onClick = { onPlayVideo(video) },
                                onDelete = { videoToDelete = video }
                            )
                        }
                    }
                }
            }
        }
    }

    // Single Delete Dialog
    videoToDelete?.let { video ->
        AlertDialog(
            onDismissRequest = { videoToDelete = null },
            title = { Text("Delete Video?", color = Color.White) },
            text = { Text("Are you sure you want to remove '${video.title}' from the catalog?", color = KidColors.textMuted) },
            confirmButton = {
                Button(
                    onClick = {
                        scope.launch {
                            viewModel.deleteVideos(listOf(video.id))
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

    // Bulk Delete Dialog
    if (showBulkDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showBulkDeleteDialog = false },
            title = { Text("Delete ${selectedVideoIds.size} Videos?", color = Color.White) },
            text = { Text("This will remove the selected videos from both the cloud catalog and local offline storage.", color = KidColors.textMuted) },
            confirmButton = {
                Button(
                    onClick = {
                        scope.launch {
                            viewModel.deleteVideos(selectedVideoIds.toList())
                            selectedVideoIds.clear()
                            showBulkDeleteDialog = false
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = KidColors.red)
                ) {
                    Text("Delete All Selected")
                }
            },
            dismissButton = {
                TextButton(onClick = { showBulkDeleteDialog = false }) {
                    Text("Cancel", color = Color.White)
                }
            },
            containerColor = KidColors.cardDark
        )
    }
}
