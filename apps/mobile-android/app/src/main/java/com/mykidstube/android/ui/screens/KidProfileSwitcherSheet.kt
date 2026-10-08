package com.mykidstube.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Add
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.mykidstube.android.domain.model.ChildProfile
import com.mykidstube.android.ui.components.ChildAvatar
import com.mykidstube.android.ui.theme.KidColors

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun KidProfileSwitcherSheet(
    activeProfile: ChildProfile?,
    profiles: List<ChildProfile>,
    onSelectProfile: (ChildProfile) -> Unit,
    onAddProfile: (name: String, avatar: String) -> Unit,
    onOpenParentGate: () -> Unit,
    onDismiss: () -> Unit
) {
    var showAddDialog by remember { mutableStateOf(false) }
    var newProfileName by remember { mutableStateOf("") }
    var newProfileAvatar by remember { mutableStateOf("bear") }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        containerColor = KidColors.surfaceDark,
        shape = RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 24.dp, vertical = 16.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp)
        ) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    "Who's Watching?",
                    color = Color.White,
                    fontSize = 18.sp,
                    fontWeight = FontWeight.Bold
                )

                TextButton(onClick = {
                    onDismiss()
                    onOpenParentGate()
                }) {
                    Icon(imageVector = Icons.Rounded.Lock, contentDescription = null, tint = KidColors.accent, modifier = Modifier.size(16.dp))
                    Spacer(modifier = Modifier.width(6.dp))
                    Text("Grown-Ups", color = KidColors.accent, fontWeight = FontWeight.SemiBold)
                }
            }

            // Profile Avatars Row
            LazyRow(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                items(profiles) { profile ->
                    val isSelected = activeProfile?.id == profile.id
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier
                            .clip(RoundedCornerShape(16.dp))
                            .clickable {
                                onSelectProfile(profile)
                                onDismiss()
                            }
                            .padding(8.dp)
                    ) {
                        Box(contentAlignment = Alignment.BottomEnd) {
                            ChildAvatar(
                                avatarIcon = profile.avatarIcon,
                                size = 64.dp,
                                modifier = if (isSelected) {
                                    Modifier.border(3.dp, KidColors.sky, CircleShape)
                                } else Modifier
                            )
                            if (isSelected) {
                                Box(
                                    modifier = Modifier
                                        .size(20.dp)
                                        .clip(CircleShape)
                                        .background(KidColors.sky),
                                    contentAlignment = Alignment.Center
                                ) {
                                    Icon(
                                        imageVector = Icons.Rounded.Check,
                                        contentDescription = null,
                                        tint = KidColors.bgDark,
                                        modifier = Modifier.size(14.dp)
                                    )
                                }
                            }
                        }

                        Text(
                            text = profile.name,
                            color = if (isSelected) KidColors.sky else Color.White,
                            fontSize = 13.sp,
                            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
                        )
                    }
                }

                // Add Child Profile Button
                item {
                    Column(
                        horizontalAlignment = Alignment.CenterHorizontally,
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                        modifier = Modifier
                            .clip(RoundedCornerShape(16.dp))
                            .clickable { showAddDialog = true }
                            .padding(8.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(64.dp)
                                .clip(CircleShape)
                                .background(KidColors.cardElevated)
                                .border(1.5.dp, KidColors.borderDark, CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Rounded.Add,
                                contentDescription = "Add Profile",
                                tint = KidColors.textMuted,
                                modifier = Modifier.size(28.dp)
                            )
                        }
                        Text("Add Kid", color = KidColors.textMuted, fontSize = 13.sp)
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))
        }
    }

    if (showAddDialog) {
        val avatarChoices = listOf("bear", "lion", "unicorn", "rocket", "astronaut", "dino")
        AlertDialog(
            onDismissRequest = { showAddDialog = false },
            title = { Text("Add Child Profile", color = Color.White) },
            text = {
                Column(verticalArrangement = Arrangement.spacedBy(14.dp)) {
                    OutlinedTextField(
                        value = newProfileName,
                        onValueChange = { newProfileName = it },
                        label = { Text("Child's Name") },
                        singleLine = true,
                        colors = OutlinedTextFieldDefaults.colors(
                            focusedTextColor = Color.White,
                            unfocusedTextColor = Color.White,
                            focusedBorderColor = KidColors.sky
                        )
                    )

                    Text("Pick an Avatar Icon:", color = KidColors.textMuted, fontSize = 12.sp)

                    LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        items(avatarChoices) { av ->
                            val isChosen = newProfileAvatar == av
                            Box(
                                modifier = Modifier
                                    .clip(CircleShape)
                                    .clickable { newProfileAvatar = av }
                                    .border(if (isChosen) 2.5.dp else 0.dp, KidColors.sky, CircleShape)
                                    .padding(2.dp)
                            ) {
                                ChildAvatar(avatarIcon = av, size = 44.dp)
                            }
                        }
                    }
                }
            },
            confirmButton = {
                Button(
                    onClick = {
                        if (newProfileName.trim().isNotEmpty()) {
                            onAddProfile(newProfileName.trim(), newProfileAvatar)
                            showAddDialog = false
                        }
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = KidColors.sky)
                ) {
                    Text("Add Profile", color = KidColors.bgDark, fontWeight = FontWeight.Bold)
                }
            },
            dismissButton = {
                TextButton(onClick = { showAddDialog = false }) {
                    Text("Cancel", color = Color.White)
                }
            },
            containerColor = KidColors.cardDark
        )
    }
}
