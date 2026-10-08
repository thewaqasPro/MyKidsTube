package com.mykidstube.android.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.mykidstube.android.data.repository.KidsTubeRepository
import com.mykidstube.android.data.store.SettingsDataStore
import com.mykidstube.android.domain.model.*
import com.mykidstube.android.worker.DownloadManager
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch
import javax.inject.Inject

data class HomeUiState(
    val categories: List<CategoryItem> = emptyList(),
    val allVideos: List<VideoItem> = emptyList(),
    val downloadedVideos: List<VideoItem> = emptyList(),
    val favoriteIds: Set<String> = emptySet(),
    val activeProfile: ChildProfile? = null,
    val profiles: List<ChildProfile> = emptyList(),
    val selectedCategoryId: String = "all",
    val searchQuery: String = "",
    val isSearchOpen: Boolean = false,
    val isOfflineOnly: Boolean = false,
    val orientationMode: AppOrientationMode = AppOrientationMode.AUTO,
    val refreshNotice: String? = null,
    val pendingPruneCount: Int = 0,
    val isSyncing: Boolean = false,
    val downloadProgressMap: Map<String, DownloadProgress> = emptyMap()
)

@HiltViewModel
class HomeViewModel @Inject constructor(
    private val repository: KidsTubeRepository,
    private val settingsDataStore: SettingsDataStore,
    private val downloadManager: DownloadManager
) : ViewModel() {

    private val _selectedCategoryId = MutableStateFlow("all")
    private val _searchQuery = MutableStateFlow("")
    private val _isSearchOpen = MutableStateFlow(false)

    val uiState: StateFlow<HomeUiState> = combine(
        repository.categories,
        repository.allVideos,
        repository.downloadedVideos,
        repository.favoriteIds,
        repository.profiles,
        settingsDataStore.currentProfileId,
        settingsDataStore.isOfflineOnly,
        settingsDataStore.orientationMode,
        repository.isSyncing,
        downloadManager.downloadProgressMap
    ) { args ->
        val categories = args[0] as List<CategoryItem>
        val allVideos = args[1] as List<VideoItem>
        val downloadedVideos = args[2] as List<VideoItem>
        val favoriteIds = args[3] as Set<String>
        val profiles = args[4] as List<ChildProfile>
        val profileId = args[5] as String?
        val isOfflineOnly = args[6] as Boolean
        val orientation = args[7] as AppOrientationMode
        val isSyncing = args[8] as Boolean
        val progressMap = args[9] as Map<String, DownloadProgress>

        val activeProfile = profiles.firstOrNull { it.id == profileId }
            ?: profiles.firstOrNull()

        HomeUiState(
            categories = categories,
            allVideos = allVideos,
            downloadedVideos = downloadedVideos,
            favoriteIds = favoriteIds,
            activeProfile = activeProfile,
            profiles = profiles,
            selectedCategoryId = _selectedCategoryId.value,
            searchQuery = _searchQuery.value,
            isSearchOpen = _isSearchOpen.value,
            isOfflineOnly = isOfflineOnly,
            orientationMode = orientation,
            refreshNotice = repository.refreshNotice.value,
            pendingPruneCount = repository.pendingPruneCount.value,
            isSyncing = isSyncing,
            downloadProgressMap = progressMap
        )
    }.stateIn(viewModelScope, SharingStarted.Eagerly, HomeUiState())

    init {
        viewModelScope.launch {
            repository.syncCatalog()
        }
    }

    fun selectCategory(categoryId: String) {
        _selectedCategoryId.value = categoryId
    }

    fun setSearchQuery(query: String) {
        _searchQuery.value = query
    }

    fun toggleSearch(isOpen: Boolean) {
        _isSearchOpen.value = isOpen
        if (!isOpen) _searchQuery.value = ""
    }

    fun toggleOfflineOnly() {
        viewModelScope.launch {
            val current = uiState.value.isOfflineOnly
            settingsDataStore.setOfflineOnly(!current)
        }
    }

    fun toggleFavorite(videoId: String) {
        viewModelScope.launch {
            repository.toggleFavorite(videoId)
        }
    }

    fun setOrientationMode(mode: AppOrientationMode) {
        viewModelScope.launch {
            settingsDataStore.setOrientationMode(mode)
        }
    }

    fun switchProfile(profile: ChildProfile) {
        viewModelScope.launch {
            repository.switchProfile(profile)
        }
    }

    fun addProfile(name: String, avatar: String) {
        viewModelScope.launch {
            val newProfile = ChildProfile(
                id = "prof_" + System.currentTimeMillis(),
                name = name,
                avatarIcon = avatar
            )
            repository.addProfile(newProfile)
            repository.switchProfile(newProfile)
        }
    }

    fun syncCatalog() {
        viewModelScope.launch {
            repository.syncCatalog()
        }
    }

    fun dismissNotice() {
        repository.dismissRefreshNotice()
    }

    fun confirmPrune() {
        viewModelScope.launch {
            repository.confirmPendingPrune()
        }
    }
}
