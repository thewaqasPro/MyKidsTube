package com.mykidstube.android

import org.junit.Assert.*
import org.junit.Test
import java.security.MessageDigest
import java.security.SecureRandom

class PinSecurityTest {

    private fun generateSalt(): String {
        val random = SecureRandom()
        val bytes = ByteArray(16)
        random.nextBytes(bytes)
        return bytes.joinToString("") { "%02x".format(it) }
    }

    private fun hashPin(pin: String, salt: String): String {
        val digest = MessageDigest.getInstance("SHA-256")
        val input = "$salt:$pin".toByteArray(Charsets.UTF_8)
        val hash = digest.digest(input)
        return hash.joinToString("") { "%02x".format(it) }
    }

    @Test
    fun testPinHashAndVerifyRoundTrip() {
        val salt = generateSalt()
        assertEquals(32, salt.length) // 16 bytes = 32 hex chars

        val pin = "5829"
        val hash = hashPin(pin, salt)

        // Verifying with correct PIN matches
        val testHashCorrect = hashPin("5829", salt)
        assertEquals(hash, testHashCorrect)

        // Verifying with incorrect PIN fails
        val testHashIncorrect = hashPin("1234", salt)
        assertNotEquals(hash, testHashIncorrect)

        // Different salts produce distinct hashes even for same PIN
        val salt2 = generateSalt()
        val hashSalt2 = hashPin(pin, salt2)
        assertNotEquals(hash, hashSalt2)
    }

    @Test
    fun testDefaultPinDetection() {
        val salt = generateSalt()
        val defaultHash = hashPin("1234", salt)

        assertTrue(hashPin("1234", salt) == defaultHash)
        assertFalse(hashPin("9999", salt) == defaultHash)
    }

    @Test
    fun testPinValidationRules() {
        fun isValidPin(pin: String): Boolean {
            return pin.length >= 4 && pin.all { it.isDigit() }
        }

        assertTrue(isValidPin("1234"))
        assertTrue(isValidPin("123456"))
        assertFalse(isValidPin("123")) // < 4 digits
        assertFalse(isValidPin("12ab")) // letters
        assertFalse(isValidPin("    ")) // blank
    }
}
