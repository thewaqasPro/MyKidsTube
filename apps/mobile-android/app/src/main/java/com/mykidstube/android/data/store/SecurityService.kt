package com.mykidstube.android.data.store

import android.content.Context
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import dagger.hilt.android.qualifiers.ApplicationContext
import java.security.MessageDigest
import java.security.SecureRandom
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SecurityService @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private val masterKey = MasterKey.Builder(context)
        .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
        .build()

    private val securePrefs = try {
        createPrefs()
    } catch (e: Exception) {
        // If master key was invalidated (e.g. app reinstall / OS keystore reset), wipe and recreate
        context.getSharedPreferences("kidstube_secure_prefs", Context.MODE_PRIVATE).edit().clear().apply()
        createPrefs()
    }

    private fun createPrefs() = EncryptedSharedPreferences.create(
        context,
        "kidstube_secure_prefs",
        masterKey,
        EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
        EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
    )

    init {
        initPinSecurity()
    }

    @Synchronized
    fun getOrCreateSalt(): String {
        var salt = securePrefs.getString(KEY_PIN_SALT, null)
        if (salt.isNullOrEmpty()) {
            val random = SecureRandom()
            val bytes = ByteArray(16)
            random.nextBytes(bytes)
            salt = bytes.joinToString("") { "%02x".format(it) }
            securePrefs.edit().putString(KEY_PIN_SALT, salt).apply()
        }
        return salt
    }

    fun hashPin(pin: String, salt: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val input = "$salt:$pin".toByteArray(Charsets.UTF_8)
        val hash = digest.digest(input)
        return hash.joinToString("") { "%02x".format(it) }
    }

    private fun initPinSecurity() {
        val salt = getOrCreateSalt()
        val storedHash = securePrefs.getString(KEY_PIN_HASH, null)
        if (storedHash.isNullOrEmpty()) {
            // Default pin is "1234" on fresh install
            val defaultHash = hashPin("1234", salt)
            securePrefs.edit().putString(KEY_PIN_HASH, defaultHash).apply()
        }
    }

    fun verifyParentPin(enteredPin: String): Boolean {
        val salt = getOrCreateSalt()
        val storedHash = securePrefs.getString(KEY_PIN_HASH, null) ?: return enteredPin == "1234"
        val enteredHash = hashPin(enteredPin, salt)
        return enteredHash == storedHash
    }

    fun changeParentPin(currentPin: String, newPin: String): Boolean {
        if (!verifyParentPin(currentPin)) return false
        if (newPin.length < 4 || !newPin.all { it.isDigit() }) return false

        val salt = getOrCreateSalt()
        val newHash = hashPin(newPin, salt)
        securePrefs.edit().putString(KEY_PIN_HASH, newHash).apply()
        return true
    }

    fun isUsingDefaultPin(): Boolean {
        val salt = getOrCreateSalt()
        val storedHash = securePrefs.getString(KEY_PIN_HASH, null) ?: return true
        val defaultHash = hashPin("1234", salt)
        return storedHash == defaultHash
    }

    // --- Device Auth Token ---
    fun getDeviceToken(): String? {
        return securePrefs.getString(KEY_DEVICE_TOKEN, null)
    }

    fun setDeviceToken(token: String?) {
        securePrefs.edit().putString(KEY_DEVICE_TOKEN, token).apply()
    }

    // --- Parent Session Token ---
    fun getParentSessionToken(): String? {
        return securePrefs.getString(KEY_PARENT_SESSION_TOKEN, null)
    }

    fun setParentSessionToken(token: String?) {
        securePrefs.edit().putString(KEY_PARENT_SESSION_TOKEN, token).apply()
    }

    fun clearAll() {
        securePrefs.edit().clear().apply()
        initPinSecurity()
    }

    companion object {
        private const val KEY_PIN_SALT = "parent_pin_salt"
        private const val KEY_PIN_HASH = "parent_pin_hash"
        private const val KEY_DEVICE_TOKEN = "device_auth_token"
        private const val KEY_PARENT_SESSION_TOKEN = "parent_session_token"
    }
}
