package com.mykidstube.android.data.db

import androidx.room.Entity
import androidx.room.Index
import androidx.room.PrimaryKey
import com.mykidstube.android.domain.model.*

@Entity(
    tableName = "videos",
    indices = [
        Index("categoryId"),
        Index("isDownloaded"),
        Index("youtubeId")
    ]
)
data class VideoEntity(
    @PrimaryKey val id: String,
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
    fun toDomain(): VideoItem = VideoItem(
        id = id,
        title = title,
        duration = duration,
        durationFormatted = durationFormatted,
        categoryId = categoryId,
        sourceUrl = sourceUrl,
        streamUrl = streamUrl,
        thumbnailUrl = thumbnailUrl,
        channelName = channelName,
        channelIconUrl = channelIconUrl,
        localFilePath = localFilePath,
        localThumbPath = localThumbPath,
        fileSizeBytes = fileSizeBytes,
        quality = quality,
        isDownloaded = isDownloaded,
        downloadedAt = downloadedAt,
        status = status,
        views = views,
        watchSeconds = watchSeconds,
        youtubeId = youtubeId
    )

    companion object {
        fun fromDomain(domain: VideoItem): VideoEntity = VideoEntity(
            id = domain.id,
            title = domain.title,
            duration = domain.duration,
            durationFormatted = domain.durationFormatted,
            categoryId = domain.categoryId,
            sourceUrl = domain.sourceUrl,
            streamUrl = domain.streamUrl,
            thumbnailUrl = domain.thumbnailUrl,
            channelName = domain.channelName,
            channelIconUrl = domain.channelIconUrl,
            localFilePath = domain.localFilePath,
            localThumbPath = domain.localThumbPath,
            fileSizeBytes = domain.fileSizeBytes,
            quality = domain.quality,
            isDownloaded = domain.isDownloaded,
            downloadedAt = domain.downloadedAt,
            status = domain.status,
            views = domain.views,
            watchSeconds = domain.watchSeconds,
            youtubeId = domain.youtubeId
        )
    }
}

@Entity(tableName = "categories")
data class CategoryEntity(
    @PrimaryKey val id: String,
    val name: String,
    val icon: String = "category",
    val displayOrder: Int = 0
) {
    fun toDomain(): CategoryItem = CategoryItem(
        id = id,
        name = name,
        icon = icon,
        displayOrder = displayOrder
    )

    companion object {
        fun fromDomain(domain: CategoryItem): CategoryEntity = CategoryEntity(
            id = domain.id,
            name = domain.name,
            icon = domain.icon,
            displayOrder = domain.displayOrder
        )
    }
}

@Entity(tableName = "local_child_profiles")
data class ChildProfileEntity(
    @PrimaryKey val id: String,
    val name: String,
    val avatarIcon: String = "bear",
    val ageBracket: String = "all",
    val createdAt: Long = System.currentTimeMillis()
) {
    fun toDomain(): ChildProfile = ChildProfile(
        id = id,
        name = name,
        avatarIcon = avatarIcon,
        ageBracket = ageBracket,
        createdAt = createdAt
    )

    companion object {
        fun fromDomain(domain: ChildProfile): ChildProfileEntity = ChildProfileEntity(
            id = domain.id,
            name = domain.name,
            avatarIcon = domain.avatarIcon,
            ageBracket = domain.ageBracket,
            createdAt = domain.createdAt
        )
    }
}

@Entity(
    tableName = "local_watch_events",
    indices = [
        Index("watchedAt"),
        Index("isSynced"),
        Index(value = ["profileId", "watchedAt"])
    ]
)
data class WatchEventEntity(
    @PrimaryKey val id: String,
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
) {
    fun toDomain(): WatchEvent = WatchEvent(
        id = id,
        videoId = videoId,
        videoTitle = videoTitle,
        categoryId = categoryId,
        deviceId = deviceId,
        profileId = profileId,
        profileName = profileName,
        secondsWatched = secondsWatched,
        videoDuration = videoDuration,
        completionRate = completionRate,
        isCompleted = isCompleted,
        isSkipped = isSkipped,
        watchedAt = watchedAt,
        isSynced = isSynced
    )

    companion object {
        fun fromDomain(domain: WatchEvent): WatchEventEntity = WatchEventEntity(
            id = domain.id,
            videoId = domain.videoId,
            videoTitle = domain.videoTitle,
            categoryId = domain.categoryId,
            deviceId = domain.deviceId,
            profileId = domain.profileId,
            profileName = domain.profileName,
            secondsWatched = domain.secondsWatched,
            videoDuration = domain.videoDuration,
            completionRate = domain.completionRate,
            isCompleted = domain.isCompleted,
            isSkipped = domain.isSkipped,
            watchedAt = domain.watchedAt,
            isSynced = domain.isSynced
        )
    }
}

@Entity(tableName = "favorites")
data class FavoriteEntity(
    @PrimaryKey val videoId: String,
    val createdAt: Long = System.currentTimeMillis()
)

@Entity(tableName = "settings")
data class SettingEntity(
    @PrimaryKey val key: String,
    val value: String
)
