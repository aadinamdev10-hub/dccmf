package apps.dccmf.util;

import java.sql.SQLException;

/**
 * Service class handling admin authentication.
 */
public class AdminService {
    private final AdminDAO adminDAO = new AdminDAO();

    /**
     * Authenticates the admin credentials.
     * @param username the username
     * @param password the password
     * @return true if credentials are valid, false otherwise.
     */
    public boolean authenticate(String username, String password) {
        try {
            return adminDAO.authenticate(username, password);
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }
    }
}
