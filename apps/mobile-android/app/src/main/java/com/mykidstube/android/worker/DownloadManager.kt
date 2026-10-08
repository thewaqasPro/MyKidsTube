package com.mykidstube.android.worker

import android.content.Context
import androidx.lifecycle.asFlow
import androidx.work.*
import com.mykidstube.android.data.db.VideoDao
import com.mykidstube.android.domain.model.DownloadProgress
import com.mykidstube.android.domain.model.DownloadStatus
import com.mykidstube.android.domain.model.VideoItem
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class DownloadManager @Inject constructor(
    @ApplicationContext private val context: Context,
    private val videoDao: VideoDao
) {
    private val workManager = WorkManager.getInstance(context)
    private val scope = CoroutineScope(Dispatchers.Default)

    private val _downloadProgressMap = MutableStateFlow<Map<String, DownloadProgress>>(emptyMap())
    val downloadProgressMap: StateFlow<Map<String, DownloadProgress>> = _downloadProgressMap.asStateFlow()

    private val _lastStorageError = MutableStateFlow<String?>(null)
    val lastStorageError: StateFlow<String?> = _lastStorageError.asStateFlow()

    init {
        observeWorkManager()
    }

    private fun observeWorkManager() {
        scope.launch {
            workManager.getWorkInfosByTagLiveData("kidstube_download").asFlow().collect { workInfos ->
                val currentMap = _downloadProgressMap.value.toMutableMap()
                for (workInfo in workInfos) {
                    val videoId = workInfo.progress.getString(DownloadWorker.KEY_VIDEO_ID)
                        ?: workInfo.outputData.getString(DownloadWorker.KEY_VIDEO_ID)
                        ?: workInfo.tags.firstOrNull { it.startsWith("video_") }?.removePrefix("video_")
                        ?: continue

                    when (workInfo.state) {
                        WorkInfo.State.ENQUEUED -> {
                            currentMap[videoId] = DownloadProgress(
                                videoId = videoId,
                                status = DownloadStatus.QUEUED,
                                progress = 0.01f
                            )
                        }
                        WorkInfo.State.RUNNING -> {
                            val progress = workInfo.progress.getFloat(DownloadWorker.KEY_PROGRESS, 0f)
                            val bytesDownloaded = workInfo.progress.getLong(DownloadWorker.KEY_BYTES_DOWNLOADED, 0L)
                            val totalBytes = workInfo.progress.getLong(DownloadWorker.KEY_TOTAL_BYTES, 0L)
                            currentMap[videoId] = DownloadProgress(
                                videoId = videoId,
                                status = DownloadStatus.DOWNLOADING,
                                progress = progress.coerceAtLeast(0.01f),
                                bytesDownloaded = bytesDownloaded,
                                totalBytes = totalBytes
                            )
                        }
                        WorkInfo.State.SUCCEEDED -> {
                            currentMap.remove(videoId)
                        }
                        WorkInfo.State.FAILED -> {
                            val error = workInfo.outputData.getString(DownloadWorker.KEY_ERROR_MESSAGE)
                            if (error != null) {
                                _lastStorageError.value = error
                            }
                            currentMap.remove(videoId)
                        }
                        WorkInfo.State.CANCELLED -> {
                            currentMap.remove(videoId)
                        }
                        else -> {}
                    }
                }
                _downloadProgressMap.value = currentMap
            }
        }
    }

    suspend fun enqueueDownload(video: VideoItem): String? = withContext(Dispatchers.IO) {
        val mediaDir = DownloadWorker.getMediaDirectory(context)
        val requiredBytes = if (video.fileSizeBytes > 0) video.fileSizeBytes else 25L * 1024L * 1024L
        val usableBytes = mediaDir.usableSpace

        if (usableBytes < requiredBytes) {
            val shortfall = requiredBytes - usableBytes
            val msg = "Not enough storage space for '${video.title}'. Short by ${DownloadWorker.formatBytes(shortfall)}."
            _lastStorageError.value = msg
            return@withContext msg
        }

        val inputData = workDataOf(
            DownloadWorker.KEY_VIDEO_ID to video.id,
            DownloadWorker.KEY_STREAM_URL to video.streamUrl,
            DownloadWorker.KEY_THUMB_URL to video.thumbnailUrl,
            DownloadWorker.KEY_TITLE to video.title,
            DownloadWorker.KEY_EXPECTED_SIZE to video.fileSizeBytes
        )

        val constraints = Constraints.Builder()
            .setRequiredNetworkType(NetworkType.CONNECTED)
            .build()

        val downloadWork = OneTimeWorkRequestBuilder<DownloadWorker>()
            .setInputData(inputData)
            .setConstraints(constraints)
            .addTag("kidstube_download")
            .addTag("video_${video.id}")
            .build()

        // Max 2 concurrent downloads is naturally coordinated by WorkManager worker pool
        workManager.enqueueUniqueWork(
            "download_${video.id}",
            ExistingWorkPolicy.KEEP,
            downloadWork
        )

        _downloadProgressMap.value = _downloadProgressMap.value + (video.id to DownloadProgress(
            videoId = video.id,
            status = DownloadStatus.QUEUED,
            progress = 0.01f
        ))

        null
    }

    fun cancelDownload(videoId: String) {
        workManager.cancelUniqueWork("download_$videoId")
        val current = _downloadProgressMap.value.toMutableMap()
        current.remove(videoId)
        _downloadProgressMap.value = current

        scope.launch(Dispatchers.IO) {
            val mediaDir = DownloadWorker.getMediaDirectory(context)
            val part = File(mediaDir, "$videoId.mp4.part")
            if (part.exists()) part.delete()
            videoDao.clearDownloadStatus(videoId)
        }
    }

    suspend fun deleteDownloaded(videoId: String, localFilePath: String?) = withContext(Dispatchers.IO) {
        cancelDownload(videoId)
        val mediaDir = DownloadWorker.getMediaDirectory(context)
        val videoFile = if (!localFilePath.isNullOrEmpty()) File(localFilePath) else File(mediaDir, "$videoId.mp4")
        if (videoFile.exists()) videoFile.delete()

        val partFile = File(mediaDir, "$videoId.mp4.part")
        if (partFile.exists()) partFile.delete()

        val thumbFile = File(mediaDir, "$videoId.webp")
        if (thumbFile.exists()) thumbFile.delete()

        videoDao.clearDownloadStatus(videoId)
    }

    suspend fun clearAllDownloaded() = withContext(Dispatchers.IO) {
        workManager.cancelAllWorkByTag("kidstube_download")
        _downloadProgressMap.value = emptyMap()

        val mediaDir = DownloadWorker.getMediaDirectory(context)
        mediaDir.listFiles()?.forEach { file ->
            try { file.delete() } catch (_: Exception) {}
        }

        val downloadedVideos = videoDao.getDownloadedVideos()
        for (v in downloadedVideos) {
            videoDao.clearDownloadStatus(v.id)
        }
    }

    suspend fun getTotalCachedBytes(): Long = withContext(Dispatchers.IO) {
        val mediaDir = DownloadWorker.getMediaDirectory(context)
        mediaDir.listFiles()?.sumOf { it.length() } ?: 0L
    }

    suspend fun getFreeDiskSpace(): Long = withContext(Dispatchers.IO) {
        val mediaDir = DownloadWorker.getMediaDirectory(context)
        mediaDir.usableSpace
    }

    suspend fun cleanupOrphanFiles() = withContext(Dispatchers.IO) {
        val mediaDir = DownloadWorker.getMediaDirectory(context)
        val validVideos = videoDao.getAllVideos().associateBy { it.id }

        mediaDir.listFiles()?.forEach { file ->
            val name = file.name
            when {
                name.endsWith(".mp4") -> {
                    val id = name.removeSuffix(".mp4")
                    val record = validVideos[id]
                    if (record == null || !record.isDownloaded) {
                        file.delete()
                    }
                }
                name.endsWith(".mp4.part") -> {
                    // Clean partials older than 24 hours
                    val age = System.currentTimeMillis() - file.lastModified()
                    if (age > 24 * 60 * 60 * 1000) {
                        file.delete()
                    }
                }
                name.endsWith(".webp") -> {
                    val id = name.removeSuffix(".webp")
                    if (!validVideos.containsKey(id)) {
                        file.delete()
                    }
                }
            }
        }
    }
}
