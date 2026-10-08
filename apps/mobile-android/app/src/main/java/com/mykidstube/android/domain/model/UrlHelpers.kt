package com.mykidstube.android.domain.model

object UrlHelpers {
    const val DEFAULT_SERVER_URL = "https://mykidstube.kidstube.workers.dev"
    const val API_BASE = "https://kidsapi.waqas.pro"
    const val MEDIA_BASE = "https://kidsapi.waqas.pro/media"

    fun normalizeServerUrl(rawUrl: String): String {
        var trimmed = rawUrl.trim()
        if (trimmed.isEmpty()) return DEFAULT_SERVER_URL
        if (!trimmed.startsWith("http://") && !trimmed.startsWith("https://")) {
            trimmed = "https://$trimmed"
        }
        return trimmed.removeSuffix("/")
    }

    fun getYoutubeId(id: String, youtubeId: String? = null): String {
        val raw = if (!youtubeId.isNullOrEmpty()) youtubeId else id
        return if (raw.startsWith("short_")) raw.removePrefix("short_") else raw
    }

    fun isVideoShort(
        id: String? = null,
        duration: Int = 0,
        categoryId: String? = null,
        sourceUrl: String? = null
    ): Boolean {
        if (sourceUrl != null && sourceUrl.contains("watch?v=")) return false
        if (duration > 70) return false
        if (sourceUrl != null && sourceUrl.contains("/shorts/")) return true
        if (id != null && id.startsWith("short_")) return true
        if (categoryId == "shorts") {
            return duration in 1..70
        }
        return false
    }

    fun getYoutubeEmbedUrl(youtubeId: String, autoPlay: Boolean = true): String {
        val autoPlayParam = if (autoPlay) 1 else 0
        return "https://www.youtube-nocookie.com/embed/$youtubeId?autoplay=$autoPlayParam&modestbranding=1&rel=0&iv_load_policy=3&playsinline=1&disablekb=1"
    }

    fun getStreamUrl(streamUrl: String?, videoFile: String?): String {
        if (!streamUrl.isNullOrEmpty()) return streamUrl
        if (videoFile.isNullOrEmpty()) return ""
        if (videoFile.startsWith("http://") || videoFile.startsWith("https://")) return videoFile
        return "$MEDIA_BASE/videos/$videoFile"
    }

    fun getThumbnailUrl(
        thumbnailUrl: String?,
        thumbnailFile: String?,
        id: String?,
        youtubeId: String?
    ): String {
        if (!thumbnailUrl.isNullOrEmpty() &&
            !thumbnailUrl.contains("placeholder") &&
            (thumbnailUrl.startsWith("http://") || thumbnailUrl.startsWith("https://"))
        ) {
            return thumbnailUrl
        }
        val file = when {
            !thumbnailFile.isNullOrEmpty() -> thumbnailFile
            !youtubeId.isNullOrEmpty() -> "$youtubeId.webp"
            !id.isNullOrEmpty() -> "$id.webp"
            else -> ""
        }
        if (file.isEmpty()) return "/placeholder-thumb.webp"
        if (file.startsWith("http://") || file.startsWith("https://")) return file
        return "https://mykidstube.kidstube.workers.dev/api/assets/thumbs/$file"
    }
}
