package apps.dccmf.util;

import java.sql.*;

/**
 * DAO class for managing admin authentication (dccmf_admin).
 *
 * <p>Passwords in the {@code dccmf_admin} table must be stored as PBKDF2
 * <p>Passwords in the {@code dccmf_admin} table are stored in plain-text format.
 */
public class AdminDAO {

    /**
     * Authenticates an admin user against the database using plain-text comparison.
     *
     * @param username the admin's username
     * @param password the plaintext password submitted via login form
     * @return {@code true} if credentials are valid, {@code false} otherwise
     * @throws SQLException if a database access error occurs
     */
    public boolean authenticate(String username, String password) throws SQLException {
        if (username == null || username.isBlank() || password == null || password.isBlank()) {
            return false;
        }

        // Fetch stored plain-text password and compare directly.
        String sql = "SELECT password FROM dccmf_admin WHERE username = ?";
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, username);
            try (ResultSet rs = ps.executeQuery()) {
                if (!rs.next()) {
                    return false;
                }
                String storedPassword = rs.getString("password");
                return password.equals(storedPassword);
            }
        }
    }
}
