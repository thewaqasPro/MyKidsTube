package com.mykidstube.android.ui.components

import android.annotation.SuppressLint
import android.graphics.Bitmap
import android.view.ViewGroup
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.foundation.background
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.WifiOff
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.viewinterop.AndroidView
import com.mykidstube.android.domain.model.UrlHelpers
import com.mykidstube.android.ui.theme.KidColors

@SuppressLint("SetJavaScriptEnabled")
@Composable
fun KidEmbedPlayer(
    youtubeId: String,
    modifier: Modifier = Modifier,
    autoPlay: Boolean = true
) {
    var isLoading by remember { mutableStateOf(true) }
    var hasError by remember { mutableStateOf(false) }
    var retryKey by remember { mutableIntStateOf(0) }

    val cleanId = UrlHelpers.getYoutubeId(youtubeId)

    val html = remember(cleanId, autoPlay, retryKey) {
        val autoPlayFlag = if (autoPlay) 1 else 0
        """
        <!DOCTYPE html>
        <html>
        <head>
          <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
          <style>
            * { box-sizing: border-box; margin: 0; padding: 0; }
            html, body {
              width: 100%;
              height: 100%;
              background-color: #000000;
              overflow: hidden;
              display: flex;
              align-items: center;
              justify-content: center;
            }
            iframe {
              width: 100%;
              height: 100%;
              border: 0;
            }
          </style>
        </head>
        <body>
          <iframe
            id="player"
            src="https://www.youtube-nocookie.com/embed/$cleanId?autoplay=$autoPlayFlag&controls=0&playsinline=1&modestbranding=1&rel=0&iv_load_policy=3&disablekb=1&enablejsapi=1&origin=https://www.youtube-nocookie.com"
            allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture"
            allowfullscreen>
          </iframe>
          <script>
            var tag = document.createElement('script');
            tag.src = "https://www.youtube.com/iframe_api";
            var firstScriptTag = document.getElementsByTagName('script')[0];
            firstScriptTag.parentNode.insertBefore(tag, firstScriptTag);

            var player;
            function onYouTubeIframeAPIReady() {
              player = new YT.Player('player', {
                events: {
                  'onReady': function(event) {
                    ${if (autoPlay) "try { event.target.playVideo(); } catch(e) {}" else ""}
                  }
                }
              });
            }
          </script>
        </body>
        </html>
        """.trimIndent()
    }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .aspectRatio(16f / 9f)
            .background(Color.Black)
    ) {
        // 1. Sandboxed Android WebView
        AndroidView(
            modifier = Modifier.fillMaxSize(),
            factory = { context ->
                WebView(context).apply {
                    layoutParams = ViewGroup.LayoutParams(
                        ViewGroup.LayoutParams.MATCH_PARENT,
                        ViewGroup.LayoutParams.MATCH_PARENT
                    )
                    settings.javaScriptEnabled = true
                    settings.domStorageEnabled = true
                    settings.mediaPlaybackRequiresUserGesture = false
                    settings.allowFileAccess = false
                    settings.allowContentAccess = false
                    setBackgroundColor(android.graphics.Color.BLACK)

                    webViewClient = object : WebViewClient() {
                        override fun onPageStarted(view: WebView?, url: String?, favicon: Bitmap?) {
                            isLoading = true
                            hasError = false
                        }

                        override fun onPageFinished(view: WebView?, url: String?) {
                            isLoading = false
                        }

                        override fun onReceivedError(
                            view: WebView?,
                            request: WebResourceRequest?,
                            error: WebResourceError?
                        ) {
                            if (request?.isForMainFrame == true) {
                                isLoading = false
                                hasError = true
                            }
                        }

                        override fun shouldOverrideUrlLoading(
                            view: WebView?,
                            request: WebResourceRequest?
                        ): Boolean {
                            val targetUrl = request?.url?.toString() ?: ""
                            // Strictly restrict navigation: only allow youtube-nocookie.com embeds or about:blank
                            if (targetUrl.contains("youtube-nocookie.com/embed") ||
                                targetUrl.startsWith("data:") ||
                                targetUrl.startsWith("about:blank")
                            ) {
                                return false // Allow internal embed navigation
                            }
                            // Block any external link clicking / navigation
                            return true
                        }
                    }

                    loadDataWithBaseURL(
                        "https://www.youtube-nocookie.com",
                        html,
                        "text/html",
                        "UTF-8",
                        null
                    )
                }
            },
            update = { webView ->
                webView.loadDataWithBaseURL(
                    "https://www.youtube-nocookie.com",
                    html,
                    "text/html",
                    "UTF-8",
                    null
                )
            }
        )

        // 2. Click-Jacking Shield 1: Top link shield (prevents clicking title/author out to YouTube)
        if (!hasError) {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(48.dp)
                    .align(Alignment.TopCenter)
                    .pointerInput(Unit) {
                        detectTapGestures { /* Absorbed */ }
                    }
            )
        }

        // 3. Click-Jacking Shield 2: Bottom-right YouTube logo shield
        if (!hasError) {
            Box(
                modifier = Modifier
                    .width(84.dp)
                    .height(48.dp)
                    .align(Alignment.BottomEnd)
                    .pointerInput(Unit) {
                        detectTapGestures { /* Absorbed */ }
                    }
            )
        }

        // 4. Loading Indicator
        if (isLoading && !hasError) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator(
                    color = KidColors.primary,
                    strokeWidth = 3.dp,
                    modifier = Modifier.size(36.dp)
                )
            }
        }

        // 5. Error UI with Retry
        if (hasError) {
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .background(Color.Black),
                contentAlignment = Alignment.Center
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Icon(
                        imageVector = Icons.Rounded.WifiOff,
                        contentDescription = null,
                        tint = KidColors.red,
                        modifier = Modifier.size(36.dp)
                    )
                    Text(
                        text = "Unable to stream embed.",
                        color = Color.White,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                    Button(
                        onClick = { retryKey++ },
                        colors = ButtonDefaults.buttonColors(
                            containerColor = KidColors.primary,
                            contentColor = Color.White
                        ),
                        shape = RoundedCornerShape(16.dp),
                        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Rounded.Refresh,
                            contentDescription = "Retry",
                            modifier = Modifier.size(16.dp)
                        )
                        Spacer(modifier = Modifier.width(6.dp))
                        Text(text = "Retry", fontSize = 12.sp)
                    }
                }
            }
        }
    }
}
