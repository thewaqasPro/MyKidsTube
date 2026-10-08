package com.mykidstube.android.data.api

import com.mykidstube.android.data.api.model.*
import retrofit2.Response
import retrofit2.http.*

interface KidsTubeApi {

    @GET("/api/v1/health")
    suspend fun checkHealth(): Response<HealthResponseDto>

    @POST("/api/v1/devices/register")
    suspend fun registerDevice(
        @Body request: RegisterDeviceRequestDto
    ): Response<RegisterDeviceResponseDto>

    @GET("/api/v1/devices/status/{code}")
    suspend fun checkDeviceStatus(
        @Path("code") code: String
    ): Response<DeviceStatusResponseDto>

    @GET("/api/v1/catalog")
    suspend fun getCatalog(
        @Query("profile_id") profileId: String? = null
    ): Response<CatalogResponseDto>

    @GET("/api/v1/profiles")
    suspend fun getProfiles(): Response<List<ProfileDto>>

    @POST("/api/auth/login")
    suspend fun loginParent(
        @Body request: LoginRequestDto
    ): Response<LoginResponseDto>

    @POST("/api/v1/ingest")
    suspend fun ingestVideo(
        @Body request: IngestRequestDto
    ): Response<IngestResponseDto>

    @DELETE("/api/studio/videos")
    suspend fun deleteVideos(
        @Query("ids") ids: String
    ): Response<Unit>

    @POST("/api/metrics/watch")
    suspend fun syncWatchMetrics(
        @Body request: WatchBatchRequestDto
    ): Response<WatchSyncResponseDto>
}
