package apps.dccmf.util;

import java.time.LocalDateTime;

/**
 * Entity class representing a generated Lookup API.
 * Uses Java 21 record.
 */
public record LookupApiEntity(
    int id,
    String apiLink,
    LocalDateTime createdAt
) {
    public String database() {
        try {
            int index = apiLink.indexOf("t=");
            if (index != -1) {
                String token = apiLink.substring(index + 2);
                String decrypted = EncryptionUtil.decrypt(token);
                return decrypted.split(":")[0];
            }
        } catch (Exception e) {
            // Fallback if decryption fails
        }
        return "N/A";
    }

    public String tableName() {
        try {
            int index = apiLink.indexOf("t=");
            if (index != -1) {
                String token = apiLink.substring(index + 2);
                String decrypted = EncryptionUtil.decrypt(token);
                return decrypted.split(":")[1];
            }
        } catch (Exception e) {
            // Fallback if decryption fails
        }
        return "N/A";
    }
}
