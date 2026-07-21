package apps.dccmf.util;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashSet;
import java.util.Set;

/**
 * Guard utility to protect against SQL Injection on dynamic identifiers (table and column names).
 * Since identifiers cannot be parameterized using standard JDBC PreparedStatement placeholder markers,
 * they must be strictly whitelisted against database schema metadata.
 */
public class SqlInjectionGuard {

    /**
     * Checks if the table name is valid for a given database.
     * @param dbName Database name.
     * @param tableName Table name.
     * @return true if the table exists, false otherwise.
     */
    public static boolean isValidTable(String dbName, String tableName) {
        if (tableName == null || tableName.trim().isEmpty()) {
            return false;
        }
        
        // Sanity regex check to ensure no weird SQL chars exist prior to query
        if (!tableName.matches("^[a-zA-Z0-9_]+$")) {
            return false;
        }

        String sql = "SELECT COUNT(*) FROM INFORMATION_SCHEMA.TABLES " +
                     "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?";
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, dbName);
            ps.setString(2, tableName);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
        }
        return false;
    }

    /**
     * Checks if all provided column names exist in the specified table.
     * @param dbName Database name.
     * @param tableName Table name.
     * @param columnNames Set of column names to validate.
     * @return true if all columns exist, false otherwise.
     */
    public static boolean isValidColumns(String dbName, String tableName, Set<String> columnNames) {
        if (!isValidTable(dbName, tableName)) {
            return false;
        }
        if (columnNames == null || columnNames.isEmpty()) {
            return true;
        }

        // Quick regex check on every column name
        for (String col : columnNames) {
            if (col == null || !col.matches("^[a-zA-Z0-9_]+$")) {
                return false;
            }
        }

        String sql = "SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS " +
                     "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ?";
        Set<String> validColumns = new HashSet<>();
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, dbName);
            ps.setString(2, tableName);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    validColumns.add(rs.getString("COLUMN_NAME").toLowerCase());
                }
            }
        } catch (SQLException e) {
            e.printStackTrace();
            return false;
        }

        for (String col : columnNames) {
            if (!validColumns.contains(col.toLowerCase())) {
                return false; // Found a column name not matching metadata
            }
        }
        return true;
    }
}
