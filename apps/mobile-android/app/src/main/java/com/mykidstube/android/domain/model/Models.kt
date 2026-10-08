package com.mykidstube.android.domain.model

data class CategoryItem(
    val id: String,
    val name: String,
    val icon: String = "category",
    val displayOrder: Int = 0
)

data class ChildProfile(
    val id: String,
    val name: String,
    val avatarIcon: String = "bear",
    val ageBracket: String = "all",
    val createdAt: Long = System.currentTimeMillis()
)

data class WatchEvent(
    val id: String,
    val videoId: String,
    val videoTitle: String? = null,
    val categoryId: String? = null,
    val deviceId: String = "kids_tablet",
    val profileId: String? = null,
    val profileName: String? = null,
    val secondsWatched: Int,
    val videoDuration: Int = 0,
    val completionRate: Float = 0.0f,
    val isCompleted: Boolean = false,
    val isSkipped: Boolean = false,
    val watchedAt: Long = System.currentTimeMillis(),
    val isSynced: Boolean = false
)

enum class DownloadStatus {
    IDLE,
    QUEUED,
    DOWNLOADING,
    COMPLETED,
    FAILED,
    CANCELLED
}

data class DownloadProgress(
    val videoId: String,
    val status: DownloadStatus = DownloadStatus.IDLE,
    val progress: Float = 0f,
    val bytesDownloaded: Long = 0L,
    val totalBytes: Long = 0L,
    val errorMessage: String? = null
)

enum class AppOrientationMode {
    AUTO,
    PORTRAIT,
    LANDSCAPE
}
