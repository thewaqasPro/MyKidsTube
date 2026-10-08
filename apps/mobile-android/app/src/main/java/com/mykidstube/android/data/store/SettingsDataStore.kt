package com.mykidstube.android.data.store

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.*
import androidx.datastore.preferences.preferencesDataStore
import com.mykidstube.android.domain.model.AppOrientationMode
import com.mykidstube.android.domain.model.UrlHelpers
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.map
import java.io.IOException
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "kidstube_settings")

@Singleton
class SettingsDataStore @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val dataStore = context.dataStore

    val vpsUrl: Flow<String> = dataStore.data
        .catch { if (it is IOException) emit(emptyPreferences()) else throw it }
        .map { it[KEY_VPS_URL] ?: UrlHelpers.DEFAULT_SERVER_URL }

    val deviceName: Flow<String> = dataStore.data
        .catch { if (it is IOException) emit(emptyPreferences()) else throw it }
        .map { it[KEY_DEVICE_NAME] ?: "Kids Tablet" }

    val isDevicePaired: Flow<Boolean> = dataStore.data
        .catch { if (it is IOException) emit(emptyPreferences()) else throw it }
        .map { it[KEY_IS_DEVICE_PAIRED] ?: false }

    val currentProfileId: Flow<String?> = dataStore.data
        .catch { if (it is IOException) emit(emptyPreferences()) else throw it }
        .map { it[KEY_CURRENT_PROFILE_ID] }

    val currentProfileName: Flow<String?> = dataStore.data
        .catch { if (it is IOException) emit(emptyPreferences()) else throw it }
        .map { it[KEY_CURRENT_PROFILE_NAME] }

    val currentProfileAvatar: Flow<String?> = dataStore.data
        .catch { if (it is IOException) emit(emptyPreferences()) else throw it }
        .map { it[KEY_CURRENT_PROFILE_AVATAR] }

    val orientationMode: Flow<AppOrientationMode> = dataStore.data
        .catch { if (it is IOException) emit(emptyPreferences()) else throw it }
        .map {
            when (it[KEY_ORIENTATION_MODE]) {
                "PORTRAIT" -> AppOrientationMode.PORTRAIT
                "LANDSCAPE" -> AppOrientationMode.LANDSCAPE
                else -> AppOrientationMode.AUTO
            }
        }

    val isOfflineOnly: Flow<Boolean> = dataStore.data
        .catch { if (it is IOException) emit(emptyPreferences()) else throw it }
        .map { it[KEY_OFFLINE_ONLY] ?: false }

    suspend fun setVpsUrl(url: String) {
        dataStore.edit { it[KEY_VPS_URL] = UrlHelpers.normalizeServerUrl(url) }
    }

    suspend fun setDeviceName(name: String) {
        dataStore.edit { it[KEY_DEVICE_NAME] = name.trim().take(64) }
    }

    suspend fun setIsDevicePaired(isPaired: Boolean) {
        dataStore.edit { it[KEY_IS_DEVICE_PAIRED] = isPaired }
    }

    suspend fun setCurrentProfile(id: String, name: String, avatar: String) {
        dataStore.edit {
            it[KEY_CURRENT_PROFILE_ID] = id
            it[KEY_CURRENT_PROFILE_NAME] = name
            it[KEY_CURRENT_PROFILE_AVATAR] = avatar
        }
    }

    suspend fun setOrientationMode(mode: AppOrientationMode) {
        dataStore.edit { it[KEY_ORIENTATION_MODE] = mode.name }
    }

    suspend fun setOfflineOnly(offline: Boolean) {
        dataStore.edit { it[KEY_OFFLINE_ONLY] = offline }
    }

    suspend fun clearSettings() {
        dataStore.edit { it.clear() }
    }

    companion object {
        private val KEY_VPS_URL = stringPreferencesKey("vps_url")
        private val KEY_DEVICE_NAME = stringPreferencesKey("device_name")
        private val KEY_IS_DEVICE_PAIRED = booleanPreferencesKey("is_device_paired")
        private val KEY_CURRENT_PROFILE_ID = stringPreferencesKey("current_profile_id")
        private val KEY_CURRENT_PROFILE_NAME = stringPreferencesKey("current_profile_name")
        private val KEY_CURRENT_PROFILE_AVATAR = stringPreferencesKey("current_profile_avatar")
        private val KEY_ORIENTATION_MODE = stringPreferencesKey("orientation_mode")
        private val KEY_OFFLINE_ONLY = booleanPreferencesKey("offline_only")
    }
}
