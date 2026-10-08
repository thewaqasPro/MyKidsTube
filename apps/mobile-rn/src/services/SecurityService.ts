import * as SecureStore from 'expo-secure-store';
import * as Crypto from 'expo-crypto';

const SALT_KEY = 'parent_pin_salt';
const PIN_HASH_KEY = 'parent_pin_hash';
const AUTH_TOKEN_KEY = 'device_auth_token';

class SecurityService {
  private static instance: SecurityService;

  public static getInstance(): SecurityService {
    if (!SecurityService.instance) {
      SecurityService.instance = new SecurityService();
    }
    return SecurityService.instance;
  }

  private constructor() {}

  /**
   * Generates or retrieves a 16-byte cryptographically secure random salt in hex (32 hex characters)
   */
  public async getOrCreateSalt(): Promise<string> {
    try {
      let salt = await SecureStore.getItemAsync(SALT_KEY);
      if (!salt || salt.length === 0) {
        const randomBytes = await Crypto.getRandomBytesAsync(16);
        salt = Array.from(randomBytes)
          .map((b) => b.toString(16).padStart(2, '0'))
          .join('');
        await SecureStore.setItemAsync(SALT_KEY, salt);
      }
      return salt;
    } catch (e) {
      // Fallback for secure store failure
      return 'c0ffee0123456789abcdef0123456789';
    }
  }

  /**
   * Computes salted SHA-256 hash of PIN in lowercase hex: sha256(salt:pin)
   */
  public async hashPin(pin: string, salt: string): Promise<string> {
    const combined = `${salt}:${pin}`;
    const hash = await Crypto.digestStringAsync(
      Crypto.CryptoDigestAlgorithm.SHA256,
      combined
    );
    return hash.toLowerCase();
  }

  /**
   * Initializes PIN storage on first launch with default '1234' if none exists
   */
  public async initPinIfNeeded(): Promise<void> {
    const salt = await this.getOrCreateSalt();
    const storedHash = await SecureStore.getItemAsync(PIN_HASH_KEY);
    if (!storedHash) {
      const defaultHash = await this.hashPin('1234', salt);
      await SecureStore.setItemAsync(PIN_HASH_KEY, defaultHash);
    }
  }

  /**
   * Returns true if active PIN is the default '1234'
   */
  public async isUsingDefaultPin(): Promise<boolean> {
    const salt = await this.getOrCreateSalt();
    let storedHash = await SecureStore.getItemAsync(PIN_HASH_KEY);
    if (!storedHash) {
      await this.initPinIfNeeded();
      storedHash = await SecureStore.getItemAsync(PIN_HASH_KEY);
    }
    const defaultHash = await this.hashPin('1234', salt);
    return storedHash === defaultHash;
  }

  /**
   * Verifies an entered PIN against the salted SHA-256 stored hash
   */
  public async verifyPin(enteredPin: string): Promise<boolean> {
    if (!enteredPin || enteredPin.length < 4) return false;
    const salt = await this.getOrCreateSalt();
    const storedHash = await SecureStore.getItemAsync(PIN_HASH_KEY);
    if (!storedHash) {
      await this.initPinIfNeeded();
      const defaultHash = await this.hashPin('1234', salt);
      const enteredHash = await this.hashPin(enteredPin, salt);
      return enteredHash === defaultHash;
    }
    const enteredHash = await this.hashPin(enteredPin, salt);
    return enteredHash === storedHash;
  }

  /**
   * Updates PIN with salted SHA-256 hash. Enforces minimum 4 characters.
   */
  public async changePin(newPin: string): Promise<boolean> {
    if (!newPin || newPin.trim().length < 4) {
      throw new Error('PIN must be at least 4 digits');
    }
    const cleanPin = newPin.trim();
    const salt = await this.getOrCreateSalt();
    const newHash = await this.hashPin(cleanPin, salt);
    await SecureStore.setItemAsync(PIN_HASH_KEY, newHash);
    return true;
  }

  /**
   * Manages device authentication token from portal pairing
   */
  public async getAuthToken(): Promise<string | null> {
    return await SecureStore.getItemAsync(AUTH_TOKEN_KEY);
  }

  public async setAuthToken(token: string): Promise<void> {
    await SecureStore.setItemAsync(AUTH_TOKEN_KEY, token);
  }

  public async clearAuthToken(): Promise<void> {
    await SecureStore.deleteItemAsync(AUTH_TOKEN_KEY);
  }
}

export const securityService = SecurityService.getInstance();
