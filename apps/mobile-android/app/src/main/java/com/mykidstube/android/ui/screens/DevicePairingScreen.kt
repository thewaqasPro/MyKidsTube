package com.mykidstube.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Refresh
import androidx.compose.material.icons.rounded.Tv
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.mykidstube.android.ui.theme.KidColors

@Composable
fun DevicePairingScreen(
    onPaired: (isDefaultPin: Boolean) -> Unit,
    viewModel: PairingViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(uiState.isPaired) {
        if (uiState.isPaired) {
            onPaired(uiState.isUsingDefaultPin)
        }
    }

    Scaffold(
        containerColor = KidColors.bgDark
    ) { paddingValues ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues),
            contentAlignment = Alignment.Center
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(28.dp)
                    .verticalScroll(rememberScrollState()),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                // 1. App Icon Badge
                Box(
                    modifier = Modifier
                        .size(80.dp)
                        .clip(RoundedCornerShape(22.dp))
                        .background(
                            Brush.linearGradient(
                                listOf(KidColors.primary, KidColors.accent)
                            )
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Rounded.Tv,
                        contentDescription = "KidsTube",
                        tint = Color.White,
                        modifier = Modifier.size(44.dp)
                    )
                }

                Spacer(modifier = Modifier.height(24.dp))

                // 2. Welcome Title & Subtitle
                Text(
                    text = "Welcome to KidsTube!",
                    color = KidColors.textLight,
                    fontSize = 26.sp,
                    fontWeight = FontWeight.ExtraBold,
                    textAlign = TextAlign.Center
                )

                Spacer(modifier = Modifier.height(10.dp))

                Text(
                    text = "To pair this device with your family library,\nopen your Parent Dashboard and enter this code:",
                    color = KidColors.textMuted,
                    fontSize = 14.sp,
                    textAlign = TextAlign.Center,
                    lineHeight = 20.sp
                )

                Spacer(modifier = Modifier.height(32.dp))

                // 3. 6-Digit Pairing Code Box
                val isInactive = uiState.isExpired || uiState.isTimedOut
                val borderColor = if (isInactive) KidColors.red else KidColors.primary

                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(20.dp))
                        .background(KidColors.cardDark)
                        .border(2.dp, borderColor, RoundedCornerShape(20.dp))
                        .padding(horizontal = 28.dp, vertical = 18.dp),
                    contentAlignment = Alignment.Center
                ) {
                    if (uiState.isRequesting) {
                        CircularProgressIndicator(
                            color = KidColors.primary,
                            strokeWidth = 3.dp,
                            modifier = Modifier.size(36.dp)
                        )
                    } else {
                        val displayText = when {
                            uiState.isTimedOut -> "TIMED OUT"
                            uiState.isExpired -> "EXPIRED"
                            else -> uiState.pairingCode ?: "---"
                        }
                        Text(
                            text = displayText,
                            color = if (isInactive) KidColors.red else KidColors.textLight,
                            fontSize = if (isInactive) 26.sp else 36.sp,
                            fontWeight = FontWeight.ExtraBold,
                            fontFamily = FontFamily.Monospace,
                            letterSpacing = if (isInactive) 2.sp else 4.sp
                        )
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // 4. Status Indicator or Expired State
                if (uiState.isExpired || uiState.isTimedOut) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(14.dp))
                            .background(KidColors.red.copy(alpha = 0.15f))
                            .border(1.dp, KidColors.red.copy(alpha = 0.4f), RoundedCornerShape(14.dp))
                            .padding(horizontal = 18.dp, vertical = 14.dp),
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        Text(
                            text = if (uiState.isTimedOut) {
                                "Pairing session timed out (5 minutes)."
                            } else {
                                "Pairing code expired or invalid."
                            },
                            color = KidColors.red,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.SemiBold,
                            textAlign = TextAlign.Center
                        )
                        Button(
                            onClick = { viewModel.startPairingFlow() },
                            colors = ButtonDefaults.buttonColors(
                                containerColor = KidColors.primary,
                                contentColor = Color.White
                            ),
                            shape = RoundedCornerShape(18.dp),
                            contentPadding = PaddingValues(horizontal = 20.dp, vertical = 10.dp)
                        ) {
                            Icon(
                                imageVector = Icons.Rounded.Refresh,
                                contentDescription = null,
                                modifier = Modifier.size(18.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(text = "Generate New Code", fontSize = 13.sp, fontWeight = FontWeight.Bold)
                        }
                    }
                } else if (!uiState.isRequesting) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(10.dp)
                    ) {
                        CircularProgressIndicator(
                            color = KidColors.accent,
                            strokeWidth = 2.dp,
                            modifier = Modifier.size(16.dp)
                        )
                        Text(
                            text = "Waiting for parent authorization...",
                            color = KidColors.textMuted,
                            fontSize = 13.sp
                        )
                    }
                }
            }
        }
    }
}
