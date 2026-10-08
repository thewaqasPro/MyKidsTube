package com.mykidstube.android

import com.mykidstube.android.domain.model.UrlHelpers
import org.junit.Assert.*
import org.junit.Test

class UrlHelpersTest {

    @Test
    fun testNormalizeServerUrl() {
        assertEquals("https://mykidstube.kidstube.workers.dev", UrlHelpers.normalizeServerUrl("https://mykidstube.kidstube.workers.dev/"))
        assertEquals("https://kidsapi.waqas.pro", UrlHelpers.normalizeServerUrl("kidsapi.waqas.pro"))
        assertEquals("http://10.0.2.2:4321", UrlHelpers.normalizeServerUrl("http://10.0.2.2:4321/"))
        assertEquals(UrlHelpers.DEFAULT_SERVER_URL, UrlHelpers.normalizeServerUrl("   "))
    }

    @Test
    fun testGetYoutubeId() {
        assertEquals("abc123XYZ", UrlHelpers.getYoutubeId("abc123XYZ"))
        assertEquals("abc123XYZ", UrlHelpers.getYoutubeId("short_abc123XYZ"))
        assertEquals("explicit_yt", UrlHelpers.getYoutubeId("short_abc123XYZ", "explicit_yt"))
    }

    @Test
    fun testIsVideoShort() {
        // Shorts URL
        assertTrue(UrlHelpers.isVideoShort(sourceUrl = "https://www.youtube.com/shorts/abc12345"))
        // ID starting with short_
        assertTrue(UrlHelpers.isVideoShort(id = "short_baby_shark", duration = 40))
        // Category shorts with duration <= 70s
        assertTrue(UrlHelpers.isVideoShort(duration = 55, categoryId = "shorts"))
        // Standard long-form watch URL is NOT short
        assertFalse(UrlHelpers.isVideoShort(sourceUrl = "https://www.youtube.com/watch?v=abc12345", duration = 40))
        // Long duration (> 70s) is NOT short
        assertFalse(UrlHelpers.isVideoShort(duration = 120, categoryId = "shorts"))
    }

    @Test
    fun testGetYoutubeEmbedUrl() {
        val url = UrlHelpers.getYoutubeEmbedUrl("abc123XYZ", autoPlay = true)
        assertTrue(url.contains("youtube-nocookie.com/embed/abc123XYZ"))
        assertTrue(url.contains("autoplay=1"))
        assertTrue(url.contains("modestbranding=1"))
        assertTrue(url.contains("playsinline=1"))
    }

    @Test
    fun testGetThumbnailUrl() {
        // Direct http url
        val direct = "https://example.com/thumb.webp"
        assertEquals(direct, UrlHelpers.getThumbnailUrl(direct, null, "vid1", null))

        // Worker thumbs endpoint
        val built = UrlHelpers.getThumbnailUrl(null, "vid1.webp", "vid1", null)
        assertEquals("https://mykidstube.kidstube.workers.dev/api/assets/thumbs/vid1.webp", built)

        // Fallback to youtube id
        val fromYt = UrlHelpers.getThumbnailUrl(null, null, "vid1", "yt123")
        assertEquals("https://mykidstube.kidstube.workers.dev/api/assets/thumbs/yt123.webp", fromYt)
    }
}
