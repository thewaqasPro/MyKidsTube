package com.mykidstube.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.text.input.VisualTransformation
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.mykidstube.android.ui.theme.KidColors
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ParentSecurityScreen(
    onNavigateBack: () -> Unit,
    isForceChange: Boolean = false,
    onSuccess: () -> Unit,
    viewModel: ParentViewModel = hiltViewModel()
) {
    var currentPin by remember { mutableStateOf(if (isForceChange) "1234" else "") }
    var newPin by remember { mutableStateOf("") }
    var confirmPin by remember { mutableStateOf("") }

    var obscureCurrent by remember { mutableStateOf(true) }
    var obscureNew by remember { mutableStateOf(true) }
    var obscureConfirm by remember { mutableStateOf(true) }

    var message by remember { mutableStateOf<String?>(null) }
    var isError by remember { mutableStateOf(false) }
    var isSaving by remember { mutableStateOf(false) }

    val scope = rememberCoroutineScope()

    Scaffold(
        containerColor = KidColors.bgDark,
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        if (isForceChange) "Setup Secure Parent PIN" else "Parent PIN & Security",
                        color = Color.White,
                        fontSize = 18.sp,
                        fontWeight = FontWeight.Bold
                    )
                },
                navigationIcon = {
                    if (!isForceChange) {
                        IconButton(onClick = onNavigateBack) {
                            Icon(
                                imageVector = Icons.Rounded.ArrowBackIosNew,
                                contentDescription = "Back",
                                tint = Color.White,
                                modifier = Modifier.size(20.dp)
                            )
                        }
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
            if (isForceChange) {
                Card(
                    shape = RoundedCornerShape(16.dp),
                    colors = CardDefaults.cardColors(containerColor = KidColors.accent.copy(alpha = 0.15f)),
                    border = CardDefaults.outlinedCardBorder().copy(brush = androidx.compose.ui.graphics.SolidColor(KidColors.accent.copy(alpha = 0.4f)))
                ) {
                    Row(
                        modifier = Modifier.padding(16.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Icon(imageVector = Icons.Rounded.Security, contentDescription = null, tint = KidColors.accent)
                        Text(
                            text = "First-time setup: please change the default PIN (1234) to a private numeric code.",
                            color = KidColors.accent,
                            fontSize = 13.sp,
                            lineHeight = 18.sp
                        )
                    }
                }
            }

            // Current PIN
            OutlinedTextField(
                value = currentPin,
                onValueChange = { if (it.all { ch -> ch.isDigit() }) currentPin = it },
                label = { Text("Current PIN") },
                visualTransformation = if (obscureCurrent) PasswordVisualTransformation() else VisualTransformation.None,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                trailingIcon = {
                    IconButton(onClick = { obscureCurrent = !obscureCurrent }) {
                        Icon(
                            imageVector = if (obscureCurrent) Icons.Rounded.Visibility else Icons.Rounded.VisibilityOff,
                            contentDescription = null,
                            tint = KidColors.textMuted
                        )
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White,
                    focusedBorderColor = KidColors.primary,
                    unfocusedBorderColor = KidColors.borderDark
                )
            )

            // New PIN
            OutlinedTextField(
                value = newPin,
                onValueChange = { if (it.all { ch -> ch.isDigit() }) newPin = it },
                label = { Text("New PIN (min 4 digits)") },
                visualTransformation = if (obscureNew) PasswordVisualTransformation() else VisualTransformation.None,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                trailingIcon = {
                    IconButton(onClick = { obscureNew = !obscureNew }) {
                        Icon(
                            imageVector = if (obscureNew) Icons.Rounded.Visibility else Icons.Rounded.VisibilityOff,
                            contentDescription = null,
                            tint = KidColors.textMuted
                        )
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White,
                    focusedBorderColor = KidColors.primary,
                    unfocusedBorderColor = KidColors.borderDark
                )
            )

            // Confirm New PIN
            OutlinedTextField(
                value = confirmPin,
                onValueChange = { if (it.all { ch -> ch.isDigit() }) confirmPin = it },
                label = { Text("Confirm New PIN") },
                visualTransformation = if (obscureConfirm) PasswordVisualTransformation() else VisualTransformation.None,
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.NumberPassword),
                trailingIcon = {
                    IconButton(onClick = { obscureConfirm = !obscureConfirm }) {
                        Icon(
                            imageVector = if (obscureConfirm) Icons.Rounded.Visibility else Icons.Rounded.VisibilityOff,
                            contentDescription = null,
                            tint = KidColors.textMuted
                        )
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedTextColor = Color.White,
                    unfocusedTextColor = Color.White,
                    focusedBorderColor = KidColors.primary,
                    unfocusedBorderColor = KidColors.borderDark
                )
            )

            if (message != null) {
                Text(
                    text = message!!,
                    color = if (isError) KidColors.red else KidColors.mint,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold
                )
            }

            Spacer(modifier = Modifier.height(10.dp))

            Button(
                onClick = {
                    val current = currentPin.trim()
                    val new = newPin.trim()
                    val confirm = confirmPin.trim()

                    if (current.isEmpty() || new.isEmpty() || confirm.isEmpty()) {
                        message = "Please fill in all PIN fields."
                        isError = true
                        return@Button
                    }
                    if (new.length < 4) {
                        message = "New PIN must be at least 4 numeric digits."
                        isError = true
                        return@Button
                    }
                    if (new != confirm) {
                        message = "New PIN and confirmation do not match."
                        isError = true
                        return@Button
                    }

                    isSaving = true
                    scope.launch {
                        val success = viewModel.changePin(current, new)
                        isSaving = false
                        if (success) {
                            message = "Parent PIN successfully updated!"
                            isError = false
                            onSuccess()
                        } else {
                            message = "Incorrect current PIN. Please try again."
                            isError = true
                        }
                    }
                },
                modifier = Modifier.fillMaxWidth().height(52.dp),
                shape = RoundedCornerShape(16.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = KidColors.primary,
                    contentColor = Color.White
                )
            ) {
                if (isSaving) {
                    CircularProgressIndicator(color = Color.White, modifier = Modifier.size(20.dp), strokeWidth = 2.dp)
                } else {
                    Text("Save PIN", fontSize = 16.sp, fontWeight = FontWeight.Bold)
                }
            }
        }
    }
}
