package com.mykidstube.android.data.repository

import com.mykidstube.android.data.api.KidsTubeApi
import com.mykidstube.android.data.api.model.IngestRequestDto
import com.mykidstube.android.data.api.model.LoginRequestDto
import com.mykidstube.android.data.api.model.RegisterDeviceRequestDto
import com.mykidstube.android.data.api.model.WatchBatchRequestDto
import com.mykidstube.android.data.api.model.WatchEventPayloadDto
import com.mykidstube.android.data.db.*
import com.mykidstube.android.data.store.SecurityService
import com.mykidstube.android.data.store.SettingsDataStore
import com.mykidstube.android.domain.model.*
import com.mykidstube.android.worker.DownloadManager
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.*
import java.util.*
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class KidsTubeRepository @Inject constructor(
    private val api: KidsTubeApi,
    private val videoDao: VideoDao,
    private val categoryDao: CategoryDao,
    private val childProfileDao: ChildProfileDao,
    private val watchEventDao: WatchEventDao,
    private val favoriteDao: FavoriteDao,
    private val securityService: SecurityService,
    private val settingsDataStore: SettingsDataStore,
    private val downloadManager: DownloadManager
) {
    val allVideos: Flow<List<VideoItem>> = videoDao.getAllVideosFlow().map { entities ->
        entities.map { it.toDomain() }
    }

    val downloadedVideos: Flow<List<VideoItem>> = videoDao.getDownloadedVideosFlow().map { entities ->
        entities.map { it.toDomain() }
    }

    val categories: Flow<List<CategoryItem>> = categoryDao.getAllCategoriesFlow().map { entities ->
        entities.map { it.toDomain() }
    }

    val profiles: Flow<List<ChildProfile>> = childProfileDao.getAllProfilesFlow().map { entities ->
        entities.map { it.toDomain() }
    }

    val favoriteIds: Flow<Set<String>> = favoriteDao.getAllFavoriteIdsFlow().map { it.toSet() }

    private val _isServerOnline = MutableStateFlow(false)
    val isServerOnline: StateFlow<Boolean> = _isServerOnline.asStateFlow()

    private val _isSyncing = MutableStateFlow(false)
    val isSyncing: StateFlow<Boolean> = _isSyncing.asStateFlow()

    private val _refreshNotice = MutableStateFlow<String?>(null)
    val refreshNotice: StateFlow<String?> = _refreshNotice.asStateFlow()

    private val _pendingPruneVideoIds = MutableStateFlow<List<String>>(emptyList())
    val pendingPruneVideoIds: StateFlow<List<String>> = _pendingPruneVideoIds.asStateFlow()

    val pendingPruneCount: StateFlow<Int> = _pendingPruneVideoIds.map { it.size }
        .stateIn(CoroutineScope(Dispatchers.Default), SharingStarted.Eagerly, 0)

    private val repositoryScope = CoroutineScope(Dispatchers.IO + SupervisorJob())

    init {
        repositoryScope.launch {
            downloadManager.cleanupOrphanFiles()
        }
    }

    fun dismissRefreshNotice() {
        _refreshNotice.value = null
    }

    fun dismissPendingPrune() {
        _pendingPruneVideoIds.value = emptyList()
        _refreshNotice.value = null
    }

    suspend fun confirmPendingPrune() = withContext(Dispatchers.IO) {
        val idsToDelete = _pendingPruneVideoIds.value
        if (idsToDelete.isNotEmpty()) {
            for (id in idsToDelete) {
                downloadManager.deleteDownloaded(id, null)
            }
            videoDao.deleteByIds(idsToDelete)
            _pendingPruneVideoIds.value = emptyList()
            _refreshNotice.value = null
        }
    }

    suspend fun checkHealth(): Boolean = withContext(Dispatchers.IO) {
        try {
            val response = api.checkHealth()
            val online = response.isSuccessful && response.body()?.status == "ok"
            _isServerOnline.value = online
            online
        } catch (_: Exception) {
            _isServerOnline.value = false
            false
        }
    }

    suspend fun pingHealth(): Int? = withContext(Dispatchers.IO) {
        val start = System.currentTimeMillis()
        try {
            val response = api.checkHealth()
            if (response.isSuccessful) {
                val latency = (System.currentTimeMillis() - start).toInt()
                _isServerOnline.value = true
                latency
            } else {
                _isServerOnline.value = false
                null
            }
        } catch (_: Exception) {
            _isServerOnline.value = false
            null
        }
    }

    // --- Device Registration & Pairing ---
    suspend fun registerDevice(deviceName: String = "Kids Tablet"): Pair<String, String>? = withContext(Dispatchers.IO) {
        try {
            val response = api.registerDevice(RegisterDeviceRequestDto(deviceName = deviceName))
            if (response.isSuccessful && response.body() != null) {
                val body = response.body()!!
                Pair(body.deviceId, body.pairingCode)
            } else {
                null
            }
        } catch (_: Exception) {
            null
        }
    }

    suspend fun checkPairingStatus(pairingCode: String): String = withContext(Dispatchers.IO) {
        try {
            val response = api.checkDeviceStatus(pairingCode)
            if (response.isSuccessful && response.body() != null) {
                val body = response.body()!!
                if (body.status == "paired") {
                    val token = body.authToken
                    if (!token.isNullOrEmpty()) {
                        securityService.setDeviceToken(token)
                    }
                    settingsDataStore.setIsDevicePaired(true)

                    body.profile?.let { profDto ->
                        val childProfile = ChildProfile(
                            id = profDto.id,
                            name = profDto.name,
                            avatarIcon = profDto.avatarIcon ?: "bear",
                            ageBracket = profDto.ageBracket ?: "all"
                        )
                        childProfileDao.upsertProfile(ChildProfileEntity.fromDomain(childProfile))
                        settingsDataStore.setCurrentProfile(childProfile.id, childProfile.name, childProfile.avatarIcon)
                    }

                    syncCatalog()
                    "paired"
                } else if (body.status == "expired") {
                    "expired"
                } else {
                    "pending"
                }
            } else if (response.code() == 404) {
                "expired"
            } else {
                "pending"
            }
        } catch (_: Exception) {
            "pending"
        }
    }

    // --- Catalog Sync with Prune Guard ---
    suspend fun syncCatalog(allowMassPrune: Boolean = false): Boolean = withContext(Dispatchers.IO) {
        _isSyncing.value = true
        try {
            val activeProfileId = settingsDataStore.currentProfileId.firstOrNull()
            val response = api.getCatalog(profileId = activeProfileId)

            if (!response.isSuccessful || response.body() == null) {
                _isServerOnline.value = checkHealth()
                _refreshNotice.value = "Couldn't refresh video catalog. Using offline library."
                _isSyncing.value = false
                return@withContext false
            }

            _isServerOnline.value = true
            val catalog = response.body()!!

            // Defensive mapping of categories and videos
            val categoriesToSync = mutableListOf<CategoryItem>()
            val videosToSync = mutableListOf<VideoItem>()
            val seenVideoIds = mutableSetOf<String>()

            // 1. Map sections
            for (section in catalog.sections) {
                section.category?.let { catDto ->
                    categoriesToSync.add(
                        CategoryItem(
                            id = catDto.id,
                            name = catDto.name,
                            icon = catDto.icon ?: "category",
                            displayOrder = catDto.displayOrder ?: 0
                        )
                    )
                }

                for (vDto in section.videos) {
                    if (vDto.id.isNotEmpty() && !seenVideoIds.contains(vDto.id)) {
                        seenVideoIds.add(vDto.id)
                        videosToSync.add(mapVideoDtoToDomain(vDto))
                    }
                }
            }

            // 2. Map all_videos (CRITICAL NON-NEGOTIABLE KEY)
            for (vDto in catalog.allVideos) {
                if (vDto.id.isNotEmpty() && !seenVideoIds.contains(vDto.id)) {
                    seenVideoIds.add(vDto.id)
                    videosToSync.add(mapVideoDtoToDomain(vDto))
                }
            }

            // 3. Fallback to categories list if sections had none
            if (categoriesToSync.isEmpty() && catalog.categories.isNotEmpty()) {
                for (catDto in catalog.categories) {
                    categoriesToSync.add(
                        CategoryItem(
                            id = catDto.id,
                            name = catDto.name,
                            icon = catDto.icon ?: "category",
                            displayOrder = catDto.displayOrder ?: 0
                        )
                    )
                }
            }

            val isExplicitlyCleared = catalog.catalogCleared == true || catalog.allowEmptyCatalog == true

            // PRUNE GUARD LOGIC
            if (videosToSync.isEmpty() && !isExplicitlyCleared) {
                // Ambiguous empty response: keep local library intact
                _refreshNotice.value = "Couldn't refresh video catalog. Using offline library."
                _isSyncing.value = false
                return@withContext false
            }

            if (videosToSync.isEmpty() && isExplicitlyCleared) {
                val localVideos = videoDao.getAllVideos()
                if (localVideos.isNotEmpty() && !allowMassPrune) {
                    _pendingPruneVideoIds.value = localVideos.map { it.id }
                    _refreshNotice.value = "Server signaled cleared catalog. Parent confirmation required in dashboard to delete offline library."
                } else {
                    for (v in localVideos) {
                        downloadManager.deleteDownloaded(v.id, v.localFilePath)
                    }
                    videoDao.deleteAllVideos()
                    _pendingPruneVideoIds.value = emptyList()
                    _refreshNotice.value = null
                }
            } else {
                // Valid non-empty catalog: upsert categories and videos
                if (categoriesToSync.isNotEmpty()) {
                    categoryDao.upsertCategories(categoriesToSync.map { CategoryEntity.fromDomain(it) })
                }

                // Preserve local download status and paths when upserting from server
                val existingLocalVideos = videoDao.getAllVideos().associateBy { it.id }
                val entitiesToUpsert = videosToSync.map { domain ->
                    val existing = existingLocalVideos[domain.id]
                    if (existing != null && existing.isDownloaded) {
                        VideoEntity.fromDomain(
                            domain.copy(
                                isDownloaded = existing.isDownloaded,
                                downloadedAt = existing.downloadedAt,
                                localFilePath = existing.localFilePath,
                                localThumbPath = existing.localThumbPath
                            )
                        )
                    } else {
                        VideoEntity.fromDomain(domain)
                    }
                }
                videoDao.upsertVideos(entitiesToUpsert)

                // Check removals against local DB
                val localVideos = videoDao.getAllVideos()
                val validIds = videosToSync.map { it.id }.toSet()
                val toDelete = localVideos.filter { !validIds.contains(it.id) }

                if (toDelete.isNotEmpty()) {
                    val pruneRatio = toDelete.size.toDouble() / localVideos.size.toDouble()
                    if (!allowMassPrune && localVideos.size > 2 && pruneRatio > 0.50) {
                        // Safety cap: held for parent confirmation
                        _pendingPruneVideoIds.value = toDelete.map { it.id }
                        _refreshNotice.value = "Catalog refreshed, but ${toDelete.size} video removal(s) (${(pruneRatio * 100).toInt()}%) held for parent confirmation."
                    } else {
                        for (v in toDelete) {
                            downloadManager.deleteDownloaded(v.id, v.localFilePath)
                        }
                        videoDao.deleteByIds(toDelete.map { it.id })
                        _pendingPruneVideoIds.value = emptyList()
                        _refreshNotice.value = null
                    }
                } else {
                    _pendingPruneVideoIds.value = emptyList()
                    _refreshNotice.value = null
                }
            }

            // Sync profiles
            if (catalog.profiles.isNotEmpty()) {
                for (pDto in catalog.profiles) {
                    childProfileDao.upsertProfile(
                        ChildProfileEntity(
                            id = pDto.id,
                            name = pDto.name,
                            avatarIcon = pDto.avatarIcon ?: "bear",
                            ageBracket = pDto.ageBracket ?: "all"
                        )
                    )
                }
            }

            _isSyncing.value = false
            true
        } catch (e: Exception) {
            _isServerOnline.value = false
            _refreshNotice.value = "Couldn't refresh video catalog. Using offline library."
            _isSyncing.value = false
            false
        }
    }

    private fun mapVideoDtoToDomain(dto: com.mykidstube.android.data.api.model.VideoDto): VideoItem {
        val id = dto.id
        val ytId = UrlHelpers.getYoutubeId(id, dto.youtubeId)
        val vidFile = dto.videoFile ?: "$id.mp4"
        val thumbFile = dto.thumbnailFile ?: "$id.webp"
        val streamUrl = UrlHelpers.getStreamUrl(dto.streamUrl, vidFile)
        val thumbUrl = UrlHelpers.getThumbnailUrl(dto.thumbnailUrl, thumbFile, id, ytId)

        return VideoItem(
            id = id,
            title = dto.title ?: "Kids Video",
            duration = dto.duration ?: 0,
            durationFormatted = dto.durationFormatted ?: "00:00",
            categoryId = dto.categoryId ?: "cartoons",
            sourceUrl = dto.sourceUrl ?: "https://www.youtube.com/watch?v=$ytId",
            streamUrl = streamUrl,
            thumbnailUrl = thumbUrl,
            channelName = dto.channelName ?: "YouTube Kids",
            channelIconUrl = dto.channelIconUrl ?: dto.channelIcon.orEmpty(),
            fileSizeBytes = dto.fileSizeBytes ?: 0L,
            quality = dto.quality ?: "720p",
            status = dto.status ?: "ready",
            views = dto.views ?: 0L,
            watchSeconds = dto.watchSeconds ?: 0L,
            youtubeId = ytId
        )
    }

    // --- Parent Operations ---
    suspend fun loginParent(pin: String): Boolean = withContext(Dispatchers.IO) {
        try {
            val response = api.loginParent(LoginRequestDto(pin = pin))
            response.isSuccessful
        } catch (_: Exception) {
            false
        }
    }

    suspend fun ingestVideo(
        url: String,
        categoryId: String = "cartoons",
        quality: String = "720p",
        allowedProfileIds: List<String>? = null
    ): Boolean = withContext(Dispatchers.IO) {
        try {
            val response = api.ingestVideo(
                IngestRequestDto(
                    url = url,
                    categoryId = categoryId,
                    quality = quality,
                    allowedProfileIds = allowedProfileIds
                )
            )
            if (response.isSuccessful) {
                // Delayed catalog sync to capture ingested video
                repositoryScope.launch {
                    delay(4000)
                    syncCatalog()
                }
                true
            } else {
                false
            }
        } catch (_: Exception) {
            false
        }
    }

    suspend fun deleteVideos(videoIds: List<String>): Boolean = withContext(Dispatchers.IO) {
        if (videoIds.isEmpty()) return@withContext true
        var remoteSuccess = false
        try {
            val response = api.deleteVideos(videoIds.joinToString(","))
            remoteSuccess = response.isSuccessful
        } catch (_: Exception) {}

        // Always prune locally from Room and disk
        for (id in videoIds) {
            downloadManager.deleteDownloaded(id, null)
        }
        videoDao.deleteByIds(videoIds)
        remoteSuccess
    }

    // --- Analytics & Watch Metrics ---
    suspend fun recordWatchSession(
        videoId: String,
        videoTitle: String?,
        categoryId: String?,
        secondsWatched: Int,
        videoDuration: Int,
        isCompleted: Boolean,
        isSkipped: Boolean
    ) = withContext(Dispatchers.IO) {
        if (secondsWatched <= 0) return@withContext
        val activeProfileId = settingsDataStore.currentProfileId.firstOrNull()
        val activeProfileName = settingsDataStore.currentProfileName.firstOrNull()
        val deviceName = settingsDataStore.deviceName.firstOrNull() ?: "Kids Tablet"

        val completionRate = if (videoDuration > 0) {
            (secondsWatched.toFloat() / videoDuration.toFloat()).coerceIn(0f, 1f)
        } else {
            0f
        }

        val event = WatchEventEntity(
            id = "ev_" + UUID.randomUUID().toString().replace("-", "").take(16),
            videoId = videoId,
            videoTitle = videoTitle,
            categoryId = categoryId,
            deviceId = deviceName,
            profileId = activeProfileId,
            profileName = activeProfileName,
            secondsWatched = secondsWatched,
            videoDuration = videoDuration,
            completionRate = completionRate,
            isCompleted = isCompleted,
            isSkipped = isSkipped,
            watchedAt = System.currentTimeMillis(),
            isSynced = false
        )
        watchEventDao.insertEvent(event)
    }

    suspend fun getWatchAnalytics(profileId: String? = null): Map<String, Any> = withContext(Dispatchers.IO) {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.HOUR_OF_DAY, 0)
            set(Calendar.MINUTE, 0)
            set(Calendar.SECOND, 0)
            set(Calendar.MILLISECOND, 0)
        }
        val startOfDay = calendar.timeInMillis
        val queryProfileId = if (profileId == "all") null else profileId

        val todaySecs = watchEventDao.getTodaySeconds(startOfDay, queryProfileId)
        val totalSecs = watchEventDao.getTotalSeconds(queryProfileId)
        val totalSessions = watchEventDao.getTotalSessions(queryProfileId)
        val completedCount = watchEventDao.getCompletedCount(queryProfileId)
        val skippedCount = watchEventDao.getSkippedCount(queryProfileId)
        val unsyncedCount = watchEventDao.getUnsyncedCount()

        val completionRate = if (totalSessions > 0) ((completedCount.toDouble() / totalSessions.toDouble()) * 100).toInt() else 0
        val skipRate = if (totalSessions > 0) ((skippedCount.toDouble() / totalSessions.toDouble()) * 100).toInt() else 0

        val lovedVideos = watchEventDao.getTopLovedVideos(queryProfileId)
        val skippedVideos = watchEventDao.getTopSkippedVideos(queryProfileId)

        mapOf(
            "today_seconds" to todaySecs,
            "total_seconds" to totalSecs,
            "total_sessions" to totalSessions,
            "completed_count" to completedCount,
            "skipped_count" to skippedCount,
            "completion_rate" to completionRate,
            "skip_rate" to skipRate,
            "unsynced_count" to unsyncedCount,
            "loved_videos" to lovedVideos,
            "skipped_videos" to skippedVideos
        )
    }

    suspend fun syncWatchEventsToServer(): Pair<Boolean, Int> = withContext(Dispatchers.IO) {
        val unsynced = watchEventDao.getUnsyncedEvents()
        if (unsynced.isEmpty()) return@withContext Pair(true, 0)

        try {
            val payloads = unsynced.map {
                WatchEventPayloadDto(
                    id = it.id,
                    videoId = it.videoId,
                    videoTitle = it.videoTitle,
                    categoryId = it.categoryId,
                    deviceId = it.deviceId,
                    profileId = it.profileId,
                    profileName = it.profileName,
                    secondsWatched = it.secondsWatched,
                    videoDuration = it.videoDuration,
                    completionRate = it.completionRate,
                    isCompleted = if (it.isCompleted) 1 else 0,
                    isSkipped = if (it.isSkipped) 1 else 0,
                    watchedAt = Date(it.watchedAt).toString()
                )
            }
            val response = api.syncWatchMetrics(WatchBatchRequestDto(events = payloads))
            if (response.isSuccessful && response.body()?.success == true) {
                val syncedIds = response.body()?.syncedIds ?: unsynced.map { it.id }
                watchEventDao.markEventsSynced(syncedIds)
                Pair(true, syncedIds.size)
            } else {
                Pair(false, 0)
            }
        } catch (_: Exception) {
            Pair(false, 0)
        }
    }

    // --- Profile Operations ---
    suspend fun switchProfile(profile: ChildProfile) = withContext(Dispatchers.IO) {
        settingsDataStore.setCurrentProfile(profile.id, profile.name, profile.avatarIcon)
        syncCatalog()
    }

    suspend fun addProfile(profile: ChildProfile) = withContext(Dispatchers.IO) {
        childProfileDao.upsertProfile(ChildProfileEntity.fromDomain(profile))
    }

    suspend fun deleteProfile(profileId: String) = withContext(Dispatchers.IO) {
        childProfileDao.deleteProfile(profileId)
        val currentProfileId = settingsDataStore.currentProfileId.firstOrNull()
        if (currentProfileId == profileId) {
            val remaining = childProfileDao.getAllProfiles()
            if (remaining.isNotEmpty()) {
                val first = remaining.first()
                settingsDataStore.setCurrentProfile(first.id, first.name, first.avatarIcon)
            }
        }
    }

    // --- Favorites ---
    suspend fun toggleFavorite(videoId: String) = withContext(Dispatchers.IO) {
        if (favoriteDao.isFavorite(videoId)) {
            favoriteDao.removeFavorite(videoId)
        } else {
            favoriteDao.addFavorite(FavoriteEntity(videoId = videoId))
        }
    }

    suspend fun isFavorite(videoId: String): Boolean = withContext(Dispatchers.IO) {
        favoriteDao.isFavorite(videoId)
    }

    // --- Cache Clearing ---
    suspend fun clearCache() = withContext(Dispatchers.IO) {
        downloadManager.clearAllDownloaded()
        videoDao.deleteAllVideos()
        categoryDao.deleteAllCategories()
        syncCatalog()
    }
}
