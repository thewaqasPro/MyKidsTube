package com.mykidstube.android.data.api

import com.mykidstube.android.data.store.SecurityService
import okhttp3.Interceptor
import okhttp3.Response
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class AuthInterceptor @Inject constructor(
    private val securityService: SecurityService
) : Interceptor {

    override fun intercept(chain: Interceptor.Chain): Response {
        val originalRequest = chain.request()
        val requestBuilder = originalRequest.newBuilder()

        val urlPath = originalRequest.url.encodedPath
        val isParentEndpoint = urlPath.contains("/api/v1/ingest") ||
                urlPath.contains("/api/studio/videos")

        val parentToken = securityService.getParentSessionToken()
        val deviceToken = securityService.getDeviceToken()

        if (isParentEndpoint && !parentToken.isNullOrEmpty()) {
            requestBuilder.header("Authorization", "Bearer $parentToken")
            requestBuilder.header("Cookie", "kidstube_parent_session=$parentToken")
        } else if (!deviceToken.isNullOrEmpty()) {
            requestBuilder.header("Authorization", "Bearer $deviceToken")
            if (!parentToken.isNullOrEmpty()) {
                requestBuilder.header("Cookie", "kidstube_parent_session=$parentToken")
            }
        }

        requestBuilder.header("Accept", "application/json")

        val response = chain.proceed(requestBuilder.build())

        // Capture session cookie from login endpoint
        if (urlPath.contains("/api/auth/login") && response.isSuccessful) {
            val setCookieHeaders = response.headers("Set-Cookie")
            for (header in setCookieHeaders) {
                if (header.contains("kidstube_parent_session=")) {
                    val match = Regex("""kidstube_parent_session=([^;]+)""").find(header)
                    match?.groupValues?.getOrNull(1)?.let { token ->
                        if (token.isNotEmpty()) {
                            securityService.setParentSessionToken(token.trim())
                        }
                    }
                }
            }
        }

        return response
    }
}
