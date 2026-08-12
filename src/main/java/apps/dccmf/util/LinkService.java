package apps.dccmf.util;

import java.sql.SQLException;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

/**
 * Service class handling shareable link generation and validation.
 */
public class LinkService {
    private final LinkDAO linkDAO = new LinkDAO();

    /**
     * Generates a new shareable link with an optional expiration time in hours.
     * @param configId The configuration ID.
     * @param expiryHours Expiration limit in hours (use 0 or negative for no expiration).
     * @return Unique token.
     */
    public String generateLink(int configId, int expiryHours) throws SQLException {
        String token = UUID.randomUUID().toString().replace("-", "");
        LocalDateTime expiresAt = null;
        if (expiryHours > 0) {
            expiresAt = LocalDateTime.now().plusHours(expiryHours);
        }
        linkDAO.saveLink(token, configId, expiresAt);
        return token;
    }

    public LinkEntity getLinkByToken(String token) throws SQLException {
        return linkDAO.getLinkByToken(token);
    }

    public void revokeLink(String token) throws SQLException {
        linkDAO.updateLinkStatus(token, "INACTIVE");
    }

    public void updateLinkSchedule(String token, LocalDateTime startsAt, LocalDateTime expiresAt, String status) throws SQLException {
        linkDAO.updateLinkSchedule(token, startsAt, expiresAt, status);
    }

    public List<LinkEntity> getAllLinks() throws SQLException {
        return linkDAO.getAllLinks();
    }

    public void deleteLink(String token) throws SQLException {
        linkDAO.deleteLink(token);
    }
}
