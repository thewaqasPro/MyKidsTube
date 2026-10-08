package com.mykidstube.android.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mykidstube.android.ui.theme.KidColors

@Composable
fun ShortsActionRail(
    isFavorite: Boolean,
    onToggleFavorite: () -> Unit,
    isMuted: Boolean,
    onToggleMute: () -> Unit,
    autoAdvance: Boolean,
    onToggleAutoAdvance: () -> Unit,
    onLock: () -> Unit,
    modifier: Modifier = Modifier
) {
    Column(
        modifier = modifier
            .padding(end = 12.dp, bottom = 48.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // 1. Favorite Button
        RailActionButton(
            icon = if (isFavorite) Icons.Rounded.Star else Icons.Rounded.StarBorder,
            label = if (isFavorite) "Liked" else "Like",
            tint = if (isFavorite) KidColors.accent else Color.White,
            onClick = onToggleFavorite
        )

        // 2. Mute / Unmute Button
        RailActionButton(
            icon = if (isMuted) Icons.Rounded.VolumeOff else Icons.Rounded.VolumeUp,
            label = if (isMuted) "Muted" else "Sound",
            tint = Color.White,
            onClick = onToggleMute
        )

        // 3. Auto-Advance vs Loop Toggle
        RailActionButton(
            icon = if (autoAdvance) Icons.Rounded.Autorenew else Icons.Rounded.RepeatOne,
            label = if (autoAdvance) "Auto" else "Loop",
            tint = if (autoAdvance) KidColors.sky else KidColors.yellow,
            onClick = onToggleAutoAdvance
        )

        // 4. Lock Screen Button
        RailActionButton(
            icon = Icons.Rounded.Lock,
            label = "Lock",
            tint = Color.White,
            onClick = onLock
        )
    }
}

@Composable
private fun RailActionButton(
    icon: ImageVector,
    label: String,
    tint: Color,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        IconButton(
            onClick = onClick,
            modifier = Modifier
                .size(48.dp)
                .background(Color.Black.copy(alpha = 0.5f), CircleShape)
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = tint,
                modifier = Modifier.size(24.dp)
            )
        }
        Text(
            text = label,
            color = Color.White,
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium
        )
    }
}
