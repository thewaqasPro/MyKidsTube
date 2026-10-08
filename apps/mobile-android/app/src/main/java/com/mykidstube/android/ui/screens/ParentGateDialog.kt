package com.mykidstube.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.Shield
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import com.mykidstube.android.data.repository.KidsTubeRepository
import com.mykidstube.android.data.store.SecurityService
import com.mykidstube.android.ui.theme.KidColors
import kotlinx.coroutines.launch

@Composable
fun ParentGateDialog(
    onDismiss: () -> Unit,
    onSuccess: (isForceChangeRequired: Boolean) -> Unit,
    securityService: SecurityService,
    repository: KidsTubeRepository
) {
    var pinText by remember { mutableStateOf("") }
    var errorMessage by remember { mutableStateOf<String?>(null) }
    var isVerifying by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()

    Dialog(onDismissRequest = onDismiss) {
        Card(
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(containerColor = KidColors.cardDark),
            border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(KidColors.borderDark)),
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp)
        ) {
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Icon(
                    imageVector = Icons.Rounded.Shield,
                    contentDescription = null,
                    tint = KidColors.primary,
                    modifier = Modifier.size(48.dp)
                )

                Text(
                    text = "Grown-Ups Only",
                    color = KidColors.textLight,
                    fontSize = 20.sp,
                    fontWeight = FontWeight.Bold
                )

                Text(
                    text = "Enter your Parent PIN to manage library settings, downloads, and security.",
                    color = KidColors.textMuted,
                    fontSize = 13.sp,
                    textAlign = TextAlign.Center,
                    lineHeight = 18.sp
                )

                OutlinedTextField(
                    value = pinText,
                    onValueChange = {
                        if (it.length <= 8 && it.all { ch -> ch.isDigit() }) {
                            pinText = it
                            errorMessage = null
                        }
                    },
                    visualTransformation = PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                    keyboardActions = KeyboardActions(
                        onDone = {
                            if (pinText.length >= 4) {
                                isVerifying = true
                                val valid = securityService.verifyParentPin(pinText)
                                if (valid) {
                                    scope.launch {
                                        repository.loginParent(pinText)
                                    }
                                    val forceChange = securityService.isUsingDefaultPin()
                                    onSuccess(forceChange)
                                } else {
                                    errorMessage = "Incorrect Parent PIN. Try again!"
                                    pinText = ""
                                }
                                isVerifying = false
                            }
                        }
                    ),
                    placeholder = {
                        Text(
                            text = "••••",
                            color = KidColors.textTertiary,
                            modifier = Modifier.fillMaxWidth(),
                            textAlign = TextAlign.Center
                        )
                    },
                    isError = errorMessage != null,
                    singleLine = true,
                    colors = OutlinedTextFieldDefaults.colors(
                        focusedTextColor = Color.White,
                        unfocusedTextColor = Color.White,
                        focusedBorderColor = KidColors.primary,
                        unfocusedBorderColor = KidColors.borderDark,
                        focusedContainerColor = KidColors.bgDark,
                        unfocusedContainerColor = KidColors.bgDark
                    ),
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier.fillMaxWidth()
                )

                if (errorMessage != null) {
                    Text(
                        text = errorMessage!!,
                        color = KidColors.red,
                        fontSize = 12.sp,
                        fontWeight = FontWeight.SemiBold
                    )
                }

                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    OutlinedButton(
                        onClick = onDismiss,
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(14.dp),
                        colors = ButtonDefaults.outlinedButtonColors(contentColor = KidColors.textMuted)
                    ) {
                        Text("Cancel")
                    }

                    Button(
                        onClick = {
                            if (pinText.length >= 4) {
                                isVerifying = true
                                val valid = securityService.verifyParentPin(pinText)
                                if (valid) {
                                    scope.launch {
                                        repository.loginParent(pinText)
                                    }
                                    val forceChange = securityService.isUsingDefaultPin()
                                    onSuccess(forceChange)
                                } else {
                                    errorMessage = "Incorrect Parent PIN. Try again!"
                                    pinText = ""
                                }
                                isVerifying = false
                            } else {
                                errorMessage = "PIN must be at least 4 digits."
                            }
                        },
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(14.dp),
                        colors = ButtonDefaults.buttonColors(
                            containerColor = KidColors.primary,
                            contentColor = Color.White
                        )
                    ) {
                        if (isVerifying) {
                            CircularProgressIndicator(
                                color = Color.White,
                                strokeWidth = 2.dp,
                                modifier = Modifier.size(16.dp)
                            )
                        } else {
                            Text("Unlock", fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }
        }
    }
}
