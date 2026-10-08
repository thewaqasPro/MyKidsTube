package com.mykidstube.android

import com.mykidstube.android.data.api.model.CatalogResponseDto
import com.mykidstube.android.domain.model.UrlHelpers
import com.mykidstube.android.domain.model.VideoItem
import kotlinx.serialization.json.Json
import org.junit.Assert.*
import org.junit.Test

class CatalogMappingTest {

    private val json = Json {
        ignoreUnknownKeys = true
        coerceInputValues = true
        isLenient = true
    }

    private val sampleCatalogJson = """
    {
      "sections": [
        {
          "category": {
            "id": "cartoons",
            "name": "Cartoons",
            "icon": "tv",
            "display_order": 0
          },
          "videos": [
            {
              "id": "peppa_pig_01",
              "title": "Peppa Pig Muddy Puddles",
              "duration": 300,
              "duration_formatted": "05:00",
              "category_id": "cartoons",
              "source_url": "https://www.youtube.com/watch?v=peppa_pig_01",
              "stream_url": "https://kidsapi.waqas.pro/media/videos/peppa_pig_01.mp4",
              "thumbnail_url": "https://mykidstube.kidstube.workers.dev/api/assets/thumbs/peppa_pig_01.webp",
              "channel_name": "Peppa Official",
              "file_size_bytes": 10485760,
              "quality": "720p",
              "status": "ready"
            }
          ]
        }
      ],
      "all_videos": [
        {
          "id": "peppa_pig_01",
          "title": "Peppa Pig Muddy Puddles",
          "duration": 300,
          "duration_formatted": "05:00",
          "category_id": "cartoons",
          "source_url": "https://www.youtube.com/watch?v=peppa_pig_01",
          "stream_url": "https://kidsapi.waqas.pro/media/videos/peppa_pig_01.mp4",
          "thumbnail_url": "https://mykidstube.kidstube.workers.dev/api/assets/thumbs/peppa_pig_01.webp",
          "channel_name": "Peppa Official",
          "file_size_bytes": 10485760,
          "quality": "720p",
          "status": "ready"
        },
        {
          "id": "short_baby_shark_dance",
          "title": "Baby Shark Dance Short",
          "duration": 45,
          "duration_formatted": "00:45",
          "category_id": "shorts",
          "source_url": "https://www.youtube.com/shorts/baby_shark_dance",
          "stream_url": "",
          "thumbnail_url": "https://mykidstube.kidstube.workers.dev/api/assets/thumbs/baby_shark_dance.webp",
          "channel_name": "Pinkfong",
          "quality": "720p"
        }
      ],
      "categories": [
        { "id": "cartoons", "name": "Cartoons", "icon": "tv", "display_order": 0 },
        { "id": "shorts", "name": "Shorts", "icon": "flash", "display_order": 1 }
      ],
      "profiles": [
        { "id": "kid_1", "name": "Emma", "avatar_icon": "unicorn", "age_bracket": "4-6" }
      ],
      "source": "d1_database"
    }
    """.trimIndent()

    @Test
    fun testCatalogDeserializationAndAllVideosMapping() {
        val catalog = json.decodeFromString<CatalogResponseDto>(sampleCatalogJson)

        // Non-negotiable: all_videos key is correctly mapped and non-empty
        assertEquals(2, catalog.allVideos.size)
        assertEquals(1, catalog.sections.size)
        assertEquals(2, catalog.categories.size)
        assertEquals(1, catalog.profiles.size)

        val firstDto = catalog.allVideos[0]
        assertEquals("peppa_pig_01", firstDto.id)
        assertEquals("Peppa Pig Muddy Puddles", firstDto.title)
        assertEquals(300, firstDto.duration)

        val secondDto = catalog.allVideos[1]
        assertEquals("short_baby_shark_dance", secondDto.id)
        assertEquals("shorts", secondDto.categoryId)

        // Map to Domain models
        val domainVideos = catalog.allVideos.map { dto ->
            val ytId = UrlHelpers.getYoutubeId(dto.id, dto.youtubeId)
            VideoItem(
                id = dto.id,
                title = dto.title ?: "Kids Video",
                duration = dto.duration ?: 0,
                durationFormatted = dto.durationFormatted ?: "00:00",
                categoryId = dto.categoryId ?: "cartoons",
                sourceUrl = dto.sourceUrl ?: "https://www.youtube.com/watch?v=$ytId",
                streamUrl = dto.streamUrl ?: "",
                thumbnailUrl = dto.thumbnailUrl ?: "",
                channelName = dto.channelName ?: "YouTube Kids",
                fileSizeBytes = dto.fileSizeBytes ?: 0L,
                quality = dto.quality ?: "720p",
                status = dto.status ?: "ready",
                youtubeId = ytId
            )
        }

        assertEquals(2, domainVideos.size)

        val regularVideo = domainVideos[0]
        assertFalse(regularVideo.isShort)
        assertEquals("peppa_pig_01", regularVideo.effectiveYoutubeId)

        val shortVideo = domainVideos[1]
        assertTrue(shortVideo.isShort)
        assertEquals("baby_shark_dance", shortVideo.effectiveYoutubeId)
        assertTrue(shortVideo.needsEmbed)
    }

    @Test
    fun testDefensiveParsingOnMalformedItems() {
        val malformedJson = """
        {
          "all_videos": [
            {
              "id": "corrupt_1"
            },
            {
              "id": "corrupt_2",
              "title": null,
              "duration": null,
              "file_size_bytes": null
            }
          ]
        }
        """.trimIndent()

        val catalog = json.decodeFromString<CatalogResponseDto>(malformedJson)
        assertEquals(2, catalog.allVideos.size)

        val v1 = catalog.allVideos[0]
        assertEquals("corrupt_1", v1.id)
        assertNull(v1.title)

        val domain1 = VideoItem(
            id = v1.id,
            title = v1.title ?: "Untitled",
            duration = v1.duration ?: 0,
            fileSizeBytes = v1.fileSizeBytes ?: 0L
        )
        assertEquals("Untitled", domain1.title)
        assertEquals(0, domain1.duration)
        assertEquals(0L, domain1.fileSizeBytes)
    }
}
