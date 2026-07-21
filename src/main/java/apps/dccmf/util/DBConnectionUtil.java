package apps.dccmf.util;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

/**
 * DBConnectionUtil helper class that handles JDBC driver loading
 * and connection creation using hardcoded credentials.
 * Completely self-contained with no external properties or dependency classes.
 */
public class DBConnectionUtil {

    private static final String URL      = "jdbc:mysql://localhost:3306/dccmf_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=UTC";
    private static final String USERNAME = "root";
    private static final String PASSWORD = "#Akshat54321";
    private static final String DRIVER   = "com.mysql.cj.jdbc.Driver";

    private static boolean initialized = false;

    private static synchronized void init() {
        if (initialized) return;
        try {
            Class.forName(DRIVER);
            initialized = true;
            System.out.println("[DBConnectionUtil] Database driver loaded successfully.");
        } catch (ClassNotFoundException e) {
            throw new RuntimeException("DBConnectionUtil init failed: " + e.getMessage(), e);
        }
    }

    /**
     * Factory method that returns a new active JDBC connection to MySQL using hardcoded credentials.
     */
    public static Connection getConnection() throws SQLException {
        init();
        return DriverManager.getConnection(URL, USERNAME, PASSWORD);
    }

    /**
     * Closes the database connection safely.
     */
    public static void closeConnection(Connection con) {
        if (con != null) {
            try {
                con.close();
            } catch (SQLException e) {
                // Ignore
            }
        }
    }

    public static void closePool() {
        // No-op for backward compatibility
    }
}
