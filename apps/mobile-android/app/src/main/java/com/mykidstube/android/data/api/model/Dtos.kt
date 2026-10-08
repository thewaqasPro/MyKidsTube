package com.mykidstube.android.data.api.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class HealthResponseDto(
    val status: String = "ok",
    val service: String? = null
)

@Serializable
data class RegisterDeviceRequestDto(
    @SerialName("device_name") val deviceName: String = "Kids Tablet"
)

@Serializable
data class RegisterDeviceResponseDto(
    @SerialName("device_id") val deviceId: String,
    @SerialName("pairing_code") val pairingCode: String,
    @SerialName("device_name") val deviceName: String? = null,
    val status: String? = null,
    @SerialName("expires_in_seconds") val expiresInSeconds: Int? = null
)

@Serializable
data class ProfileDto(
    val id: String,
    val name: String,
    @SerialName("avatar_icon") val avatarIcon: String? = "bear",
    @SerialName("age_bracket") val ageBracket: String? = "all"
)

@Serializable
data class DeviceStatusResponseDto(
    val status: String,
    @SerialName("device_id") val deviceId: String? = null,
    @SerialName("device_name") val deviceName: String? = null,
    @SerialName("auth_token") val authToken: String? = null,
    val profile: ProfileDto? = null,
    val message: String? = null
)

@Serializable
data class CategoryDto(
    val id: String,
    val name: String,
    val icon: String? = "category",
    @SerialName("display_order") val displayOrder: Int? = 0
)

@Serializable
data class VideoDto(
    val id: String,
    val title: String? = null,
    val duration: Int? = 0,
    @SerialName("duration_formatted") val durationFormatted: String? = "00:00",
    @SerialName("category_id") val categoryId: String? = "cartoons",
    @SerialName("source_url") val sourceUrl: String? = null,
    @SerialName("stream_url") val streamUrl: String? = null,
    @SerialName("thumbnail_url") val thumbnailUrl: String? = null,
    @SerialName("thumbnail_file") val thumbnailFile: String? = null,
    @SerialName("video_file") val videoFile: String? = null,
    @SerialName("channel_name") val channelName: String? = "YouTube Kids",
    @SerialName("channel_icon") val channelIcon: String? = null,
    @SerialName("channel_icon_url") val channelIconUrl: String? = null,
    @SerialName("file_size_bytes") val fileSizeBytes: Long? = 0L,
    val quality: String? = "720p",
    val status: String? = "ready",
    val views: Long? = 0L,
    @SerialName("watch_seconds") val watchSeconds: Long? = 0L,
    @SerialName("youtube_id") val youtubeId: String? = null
)

@Serializable
data class SectionDto(
    val category: CategoryDto? = null,
    val videos: List<VideoDto> = emptyList()
)

@Serializable
data class CatalogResponseDto(
    val sections: List<SectionDto> = emptyList(),
    @SerialName("all_videos") val allVideos: List<VideoDto> = emptyList(),
    val categories: List<CategoryDto> = emptyList(),
    val profiles: List<ProfileDto> = emptyList(),
    val source: String? = null,
    @SerialName("catalog_cleared") val catalogCleared: Boolean? = null,
    @SerialName("allow_empty_catalog") val allowEmptyCatalog: Boolean? = null
)

@Serializable
data class LoginRequestDto(
    val pin: String
)

@Serializable
data class LoginResponseDto(
    val success: Boolean = false,
    val message: String? = null
)

@Serializable
data class IngestRequestDto(
    val url: String,
    @SerialName("category_id") val categoryId: String = "cartoons",
    val quality: String = "720p",
    @SerialName("allowed_profile_ids") val allowedProfileIds: List<String>? = null
)

@Serializable
data class IngestResponseDto(
    val success: Boolean = false,
    @SerialName("video_id") val videoId: String? = null,
    val title: String? = null,
    val message: String? = null
)

@Serializable
data class WatchEventPayloadDto(
    val id: String? = null,
    @SerialName("video_id") val videoId: String,
    @SerialName("video_title") val videoTitle: String? = null,
    @SerialName("category_id") val categoryId: String? = null,
    @SerialName("device_id") val deviceId: String? = null,
    @SerialName("profile_id") val profileId: String? = null,
    @SerialName("profile_name") val profileName: String? = null,
    @SerialName("seconds_watched") val secondsWatched: Int,
    @SerialName("video_duration") val videoDuration: Int = 0,
    @SerialName("completion_rate") val completionRate: Float = 0f,
    @SerialName("is_completed") val isCompleted: Int = 0,
    @SerialName("is_skipped") val isSkipped: Int = 0,
    @SerialName("watched_at") val watchedAt: String? = null
)

@Serializable
data class WatchBatchRequestDto(
    val events: List<WatchEventPayloadDto>
)

@Serializable
data class WatchSyncResponseDto(
    val success: Boolean = false,
    @SerialName("synced_count") val syncedCount: Int = 0,
    @SerialName("synced_ids") val syncedIds: List<String> = emptyList()
)
