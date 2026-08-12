package apps.dccmf.util;

import java.sql.*;
import java.util.ArrayList;
import java.util.List;

/**
 * DAO class for managing configurations and database metadata retrieval.
 */
public class ConfigDAO {

    /**
     * Fetch all user databases from MySQL instance, excluding internal schemas.
     */
    public List<String> getDatabases() throws SQLException {
        List<String> databases = new ArrayList<>();
        String sql = "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA " +
                     "WHERE SCHEMA_NAME NOT IN ('information_schema', 'mysql', 'performance_schema', 'sys') " +
                     "ORDER BY SCHEMA_NAME";
        try (Connection conn = DBConnectionUtil.getConnection();
             Statement stmt = conn.createStatement();
             ResultSet rs = stmt.executeQuery(sql)) {
            while (rs.next()) {
                databases.add(rs.getString("SCHEMA_NAME"));
            }
        }
        return databases;
    }

    /**
     * Fetch all tables within a given database.
     */
    public List<String> getTables(String dbName) throws SQLException {
        List<String> tables = new ArrayList<>();
        String sql = "SELECT TABLE_NAME FROM INFORMATION_SCHEMA.TABLES " +
                     "WHERE TABLE_SCHEMA = ? AND TABLE_TYPE = 'BASE TABLE' " +
                     "ORDER BY TABLE_NAME";
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, dbName);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    tables.add(rs.getString("TABLE_NAME"));
                }
            }
        }
        return tables;
    }

    /**
     * Fetch details of all columns for a specific database table.
     */
    public List<ColumnConfig> getTableColumns(String dbName, String tableName) throws SQLException {
        List<ColumnConfig> columns = new ArrayList<>();
        String sql = "SELECT COLUMN_NAME, DATA_TYPE FROM INFORMATION_SCHEMA.COLUMNS " +
                     "WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? " +
                     "ORDER BY ORDINAL_POSITION";
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, dbName);
            ps.setString(2, tableName);
            try (ResultSet rs = ps.executeQuery()) {
                while (rs.next()) {
                    String name = rs.getString("COLUMN_NAME");
                    // We generate a default ColumnConfig for new configuration grids
                    columns.add(new ColumnConfig(name, false, false, "TextBox", "", false, "None", "", true, null, null, 5, "png,jpg,pdf,zip"));
                }
            }
        }
        return columns;
    }

    /**
     * Saves a TableConfig object to dccmf_config. Overwrites if a configuration for the table already exists.
     * @return generated or updated config_id.
     */
    public int saveConfig(TableConfig config, Integer editConfigId, String createdBy) throws SQLException {
        String json = JsonUtil.toJson(config);
        
        // If in Edit Mode (from Manage Links), update existing config in-place
        if (editConfigId != null) {
            String updateSql = "UPDATE dccmf_config SET config_json = ?, updated_at = CURRENT_TIMESTAMP WHERE config_id = ?";
            try (Connection conn = DBConnectionUtil.getConnection();
                 PreparedStatement updatePs = conn.prepareStatement(updateSql)) {
                updatePs.setString(1, json);
                updatePs.setInt(2, editConfigId);
                updatePs.executeUpdate();
            }
            System.out.println("[ConfigDAO] Updated config_id: " + editConfigId + " in-place.");
            return editConfigId;
        }

        // Otherwise, always insert new config row to generate a brand new configId and link
        String insertSql = "INSERT INTO dccmf_config (db_name, table_name, config_json, created_by) VALUES (?, ?, ?, ?)";
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement insertPs = conn.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
            insertPs.setString(1, config.database());
            insertPs.setString(2, config.table());
            insertPs.setString(3, json);
            insertPs.setString(4, createdBy);
            insertPs.executeUpdate();
            
            try (ResultSet keys = insertPs.getGeneratedKeys()) {
                if (keys.next()) {
                    int newId = keys.getInt(1);
                    System.out.println("[ConfigDAO] Inserted new config_id: " + newId);
                    return newId;
                }
            }
        }
        throw new SQLException("Failed to save config, no keys generated.");
    }

    public int saveConfig(TableConfig config, String createdBy) throws SQLException {
        return saveConfig(config, null, createdBy);
    }

    /**
     * Retrieve a configuration by its ID.
     */
    public TableConfig getConfigById(int configId) throws SQLException {
        String sql = "SELECT config_json FROM dccmf_config WHERE config_id = ?";
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setInt(1, configId);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String json = rs.getString("config_json");
                    return JsonUtil.fromJson(json, TableConfig.class);
                }
            }
        }
        return null;
    }

    /**
     * Retrieve a configuration by database name and table name.
     */
    public TableConfig getConfigByDbAndTable(String dbName, String tableName) throws SQLException {
        // Retrieve the latest saved configuration (highest config_id)
        String sql = "SELECT config_json FROM dccmf_config WHERE db_name = ? AND table_name = ? ORDER BY config_id DESC LIMIT 1";
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setString(1, dbName);
            ps.setString(2, tableName);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    String json = rs.getString("config_json");
                    return JsonUtil.fromJson(json, TableConfig.class);
                }
            }
        }
        return null;
    }
}
