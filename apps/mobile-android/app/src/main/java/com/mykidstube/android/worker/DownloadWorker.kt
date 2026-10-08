package com.mykidstube.android.worker

import android.content.Context
import androidx.hilt.work.HiltWorker
import androidx.work.CoroutineWorker
import androidx.work.WorkerParameters
import androidx.work.workDataOf
import com.mykidstube.android.data.db.VideoDao
import dagger.assisted.Assisted
import dagger.assisted.AssistedInject
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import okhttp3.OkHttpClient
import okhttp3.Request
import java.io.File
import java.io.FileOutputStream
import java.io.IOException

@HiltWorker
class DownloadWorker @AssistedInject constructor(
    @Assisted private val context: Context,
    @Assisted workerParams: WorkerParameters,
    private val videoDao: VideoDao,
    private val okHttpClient: OkHttpClient
) : CoroutineWorker(context, workerParams) {

    override suspend fun doWork(): Result = withContext(Dispatchers.IO) {
        val videoId = inputData.getString(KEY_VIDEO_ID) ?: return@withContext Result.failure()
        val streamUrl = inputData.getString(KEY_STREAM_URL) ?: return@withContext Result.failure()
        val thumbUrl = inputData.getString(KEY_THUMB_URL).orEmpty()
        val title = inputData.getString(KEY_TITLE) ?: "Video"
        val expectedSize = inputData.getLong(KEY_EXPECTED_SIZE, 0L)

        val mediaDir = getMediaDirectory(context)
        val finalVideoFile = File(mediaDir, "$videoId.mp4")
        val partFile = File(mediaDir, "$videoId.mp4.part")
        val thumbFile = File(mediaDir, "$videoId.webp")

        // 1. Pre-flight storage check
        val requiredBytes = if (expectedSize > 0) expectedSize else 25L * 1024L * 1024L
        val usableBytes = mediaDir.usableSpace
        if (usableBytes < requiredBytes) {
            val shortfall = requiredBytes - usableBytes
            val shortfallStr = formatBytes(shortfall)
            val errorMsg = "Not enough storage space for '$title'. Short by $shortfallStr."
            return@withContext Result.failure(
                workDataOf(
                    KEY_ERROR_MESSAGE to errorMsg,
                    KEY_VIDEO_ID to videoId
                )
            )
        }

        var outputStream: FileOutputStream? = null
        try {
            // 2. HTTP Range resume detection
            var existingBytes = 0L
            if (partFile.exists()) {
                existingBytes = partFile.length()
            }

            val requestBuilder = Request.Builder().url(streamUrl)
            if (existingBytes > 0L) {
                requestBuilder.header("Range", "bytes=$existingBytes-")
            }

            val request = requestBuilder.build()
            val response = okHttpClient.newCall(request).execute()

            if (!response.isSuccessful && response.code != 206) {
                if (response.code == 416) {
                    // Range not satisfiable: partial file may be corrupt or fully downloaded
                    partFile.delete()
                    throw IOException("HTTP 416: Invalid range, retrying cleanly")
                }
                throw IOException("Server responded with HTTP ${response.code} ${response.message}")
            }

            val responseBody = response.body ?: throw IOException("Empty response body from media server")
            val isResume = response.code == 206 && existingBytes > 0L
            val appendMode = isResume

            val fos = FileOutputStream(partFile, appendMode)
            outputStream = fos

            val contentLength = responseBody.contentLength()
            val totalBytes = if (contentLength > 0) {
                if (isResume) existingBytes + contentLength else contentLength
            } else if (expectedSize > 0) {
                expectedSize
            } else {
                -1L
            }

            var receivedBytes = if (isResume) existingBytes else 0L
            val buffer = ByteArray(32 * 1024)
            val inputStream = responseBody.byteStream()
            var lastProgressReportTime = 0L

            while (true) {
                if (isStopped) {
                    fos.flush()
                    fos.close()
                    outputStream = null
                    // Rule: delete partials on failure/cancel
                    if (partFile.exists()) partFile.delete()
                    videoDao.clearDownloadStatus(videoId)
                    return@withContext Result.failure(
                        workDataOf(
                            KEY_ERROR_MESSAGE to "Download cancelled",
                            KEY_VIDEO_ID to videoId,
                            KEY_IS_CANCELLED to true
                        )
                    )
                }

                val bytesRead = inputStream.read(buffer)
                if (bytesRead == -1) break

                fos.write(buffer, 0, bytesRead)
                receivedBytes += bytesRead

                // Throttled progress update (<= 4 updates/sec, 250ms)
                val currentTime = System.currentTimeMillis()
                if (currentTime - lastProgressReportTime >= 250L || receivedBytes == totalBytes) {
                    lastProgressReportTime = currentTime
                    val progressRatio = if (totalBytes > 0) {
                        (receivedBytes.toFloat() / totalBytes.toFloat()).coerceIn(0f, 1f)
                    } else {
                        0f
                    }
                    setProgress(
                        workDataOf(
                            KEY_VIDEO_ID to videoId,
                            KEY_PROGRESS to progressRatio,
                            KEY_BYTES_DOWNLOADED to receivedBytes,
                            KEY_TOTAL_BYTES to totalBytes
                        )
                    )
                }
            }

            fos.flush()
            fos.close()
            outputStream = null

            // 3. Size Integrity Verification against catalog
            val finalDownloadedBytes = partFile.length()
            if (expectedSize > 0 && finalDownloadedBytes < (expectedSize * 0.90)) {
                if (partFile.exists()) partFile.delete()
                videoDao.clearDownloadStatus(videoId)
                val errorMsg = "Download truncated: received $finalDownloadedBytes bytes, expected $expectedSize"
                return@withContext Result.failure(
                    workDataOf(
                        KEY_ERROR_MESSAGE to errorMsg,
                        KEY_VIDEO_ID to videoId
                    )
                )
            }

            // 4. Atomic Rename (.part -> .mp4)
            if (finalVideoFile.exists()) {
                finalVideoFile.delete()
            }
            val renamed = partFile.renameTo(finalVideoFile)
            if (!renamed) {
                throw IOException("Failed to atomically rename .part file to final .mp4")
            }

            // 5. Download Thumbnail WebP
            var localThumbPath: String? = null
            if (thumbUrl.isNotEmpty()) {
                try {
                    val thumbRequest = Request.Builder().url(thumbUrl).build()
                    val thumbResponse = okHttpClient.newCall(thumbRequest).execute()
                    if (thumbResponse.isSuccessful && thumbResponse.body != null) {
                        FileOutputStream(thumbFile).use { fos ->
                            thumbResponse.body!!.byteStream().copyTo(fos)
                        }
                        if (thumbFile.exists()) {
                            localThumbPath = thumbFile.absolutePath
                        }
                    }
                } catch (_: Exception) {
                    localThumbPath = null
                }
            }

            // 6. Update database record
            videoDao.updateDownloadStatus(
                videoId = videoId,
                isDownloaded = true,
                downloadedAt = System.currentTimeMillis(),
                localFilePath = finalVideoFile.absolutePath,
                localThumbPath = localThumbPath
            )

            Result.success(
                workDataOf(
                    KEY_VIDEO_ID to videoId,
                    KEY_PROGRESS to 1.0f,
                    KEY_FILE_PATH to finalVideoFile.absolutePath
                )
            )
        } catch (e: Exception) {
            outputStream?.close()
            if (partFile.exists()) {
                partFile.delete()
            }
            videoDao.clearDownloadStatus(videoId)
            val message = e.message ?: "Download failed"
            Result.failure(
                workDataOf(
                    KEY_ERROR_MESSAGE to message,
                    KEY_VIDEO_ID to videoId
                )
            )
        }
    }

    companion object {
        const val KEY_VIDEO_ID = "video_id"
        const val KEY_STREAM_URL = "stream_url"
        const val KEY_THUMB_URL = "thumb_url"
        const val KEY_TITLE = "title"
        const val KEY_EXPECTED_SIZE = "expected_size"
        const val KEY_PROGRESS = "progress"
        const val KEY_BYTES_DOWNLOADED = "bytes_downloaded"
        const val KEY_TOTAL_BYTES = "total_bytes"
        const val KEY_FILE_PATH = "file_path"
        const val KEY_ERROR_MESSAGE = "error_message"
        const val KEY_IS_CANCELLED = "is_cancelled"

        fun getMediaDirectory(context: Context): File {
            val dir = File(context.filesDir, "kidstube_media")
            if (!dir.exists()) {
                dir.mkdirs()
            }
            return dir
        }

        fun formatBytes(bytes: Long): String {
            return when {
                bytes < 1024L * 1024L -> "%.1f KB".format(bytes / 1024.0)
                bytes < 1024L * 1024L * 1024L -> "%.1f MB".format(bytes / (1024.0 * 1024.0))
                else -> "%.2f GB".format(bytes / (1024.0 * 1024.0 * 1024.0))
            }
        }
    }
}
