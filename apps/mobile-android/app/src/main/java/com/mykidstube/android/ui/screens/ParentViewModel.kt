package com.mykidstube.android.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.mykidstube.android.data.repository.KidsTubeRepository
import com.mykidstube.android.data.store.SecurityService
import com.mykidstube.android.data.store.SettingsDataStore
import com.mykidstube.android.domain.model.ChildProfile
import com.mykidstube.android.domain.model.VideoItem
import com.mykidstube.android.worker.DownloadManager
import com.mykidstube.android.worker.DownloadWorker
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ParentDashboardState(
    val totalVideos: Int = 0,
    val downloadedCount: Int = 0,
    val cachedBytes: Long = 0L,
    val freeBytes: Long = 0L,
    val isServerOnline: Boolean = false,
    val todayWatchSeconds: Long = 0L,
    val isUsingDefaultPin: Boolean = false,
    val hasPendingMassPrune: Boolean = false,
    val pendingPruneCount: Int = 0,
    val refreshNotice: String? = null,
    val activeProfile: ChildProfile? = null
)

@HiltViewModel
class ParentViewModel @Inject constructor(
    private val repository: KidsTubeRepository,
    private val securityService: SecurityService,
    private val settingsDataStore: SettingsDataStore,
    private val downloadManager: DownloadManager
) : ViewModel() {

    val allVideos = repository.allVideos.stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())
    val downloadedVideos = repository.downloadedVideos.stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())
    val categories = repository.categories.stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())
    val profiles = repository.profiles.stateIn(viewModelScope, SharingStarted.Eagerly, emptyList())
    val isServerOnline = repository.isServerOnline
    val isSyncing = repository.isSyncing
    val refreshNotice = repository.refreshNotice
    val pendingPruneVideoIds = repository.pendingPruneVideoIds
    val pendingPruneCount = repository.pendingPruneCount

    private val _vpsUrl = MutableStateFlow("")
    val vpsUrl: StateFlow<String> = _vpsUrl.asStateFlow()

    private val _deviceName = MutableStateFlow("")
    val deviceName: StateFlow<String> = _deviceName.asStateFlow()

    private val _cachedBytes = MutableStateFlow(0L)
    val cachedBytes: StateFlow<Long> = _cachedBytes.asStateFlow()

    private val _freeBytes = MutableStateFlow(0L)
    val freeBytes: StateFlow<Long> = _freeBytes.asStateFlow()

    private val _pingLatencyMs = MutableStateFlow<Int?>(null)
    val pingLatencyMs: StateFlow<Int?> = _pingLatencyMs.asStateFlow()

    private val _isTestingPing = MutableStateFlow(false)
    val isTestingPing: StateFlow<Boolean> = _isTestingPing.asStateFlow()

    private val _analyticsData = MutableStateFlow<Map<String, Any>>(emptyMap())
    val analyticsData: StateFlow<Map<String, Any>> = _analyticsData.asStateFlow()

    private val _isSyncingCloud = MutableStateFlow(false)
    val isSyncingCloud: StateFlow<Boolean> = _isSyncingCloud.asStateFlow()

    private val _isUsingDefaultPin = MutableStateFlow(false)
    val isUsingDefaultPin: StateFlow<Boolean> = _isUsingDefaultPin.asStateFlow()

    init {
        viewModelScope.launch {
            _vpsUrl.value = settingsDataStore.vpsUrl.first()
            _deviceName.value = settingsDataStore.deviceName.first()
            refreshStorageMetrics()
            checkDefaultPin()
            loadAnalytics()
            testPing()
        }
    }

    fun checkDefaultPin() {
        _isUsingDefaultPin.value = securityService.isUsingDefaultPin()
    }

    fun refreshStorageMetrics() {
        viewModelScope.launch {
            _cachedBytes.value = downloadManager.getTotalCachedBytes()
            _freeBytes.value = downloadManager.getFreeDiskSpace()
        }
    }

    fun syncCatalog() {
        viewModelScope.launch {
            repository.syncCatalog()
            refreshStorageMetrics()
        }
    }

    fun confirmPendingPrune() {
        viewModelScope.launch {
            repository.confirmPendingPrune()
            refreshStorageMetrics()
        }
    }

    fun dismissPendingPrune() {
        repository.dismissPendingPrune()
    }

    fun dismissRefreshNotice() {
        repository.dismissRefreshNotice()
    }

    // --- Security PIN Change ---
    suspend fun changePin(currentPin: String, newPin: String): Boolean {
        val success = securityService.changeParentPin(currentPin, newPin)
        if (success) {
            checkDefaultPin()
        }
        return success
    }

    // --- Media Ingest & Delete ---
    suspend fun submitIngestUrl(
        url: String,
        categoryId: String = "cartoons",
        quality: String = "720p"
    ): Boolean {
        return repository.ingestVideo(url, categoryId, quality)
    }

    suspend fun deleteVideos(videoIds: List<String>): Boolean {
        val success = repository.deleteVideos(videoIds)
        refreshStorageMetrics()
        return success
    }

    // --- Storage Actions ---
    suspend fun downloadAllVideos(onProgress: (done: Int, total: Int) -> Unit): String? {
        val undownloaded = allVideos.value.filter { !it.isOfflineReady }
        if (undownloaded.isEmpty()) return null

        val totalNeeded = undownloaded.sumOf { if (it.fileSizeBytes > 0) it.fileSizeBytes else 25L * 1024L * 1024L }
        val free = downloadManager.getFreeDiskSpace()
        if (free < totalNeeded) {
            val shortfall = totalNeeded - free
            return "Not enough storage space to download all (${undownloaded.size}) videos. Short by ${DownloadWorker.formatBytes(shortfall)}."
        }

        var count = 0
        for (v in undownloaded) {
            val err = downloadManager.enqueueDownload(v)
            if (err != null) return err
            count++
            onProgress(count, undownloaded.size)
        }
        refreshStorageMetrics()
        return null
    }

    suspend fun deleteDownloadedVideo(video: VideoItem) {
        downloadManager.deleteDownloaded(video.id, video.localFilePath)
        refreshStorageMetrics()
    }

    suspend fun clearAllStorage() {
        downloadManager.clearAllDownloaded()
        refreshStorageMetrics()
    }

    suspend fun resetCache() {
        repository.clearCache()
        refreshStorageMetrics()
    }

    // --- Server & VPS Config ---
    fun updateVpsUrl(url: String) {
        viewModelScope.launch {
            settingsDataStore.setVpsUrl(url)
            _vpsUrl.value = url
            testPing()
            repository.syncCatalog()
        }
    }

    fun updateDeviceName(name: String) {
        viewModelScope.launch {
            settingsDataStore.setDeviceName(name)
            _deviceName.value = name
        }
    }

    fun testPing() {
        viewModelScope.launch {
            _isTestingPing.value = true
            _pingLatencyMs.value = repository.pingHealth()
            _isTestingPing.value = false
        }
    }

    // --- Analytics ---
    fun loadAnalytics(profileId: String? = null) {
        viewModelScope.launch {
            _analyticsData.value = repository.getWatchAnalytics(profileId)
        }
    }

    suspend fun syncAnalyticsToCloud(): Pair<Boolean, Int> {
        _isSyncingCloud.value = true
        val result = repository.syncWatchEventsToServer()
        loadAnalytics()
        _isSyncingCloud.value = false
        return result
    }
}
