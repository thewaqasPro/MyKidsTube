package com.mykidstube.android.data.db

import androidx.room.*
import kotlinx.coroutines.flow.Flow

@Dao
interface VideoDao {
    @Query("SELECT * FROM videos ORDER BY id ASC")
    fun getAllVideosFlow(): Flow<List<VideoEntity>>

    @Query("SELECT * FROM videos ORDER BY id ASC")
    suspend fun getAllVideos(): List<VideoEntity>

    @Query("SELECT * FROM videos WHERE id = :id LIMIT 1")
    suspend fun getVideoById(id: String): VideoEntity?

    @Query("SELECT * FROM videos WHERE isDownloaded = 1 ORDER BY downloadedAt DESC")
    fun getDownloadedVideosFlow(): Flow<List<VideoEntity>>

    @Query("SELECT * FROM videos WHERE isDownloaded = 1 ORDER BY downloadedAt DESC")
    suspend fun getDownloadedVideos(): List<VideoEntity>

    @Upsert
    suspend fun upsertVideos(videos: List<VideoEntity>)

    @Query("""
        UPDATE videos 
        SET isDownloaded = :isDownloaded, 
            downloadedAt = :downloadedAt, 
            localFilePath = :localFilePath, 
            localThumbPath = :localThumbPath 
        WHERE id = :videoId
    """)
    suspend fun updateDownloadStatus(
        videoId: String,
        isDownloaded: Boolean,
        downloadedAt: Long?,
        localFilePath: String?,
        localThumbPath: String?
    )

    @Query("""
        UPDATE videos 
        SET isDownloaded = 0, 
            downloadedAt = NULL, 
            localFilePath = NULL, 
            localThumbPath = NULL 
        WHERE id = :videoId
    """)
    suspend fun clearDownloadStatus(videoId: String)

    @Query("DELETE FROM videos WHERE id IN (:ids)")
    suspend fun deleteByIds(ids: List<String>)

    @Query("DELETE FROM videos")
    suspend fun deleteAllVideos()
}

@Dao
interface CategoryDao {
    @Query("SELECT * FROM categories ORDER BY displayOrder ASC")
    fun getAllCategoriesFlow(): Flow<List<CategoryEntity>>

    @Query("SELECT * FROM categories ORDER BY displayOrder ASC")
    suspend fun getAllCategories(): List<CategoryEntity>

    @Upsert
    suspend fun upsertCategories(categories: List<CategoryEntity>)

    @Query("DELETE FROM categories")
    suspend fun deleteAllCategories()
}

@Dao
interface ChildProfileDao {
    @Query("SELECT * FROM local_child_profiles ORDER BY createdAt ASC")
    fun getAllProfilesFlow(): Flow<List<ChildProfileEntity>>

    @Query("SELECT * FROM local_child_profiles ORDER BY createdAt ASC")
    suspend fun getAllProfiles(): List<ChildProfileEntity>

    @Query("SELECT * FROM local_child_profiles WHERE id = :id LIMIT 1")
    suspend fun getProfileById(id: String): ChildProfileEntity?

    @Upsert
    suspend fun upsertProfile(profile: ChildProfileEntity)

    @Query("DELETE FROM local_child_profiles WHERE id = :id")
    suspend fun deleteProfile(id: String)
}

@Dao
interface FavoriteDao {
    @Query("SELECT videoId FROM favorites")
    fun getAllFavoriteIdsFlow(): Flow<List<String>>

    @Query("SELECT videoId FROM favorites")
    suspend fun getAllFavoriteIds(): List<String>

    @Query("SELECT EXISTS(SELECT 1 FROM favorites WHERE videoId = :videoId)")
    suspend fun isFavorite(videoId: String): Boolean

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun addFavorite(favorite: FavoriteEntity)

    @Query("DELETE FROM favorites WHERE videoId = :videoId")
    suspend fun removeFavorite(videoId: String)
}

@Dao
interface WatchEventDao {
    @Insert(onConflict = OnConflictStrategy.IGNORE)
    suspend fun insertEvent(event: WatchEventEntity)

    @Query("SELECT * FROM local_watch_events WHERE isSynced = 0 ORDER BY watchedAt ASC")
    suspend fun getUnsyncedEvents(): List<WatchEventEntity>

    @Query("UPDATE local_watch_events SET isSynced = 1 WHERE id IN (:ids)")
    suspend fun markEventsSynced(ids: List<String>)

    @Query("""
        SELECT COALESCE(SUM(secondsWatched), 0) 
        FROM local_watch_events 
        WHERE watchedAt >= :startOfDayTimestamp
          AND (:profileId IS NULL OR profileId = :profileId)
    """)
    suspend fun getTodaySeconds(startOfDayTimestamp: Long, profileId: String?): Long

    @Query("""
        SELECT COALESCE(SUM(secondsWatched), 0) 
        FROM local_watch_events 
        WHERE (:profileId IS NULL OR profileId = :profileId)
    """)
    suspend fun getTotalSeconds(profileId: String?): Long

    @Query("""
        SELECT COUNT(*) 
        FROM local_watch_events 
        WHERE (:profileId IS NULL OR profileId = :profileId)
    """)
    suspend fun getTotalSessions(profileId: String?): Int

    @Query("""
        SELECT COUNT(*) 
        FROM local_watch_events 
        WHERE isCompleted = 1 
          AND (:profileId IS NULL OR profileId = :profileId)
    """)
    suspend fun getCompletedCount(profileId: String?): Int

    @Query("""
        SELECT COUNT(*) 
        FROM local_watch_events 
        WHERE isSkipped = 1 
          AND (:profileId IS NULL OR profileId = :profileId)
    """)
    suspend fun getSkippedCount(profileId: String?): Int

    @Query("""
        SELECT COUNT(*) 
        FROM local_watch_events 
        WHERE isSynced = 0
    """)
    suspend fun getUnsyncedCount(): Int

    @Query("""
        SELECT videoId, videoTitle, COUNT(*) as playCount, SUM(secondsWatched) as totalSecs
        FROM local_watch_events
        WHERE isCompleted = 1 AND (:profileId IS NULL OR profileId = :profileId)
        GROUP BY videoId
        ORDER BY totalSecs DESC
        LIMIT 5
    """)
    suspend fun getTopLovedVideos(profileId: String?): List<TopVideoRow>

    @Query("""
        SELECT videoId, videoTitle, COUNT(*) as playCount, SUM(secondsWatched) as totalSecs
        FROM local_watch_events
        WHERE isSkipped = 1 AND (:profileId IS NULL OR profileId = :profileId)
        GROUP BY videoId
        ORDER BY playCount DESC
        LIMIT 5
    """)
    suspend fun getTopSkippedVideos(profileId: String?): List<TopVideoRow>
}

data class TopVideoRow(
    val videoId: String,
    val videoTitle: String?,
    val playCount: Int,
    val totalSecs: Long
)

@Dao
interface SettingDao {
    @Query("SELECT value FROM settings WHERE `key` = :key LIMIT 1")
    suspend fun getSetting(key: String): String?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun setSetting(setting: SettingEntity)

    @Query("DELETE FROM settings WHERE `key` = :key")
    suspend fun removeSetting(key: String)
}
