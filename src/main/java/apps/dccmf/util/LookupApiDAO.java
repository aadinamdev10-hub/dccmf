package apps.dccmf.util;

import java.sql.*;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO class for managing lookup API configurations (dccmf_api).
 */
public class LookupApiDAO {

    public void saveLookupApi(String apiLink) throws SQLException {
        // Prevent duplicate registration of the same lookup link
        String checkSql = "SELECT COUNT(*) FROM dccmf_api WHERE api_link = ?";
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement checkPs = conn.prepareStatement(checkSql)) {
            checkPs.setString(1, apiLink);
            try (ResultSet rs = checkPs.executeQuery()) {
                if (rs.next() && rs.getInt(1) > 0) {
                    return; 
                }
            }
        }

        String sql = "INSERT INTO dccmf_api (api_link) VALUES (?)";
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, apiLink);
            ps.executeUpdate();
        }
    }

    public List<LookupApiEntity> getAllLookupApis() throws SQLException {
        List<LookupApiEntity> apis = new ArrayList<>();
        String sql = "SELECT id, api_link, created_at FROM dccmf_api ORDER BY created_at DESC";
        try (Connection conn = DBConnectionUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                Timestamp creTs = rs.getTimestamp("created_at");
                apis.add(new LookupApiEntity(
                    rs.getInt("id"),
                    rs.getString("api_link"),
                    creTs != null ? creTs.toLocalDateTime() : null
                ));
            }
        }
        return apis;
    }

    public void deleteLookupApi(int id) throws SQLException {
        String sql = "DELETE FROM dccmf_api WHERE id = ?";
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, id);
            ps.executeUpdate();
        }
    }
}
