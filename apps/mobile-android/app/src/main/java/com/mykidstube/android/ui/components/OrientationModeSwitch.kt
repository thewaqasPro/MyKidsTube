package com.mykidstube.android.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ScreenRotation
import androidx.compose.material.icons.rounded.StayCurrentLandscape
import androidx.compose.material.icons.rounded.StayCurrentPortrait
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mykidstube.android.domain.model.AppOrientationMode
import com.mykidstube.android.ui.theme.KidColors

@Composable
fun OrientationModeSwitch(
    currentMode: AppOrientationMode,
    onModeChanged: (AppOrientationMode) -> Unit,
    modifier: Modifier = Modifier
) {
    val modes = listOf(
        AppOrientationMode.AUTO to Icons.Rounded.ScreenRotation,
        AppOrientationMode.PORTRAIT to Icons.Rounded.StayCurrentPortrait,
        AppOrientationMode.LANDSCAPE to Icons.Rounded.StayCurrentLandscape
    )

    Row(
        modifier = modifier
            .clip(RoundedCornerShape(20.dp))
            .background(KidColors.cardDark)
            .border(1.dp, KidColors.borderDark, RoundedCornerShape(20.dp))
            .padding(3.dp),
        horizontalArrangement = Arrangement.spacedBy(4.dp)
    ) {
        modes.forEach { (mode, icon) ->
            val isSelected = currentMode == mode
            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(16.dp))
                    .background(if (isSelected) KidColors.sky else Color.Transparent)
                    .clickable { onModeChanged(mode) }
                    .padding(horizontal = 8.dp, vertical = 5.dp),
                contentAlignment = Alignment.Center
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(4.dp)
                ) {
                    Icon(
                        imageVector = icon,
                        contentDescription = mode.name,
                        tint = if (isSelected) KidColors.bgDark else KidColors.textMuted,
                        modifier = Modifier.size(16.dp)
                    )
                    Text(
                        text = mode.name.lowercase().replaceFirstChar { it.uppercase() },
                        color = if (isSelected) KidColors.bgDark else KidColors.textMuted,
                        fontSize = 11.sp,
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
                    )
                }
            }
        }
    }
}
