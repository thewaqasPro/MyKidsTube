package com.mykidstube.android.ui.screens

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.mykidstube.android.data.repository.KidsTubeRepository
import com.mykidstube.android.data.store.SecurityService
import com.mykidstube.android.data.store.SettingsDataStore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import javax.inject.Inject
import kotlin.math.min

data class PairingUiState(
    val pairingCode: String? = null,
    val isRequesting: Boolean = false,
    val isExpired: Boolean = false,
    val isTimedOut: Boolean = false,
    val isPaired: Boolean = false,
    val isUsingDefaultPin: Boolean = true
)

@HiltViewModel
class PairingViewModel @Inject constructor(
    private val repository: KidsTubeRepository,
    private val securityService: SecurityService,
    private val settingsDataStore: SettingsDataStore
) : ViewModel() {

    private val _uiState = MutableStateFlow(PairingUiState())
    val uiState: StateFlow<PairingUiState> = _uiState.asStateFlow()

    private var pollJob: Job? = null
    private var pollIntervalMs = 2500L
    private var totalElapsedSeconds = 0

    init {
        startPairingFlow()
    }

    fun startPairingFlow() {
        pollJob?.cancel()
        _uiState.value = PairingUiState(isRequesting = true)
        pollIntervalMs = 2500L
        totalElapsedSeconds = 0

        viewModelScope.launch {
            val deviceName = settingsDataStore.deviceName.first()
            val result = repository.registerDevice(deviceName)
            if (result != null) {
                val (_, code) = result
                _uiState.value = _uiState.value.copy(
                    pairingCode = code,
                    isRequesting = false,
                    isExpired = false,
                    isTimedOut = false
                )
                startPolling(code)
            } else {
                _uiState.value = _uiState.value.copy(
                    isRequesting = false,
                    isExpired = true
                )
            }
        }
    }

    private fun startPolling(code: String) {
        pollJob?.cancel()
        pollJob = viewModelScope.launch {
            while (true) {
                delay(pollIntervalMs)
                totalElapsedSeconds += (pollIntervalMs / 1000).toInt().coerceAtLeast(1)

                // 5 minute timeout cap
                if (totalElapsedSeconds >= 300) {
                    _uiState.value = _uiState.value.copy(isTimedOut = true)
                    break
                }

                val status = repository.checkPairingStatus(code)
                if (status == "paired") {
                    val isDefaultPin = securityService.isUsingDefaultPin()
                    _uiState.value = _uiState.value.copy(
                        isPaired = true,
                        isUsingDefaultPin = isDefaultPin
                    )
                    break
                } else if (status == "expired") {
                    _uiState.value = _uiState.value.copy(isExpired = true)
                    break
                }

                // Exponential backoff capped at 10 seconds
                pollIntervalMs = min(10000L, (pollIntervalMs * 1.25).toLong())
            }
        }
    }

    override fun onCleared() {
        super.onCleared()
        pollJob?.cancel()
    }
}
