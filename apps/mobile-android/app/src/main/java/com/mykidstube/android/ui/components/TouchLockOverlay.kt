package com.mykidstube.android.ui.components

import androidx.activity.compose.BackHandler
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.LinearEasing
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.LockOpen
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mykidstube.android.ui.theme.KidColors
import kotlinx.coroutines.launch

@Composable
fun TouchLockOverlay(
    isLocked: Boolean,
    onLock: () -> Unit,
    onUnlock: () -> Unit,
    showLockButton: Boolean = true,
    modifier: Modifier = Modifier
) {
    val haptic = LocalHapticFeedback.current
    val progress = remember { Animatable(0f) }
    val scope = rememberCoroutineScope()

    if (isLocked) {
        // Intercept and swallow Android hardware / gesture back button
        BackHandler(enabled = true) {
            haptic.performHapticFeedback(HapticFeedbackType.LongPress)
        }

        Box(
            modifier = modifier
                .fillMaxSize()
                // Absorb all underlying touches
                .pointerInput(Unit) {
                    detectTapGestures { /* Absorbed */ }
                }
        ) {
            // Prominent 3s-hold unlock pill in top-right
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(top = 28.dp, end = 24.dp)
                    .clip(RoundedCornerShape(24.dp))
                    .background(Color.Black.copy(alpha = 0.85f))
                    .border(1.5.dp, KidColors.accent, RoundedCornerShape(24.dp))
                    .pointerInput(Unit) {
                        detectTapGestures(
                            onPress = {
                                haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                val animJob = scope.launch {
                                    progress.animateTo(
                                        targetValue = 1f,
                                        animationSpec = tween(durationMillis = 3000, easing = LinearEasing)
                                    )
                                }
                                val released = tryAwaitRelease()
                                if (progress.value >= 1f) {
                                    haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                    onUnlock()
                                    scope.launch { progress.snapTo(0f) }
                                } else {
                                    animJob.cancel()
                                    scope.launch {
                                        progress.animateTo(
                                            targetValue = 0f,
                                            animationSpec = tween(durationMillis = 200)
                                        )
                                    }
                                }
                            }
                        )
                    }
                    .padding(horizontal = 16.dp, vertical = 10.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(10.dp)
                ) {
                    Box(
                        modifier = Modifier.size(24.dp),
                        contentAlignment = Alignment.Center
                    ) {
                        CircularProgressIndicator(
                            progress = { progress.value },
                            modifier = Modifier.fillMaxSize(),
                            color = KidColors.accent,
                            trackColor = Color.White.copy(alpha = 0.2f),
                            strokeWidth = 3.dp
                        )
                        Icon(
                            imageVector = Icons.Rounded.Lock,
                            contentDescription = null,
                            tint = Color.White,
                            modifier = Modifier.size(13.dp)
                        )
                    }
                    Text(
                        text = if (progress.value > 0f) "Hold to unlock..." else "Hold 3s to Unlock",
                        color = Color.White,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }
    } else if (showLockButton) {
        Box(
            modifier = modifier
                .fillMaxSize()
        ) {
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(top = 24.dp, end = 24.dp)
                    .clip(RoundedCornerShape(20.dp))
                    .background(Color.Black.copy(alpha = 0.6f))
                    .border(1.dp, Color.White.copy(alpha = 0.3f), RoundedCornerShape(20.dp))
                    .pointerInput(Unit) {
                        detectTapGestures(
                            onTap = {
                                haptic.performHapticFeedback(HapticFeedbackType.LongPress)
                                onLock()
                            }
                        )
                    }
                    .padding(horizontal = 14.dp, vertical = 8.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    Icon(
                        imageVector = Icons.Rounded.LockOpen,
                        contentDescription = "Lock Screen",
                        tint = Color.White,
                        modifier = Modifier.size(18.dp)
                    )
                    Text(
                        text = "Lock Screen",
                        color = Color.White,
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }
            }
        }
    }
}
