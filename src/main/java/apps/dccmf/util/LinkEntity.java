package apps.dccmf.util;

import java.time.LocalDateTime;

/**
 * Entity class representing a shareable link in dccmf_links.
 * Uses Java 21 record.
 */
public record LinkEntity(
    int linkId,
    String token,
    int configId,
    String status, // ACTIVE, REVOKED, EXPIRED
    LocalDateTime expiresAt,
    LocalDateTime createdAt,
    LocalDateTime startsAt
) {
    public boolean isExpired() {
        return expiresAt != null && expiresAt.isBefore(LocalDateTime.now());
    }

    public boolean isNotStartedYet() {
        return startsAt != null && startsAt.isAfter(LocalDateTime.now());
    }

    public boolean isActive() {
        return "ACTIVE".equalsIgnoreCase(status) && !isExpired() && !isNotStartedYet();
    }
}
