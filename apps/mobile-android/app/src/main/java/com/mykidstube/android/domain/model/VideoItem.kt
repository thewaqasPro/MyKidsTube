package com.mykidstube.android.domain.model

import java.io.File

data class VideoItem(
    val id: String,
    val title: String,
    val duration: Int = 0,
    val durationFormatted: String = "00:00",
    val categoryId: String = "cartoons",
    val sourceUrl: String = "",
    val streamUrl: String = "",
    val thumbnailUrl: String = "",
    val channelName: String = "YouTube Kids",
    val channelIconUrl: String = "",
    val localFilePath: String? = null,
    val localThumbPath: String? = null,
    val fileSizeBytes: Long = 0L,
    val quality: String = "720p",
    val isDownloaded: Boolean = false,
    val downloadedAt: Long? = null,
    val status: String = "ready",
    val views: Long = 0L,
    val watchSeconds: Long = 0L,
    val youtubeId: String = ""
) {
    val effectiveYoutubeId: String
        get() = UrlHelpers.getYoutubeId(id, youtubeId)

    val isShort: Boolean
        get() = UrlHelpers.isVideoShort(id, duration, categoryId, sourceUrl)

    val isOfflineReady: Boolean
        get() = isDownloaded && !localFilePath.isNullOrEmpty() && File(localFilePath).exists()

    val needsEmbed: Boolean
        get() = !isOfflineReady && (streamUrl.isEmpty() || streamUrl.contains("youtube.com") || streamUrl.contains("youtu.be"))
}
