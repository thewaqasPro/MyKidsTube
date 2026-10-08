package com.mykidstube.android.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.Icon
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.mykidstube.android.ui.theme.KidColors

@Composable
fun ChildAvatar(
    avatarIcon: String,
    modifier: Modifier = Modifier,
    size: Dp = 44.dp
) {
    val (icon, gradient) = getAvatarConfig(avatarIcon)

    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(Brush.linearGradient(gradient)),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = Color.White,
            modifier = Modifier.size(size * 0.58f)
        )
    }
}

private fun getAvatarConfig(avatarIcon: String): Pair<ImageVector, List<Color>> {
    return when (avatarIcon.lowercase()) {
        "bear" -> Icons.Rounded.Pets to listOf(KidColors.primary, KidColors.accent)
        "lion" -> Icons.Rounded.CrueltyFree to listOf(KidColors.accent, KidColors.sun)
        "unicorn", "stars" -> Icons.Rounded.AutoAwesome to listOf(KidColors.violet, KidColors.bubblegum)
        "rocket" -> Icons.Rounded.RocketLaunch to listOf(KidColors.sky, KidColors.primary)
        "astronaut" -> Icons.Rounded.Face to listOf(KidColors.mint, KidColors.sky)
        "panda" -> Icons.Rounded.Mood to listOf(KidColors.cardElevated, KidColors.borderDark)
        "fox" -> Icons.Rounded.Celebration to listOf(KidColors.coral, KidColors.yellow)
        "dino" -> Icons.Rounded.Forest to listOf(KidColors.green, KidColors.sky)
        else -> Icons.Rounded.Face to listOf(KidColors.primary, KidColors.accent)
    }
}
