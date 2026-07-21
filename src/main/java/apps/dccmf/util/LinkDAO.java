package apps.dccmf.util;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO class for managing shareable links (dccmf_links).
 */
public class LinkDAO {

    /**
     * Saves a new link mapping into dccmf_links.
     */
    public void saveLink(String token, int configId, LocalDateTime expiresAt) throws SQLException {
        String sql = "INSERT INTO dccmf_links (token, config_id, expires_at) VALUES (?, ?, ?)";
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, token);
            ps.setInt(2, configId);
            if (expiresAt != null) {
                ps.setTimestamp(3, Timestamp.valueOf(expiresAt));
            } else {
                ps.setNull(3, Types.TIMESTAMP);
            }
            ps.executeUpdate();
        }
    }

    /**
     * Retrieves a LinkEntity by its unique token.
     */
    public LinkEntity getLinkByToken(String token) throws SQLException {
        String sql = "SELECT link_id, token, config_id, status, expires_at, created_at, starts_at FROM dccmf_links WHERE token = ?";
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, token);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Timestamp expTs = rs.getTimestamp("expires_at");
                    Timestamp creTs = rs.getTimestamp("created_at");
                    Timestamp strTs = rs.getTimestamp("starts_at");
                    return new LinkEntity(
                        rs.getInt("link_id"),
                        rs.getString("token"),
                        rs.getInt("config_id"),
                        rs.getString("status"),
                        expTs != null ? expTs.toLocalDateTime() : null,
                        creTs != null ? creTs.toLocalDateTime() : null,
                        strTs != null ? strTs.toLocalDateTime() : null
                    );
                }
            }
        }
        return null;
    }

    /**
     * Updates status of a link (e.g. REVOKED).
     */
    public void updateLinkStatus(String token, String status) throws SQLException {
        String sql = "UPDATE dccmf_links SET status = ? WHERE token = ?";
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, status);
            ps.setString(2, token);
            ps.executeUpdate();
        }
    }

    /**
     * Updates scheduling fields (starts_at, expires_at) and status of a link.
     */
    public void updateLinkSchedule(String token, LocalDateTime startsAt, LocalDateTime expiresAt, String status) throws SQLException {
        String sql = "UPDATE dccmf_links SET starts_at = ?, expires_at = ?, status = ? WHERE token = ?";
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            if (startsAt != null) {
                ps.setTimestamp(1, Timestamp.valueOf(startsAt));
            } else {
                ps.setNull(1, Types.TIMESTAMP);
            }
            if (expiresAt != null) {
                ps.setTimestamp(2, Timestamp.valueOf(expiresAt));
            } else {
                ps.setNull(2, Types.TIMESTAMP);
            }
            ps.setString(3, status);
            ps.setString(4, token);
            ps.executeUpdate();
        }
    }

    /**
     * Lists all generated link entities with metadata info.
     */
    public List<LinkEntity> getAllLinks() throws SQLException {
        List<LinkEntity> links = new ArrayList<>();
        String sql = "SELECT link_id, token, config_id, status, expires_at, created_at, starts_at " +
                     "FROM dccmf_links ORDER BY created_at DESC";
        try (Connection conn = DBConnectionUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                Timestamp expTs = rs.getTimestamp("expires_at");
                Timestamp creTs = rs.getTimestamp("created_at");
                Timestamp strTs = rs.getTimestamp("starts_at");
                links.add(new LinkEntity(
                    rs.getInt("link_id"),
                    rs.getString("token"),
                    rs.getInt("config_id"),
                    rs.getString("status"),
                    expTs != null ? expTs.toLocalDateTime() : null,
                    creTs != null ? creTs.toLocalDateTime() : null,
                    strTs != null ? strTs.toLocalDateTime() : null
                ));
            }
        }
        return links;
    }

    /**
     * Deletes a link token from the database.
     */
    public void deleteLink(String token) throws SQLException {
        String sql = "DELETE FROM dccmf_links WHERE token = ?";
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, token);
            ps.executeUpdate();
        }
    }
}
