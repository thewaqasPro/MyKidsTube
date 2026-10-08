package com.mykidstube.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.mykidstube.android.ui.theme.KidColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ParentServerScreen(
    onNavigateBack: () -> Unit,
    viewModel: ParentViewModel = hiltViewModel()
) {
    val currentVpsUrl by viewModel.vpsUrl.collectAsState()
    val currentDeviceName by viewModel.deviceName.collectAsState()
    val pingLatencyMs by viewModel.pingLatencyMs.collectAsState()
    val isTestingPing by viewModel.isTestingPing.collectAsState()
    val isServerOnline by viewModel.isServerOnline.collectAsState()

    var vpsUrlInput by remember { mutableStateOf("") }
    var deviceNameInput by remember { mutableStateOf("") }
    var statusMessage by remember { mutableStateOf<String?>(null) }

    LaunchedEffect(currentVpsUrl, currentDeviceName) {
        vpsUrlInput = currentVpsUrl
        deviceNameInput = currentDeviceName
    }

    Scaffold(
        containerColor = KidColors.bgDark,
        topBar = {
            TopAppBar(
                title = { Text("Server & Pairing", color = Color.White, fontSize = 18.sp, fontWeight = FontWeight.Bold) },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(imageVector = Icons.Rounded.ArrowBackIosNew, contentDescription = "Back", tint = Color.White, modifier = Modifier.size(20.dp))
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(containerColor = KidColors.bgDark)
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
                .verticalScroll(rememberScrollState())
                .padding(24.dp),
            verticalArrangement = Arrangement.spacedBy(18.dp)
        ) {
            // 1. VPS Endpoint Configuration Card
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = KidColors.cardDark),
                border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(KidColors.borderDark)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(18.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text("VPS Server Endpoint", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                    Text(
                        "Point to your Cloudflare Worker portal or local development server.",
                        color = KidColors.textMuted,
                        fontSize = 12.sp,
                        lineHeight = 16.sp
                    )

                    OutlinedTextField(
                        value = vpsUrlInput,
                        onValueChange = { vpsUrlInput = it },
                        label = { Text("Server URL") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(14.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedTextColor = Color.White,
                            unfocusedTextColor = Color.White,
                            focusedBorderColor = KidColors.primary,
                            unfocusedBorderColor = KidColors.borderDark
                        )
                    )

                    Button(
                        onClick = {
                            viewModel.updateVpsUrl(vpsUrlInput.trim())
                            statusMessage = "Server endpoint updated and catalog synced!"
                        },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(14.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = KidColors.primary)
                    ) {
                        Text("Save & Connect", fontWeight = FontWeight.Bold)
                    }
                }
            }

            // 2. Ping Latency Diagnostics
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = KidColors.cardDark),
                border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(KidColors.borderDark)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(18.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Connection Health", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(6.dp)
                        ) {
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .clip(RoundedCornerShape(4.dp))
                                    .background(if (isServerOnline) KidColors.mint else KidColors.red)
                            )
                            Text(
                                if (isServerOnline) "Online" else "Offline",
                                color = if (isServerOnline) KidColors.mint else KidColors.red,
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Bold
                            )
                        }
                    }

                    if (pingLatencyMs != null) {
                        Text(
                            "Round-trip latency: ${pingLatencyMs}ms",
                            color = KidColors.sky,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold
                        )
                    } else if (!isTestingPing) {
                        Text(
                            "Server unreachable or offline.",
                            color = KidColors.red,
                            fontSize = 13.sp
                        )
                    }

                    OutlinedButton(
                        onClick = { viewModel.testPing() },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(14.dp),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = Color.White)
                    ) {
                        if (isTestingPing) {
                            CircularProgressIndicator(color = Color.White, modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
                        } else {
                            Icon(imageVector = Icons.Rounded.Speed, contentDescription = null, modifier = Modifier.size(18.dp))
                            Spacer(modifier = Modifier.width(8.dp))
                            Text("Run Ping Test")
                        }
                    }
                }
            }

            // 3. Device Identification
            Card(
                shape = RoundedCornerShape(18.dp),
                colors = CardDefaults.cardColors(containerColor = KidColors.cardDark),
                border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(KidColors.borderDark)),
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(
                    modifier = Modifier.padding(18.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    Text("Device Name", color = Color.White, fontSize = 15.sp, fontWeight = FontWeight.Bold)

                    OutlinedTextField(
                        value = deviceNameInput,
                        onValueChange = { deviceNameInput = it },
                        label = { Text("Display Name") },
                        singleLine = true,
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(14.dp),
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedTextColor = Color.White,
                            unfocusedTextColor = Color.White,
                            focusedBorderColor = KidColors.primary,
                            unfocusedBorderColor = KidColors.borderDark
                        )
                    )

                    Button(
                        onClick = {
                            viewModel.updateDeviceName(deviceNameInput.trim())
                            statusMessage = "Device name updated!"
                        },
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(14.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = KidColors.cardElevated)
                    ) {
                        Text("Update Name", color = Color.White)
                    }
                }
            }

            if (statusMessage != null) {
                Text(
                    statusMessage!!,
                    color = KidColors.mint,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }
}
