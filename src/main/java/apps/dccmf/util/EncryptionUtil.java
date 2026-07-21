package apps.dccmf.util;

import javax.crypto.Cipher;
import javax.crypto.spec.GCMParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.io.InputStream;
import java.nio.charset.StandardCharsets;
import java.security.SecureRandom;
import java.util.Base64;
import java.util.Properties;

/**
 * Security utility for authenticated encryption using AES-256-GCM.
 *
 * <p><strong>Algorithm:</strong> AES/GCM/NoPadding
 * <ul>
 *   <li>Randomly generated 96-bit IV per encryption operation (prevents ciphertext patterns)</li>
 *   <li>128-bit GCM authentication tag (detects tampering)</li>
 *   <li>AES-256 key (32 bytes)</li>
 *   <li>Output: URL-safe Base64( IV[12] + ciphertext + GCM_tag[16] )</li>
 * </ul>
 *
 * <p><strong>Key resolution order (highest priority first):</strong>
 * <ol>
 *   <li>Environment variable: {@code DCCMF_ENCRYPTION_KEY}</li>
 *   <li>Property: {@code encryption.secret.key} in {@code db.properties}</li>
 * </ol>
 *
 * <p>The key must be at least 16 characters. Keys shorter than 32 bytes are
 * zero-padded; keys longer than 32 bytes are truncated to 32 bytes (AES-256).
 *
 * <p><strong>⚠️ Breaking change notice:</strong>
 * Changing the key invalidates all previously encrypted tokens.
 * After a key change, re-generate any {@code Generic} lookup tokens from the admin panel.
 *
 * <p><strong>Production setup (Tomcat setenv.sh):</strong>
 * <pre>
 *   export DCCMF_ENCRYPTION_KEY="$(openssl rand -base64 32)"
 * </pre>
 */
public class EncryptionUtil {

    private static final String ALGORITHM      = "AES/GCM/NoPadding";
    private static final int    GCM_IV_BYTES   = 12;  // 96-bit IV — NIST recommended for GCM
    private static final int    GCM_TAG_BITS   = 128; // 128-bit authentication tag

    /** Lazily loaded and cached secret key bytes (32 bytes = AES-256). */
    private static volatile byte[] cachedKeyBytes = null;

    /** Prevent instantiation — all methods are static. */
    private EncryptionUtil() {}

    // ── Public API ────────────────────────────────────────────────────────────

    /**
     * Encrypts the given plaintext value.
     *
     * @param value the plaintext string to encrypt (must not be null)
     * @return URL-safe Base64-encoded string containing IV + ciphertext + GCM tag
     * @throws RuntimeException if encryption fails
     */
    public static String encrypt(String value) {
        try {
            byte[] iv = new byte[GCM_IV_BYTES];
            new SecureRandom().nextBytes(iv); // Fresh random IV for every encryption

            Cipher cipher = buildCipher(Cipher.ENCRYPT_MODE, iv);
            byte[] ciphertext = cipher.doFinal(value.getBytes(StandardCharsets.UTF_8));

            // Layout: [ IV (12 bytes) ][ ciphertext + GCM tag ]
            byte[] combined = new byte[GCM_IV_BYTES + ciphertext.length];
            System.arraycopy(iv,         0, combined, 0,            GCM_IV_BYTES);
            System.arraycopy(ciphertext, 0, combined, GCM_IV_BYTES, ciphertext.length);

            return Base64.getUrlEncoder().withoutPadding().encodeToString(combined);
        } catch (Exception e) {
            throw new RuntimeException("AES-GCM encryption failed: " + e.getMessage(), e);
        }
    }

    /**
     * Decrypts a token previously produced by {@link #encrypt(String)}.
     *
     * @param encryptedValue URL-safe Base64-encoded token
     * @return the original plaintext string
     * @throws RuntimeException if decryption or authentication fails
     */
    public static String decrypt(String encryptedValue) {
        try {
            byte[] combined = Base64.getUrlDecoder().decode(encryptedValue);
            if (combined.length <= GCM_IV_BYTES) {
                throw new IllegalArgumentException("Invalid encrypted token: too short to contain IV + ciphertext");
            }

            // Split IV from ciphertext+tag
            byte[] iv         = new byte[GCM_IV_BYTES];
            byte[] ciphertext = new byte[combined.length - GCM_IV_BYTES];
            System.arraycopy(combined, 0,            iv,         0, GCM_IV_BYTES);
            System.arraycopy(combined, GCM_IV_BYTES, ciphertext, 0, ciphertext.length);

            Cipher cipher = buildCipher(Cipher.DECRYPT_MODE, iv);
            return new String(cipher.doFinal(ciphertext), StandardCharsets.UTF_8);
        } catch (Exception e) {
            throw new RuntimeException("AES-GCM decryption failed: " + e.getMessage(), e);
        }
    }

    // ── Private helpers ───────────────────────────────────────────────────────

    private static Cipher buildCipher(int mode, byte[] iv) throws Exception {
        SecretKeySpec keySpec = new SecretKeySpec(getKeyBytes(), "AES");
        GCMParameterSpec gcmParams = new GCMParameterSpec(GCM_TAG_BITS, iv);
        Cipher cipher = Cipher.getInstance(ALGORITHM);
        cipher.init(mode, keySpec, gcmParams);
        return cipher;
    }

    /**
     * Loads, normalizes, and caches the AES key.
     * Thread-safe via double-checked locking on a volatile field.
     */
    private static byte[] getKeyBytes() {
        if (cachedKeyBytes != null) return cachedKeyBytes;
        synchronized (EncryptionUtil.class) {
            if (cachedKeyBytes != null) return cachedKeyBytes;

            String rawKey = null;

            // 1. Try environment variable first (highest priority)
            String envKey = System.getenv("DCCMF_ENCRYPTION_KEY");
            if (envKey != null && envKey.length() >= 16) {
                rawKey = envKey;
                System.out.println("[EncryptionUtil] Key loaded from DCCMF_ENCRYPTION_KEY env var.");
            }

            // 2. Fallback to db.properties
            if (rawKey == null) {
                Properties props = new Properties();
                try (InputStream is = EncryptionUtil.class.getClassLoader()
                        .getResourceAsStream("db.properties")) {
                    if (is != null) props.load(is);
                } catch (Exception e) {
                    System.err.println("[EncryptionUtil] Warning: could not read db.properties: " + e.getMessage());
                }
                String propKey = props.getProperty("encryption.secret.key");
                if (propKey != null && propKey.length() >= 16) {
                    rawKey = propKey;
                    System.out.println("[EncryptionUtil] Key loaded from db.properties (encryption.secret.key).");
                }
            }

            if (rawKey == null) {
                // Default fallback key if both env var and db.properties are missing
                rawKey = "DCCMFSecretKey12_CHANGE_ME_NOW!!";
                System.out.println("[EncryptionUtil] Using default hardcoded fallback key.");
            }

            // Normalize to exactly 32 bytes (AES-256): pad with zeros or truncate
            byte[] raw = rawKey.getBytes(StandardCharsets.UTF_8);
            byte[] key = new byte[32];
            System.arraycopy(raw, 0, key, 0, Math.min(raw.length, 32));
            cachedKeyBytes = key;
            return cachedKeyBytes;
        }
    }
}
