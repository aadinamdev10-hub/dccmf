package apps.dccmf.util;

import java.sql.*;
import java.util.*;

/**
 * DAO class for running dynamic SELECT and UPDATE queries on tables,
 * driven by the user config and protected by SQL injection guards.
 */
public class DynamicQueryDAO {

    /**
     * Executes a dynamic SELECT query on a table based on search parameters.
     * @param dbName Database name.
     * @param tableName Table name.
     * @param searchCriteria Map of column names to search values.
     * @return List of rows, where each row is represented as a Map of columnName -> value.
     */
    public List<Map<String, Object>> searchRecords(String dbName, String tableName, Map<String, Object> searchCriteria) throws SQLException {
        return searchRecords(dbName, tableName, searchCriteria, null, null);
    }

    public List<Map<String, Object>> searchRecords(String dbName, String tableName, Map<String, Object> searchCriteria, Integer limit, Integer offset) throws SQLException {
        // 1. Guard against SQL Injection by validating table name and search column names
        if (!SqlInjectionGuard.isValidTable(dbName, tableName)) {
            throw new SecurityException("Access Denied: Invalid table name - " + tableName);
        }
        if (!SqlInjectionGuard.isValidColumns(dbName, tableName, searchCriteria.keySet())) {
            throw new SecurityException("Access Denied: Invalid search columns - " + searchCriteria.keySet());
        }

        // 2. Build the SELECT SQL statement
        StringBuilder sql = new StringBuilder("SELECT * FROM ");
        // Safety check: Quote database and table name to prevent conflicts with SQL reserved words
        sql.append("`").append(dbName).append("`.`").append(tableName).append("`");

        List<Object> params = new ArrayList<>();
        if (!searchCriteria.isEmpty()) {
            sql.append(" WHERE ");
            int index = 0;
            for (Map.Entry<String, Object> entry : searchCriteria.entrySet()) {
                if (index > 0) {
                    sql.append(" AND ");
                }
                sql.append("`").append(entry.getKey()).append("` = ?");
                params.add(entry.getValue());
                index++;
            }
        }

        if (limit != null && offset != null) {
            sql.append(" LIMIT ").append(limit).append(" OFFSET ").append(offset);
        }

        // 3. Execute the statement
        List<Map<String, Object>> results = new ArrayList<>();
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, normalizeParamValue(params.get(i)));
            }

            try (ResultSet rs = ps.executeQuery()) {
                ResultSetMetaData rsmd = rs.getMetaData();
                int columnCount = rsmd.getColumnCount();
                
                while (rs.next()) {
                    Map<String, Object> row = new LinkedHashMap<>();
                    for (int i = 1; i <= columnCount; i++) {
                        String colName = rsmd.getColumnLabel(i);
                        Object colVal = rs.getObject(i);
                        // Convert dates or other special objects to string representation if needed
                        if (colVal instanceof java.util.Date) {
                            row.put(colName, colVal.toString());
                        } else {
                            row.put(colName, colVal);
                        }
                    }
                    results.add(row);
                }
            }
        }
        return results;
    }

    /**
     * Counts the total number of records matching the search criteria.
     */
    public long countRecords(String dbName, String tableName, Map<String, Object> searchCriteria) throws SQLException {
        if (!SqlInjectionGuard.isValidTable(dbName, tableName)) {
            throw new SecurityException("Access Denied: Invalid table name - " + tableName);
        }
        if (!SqlInjectionGuard.isValidColumns(dbName, tableName, searchCriteria.keySet())) {
            throw new SecurityException("Access Denied: Invalid search columns - " + searchCriteria.keySet());
        }

        StringBuilder sql = new StringBuilder("SELECT COUNT(*) FROM ");
        sql.append("`").append(dbName).append("`.`").append(tableName).append("`");

        List<Object> params = new ArrayList<>();
        if (!searchCriteria.isEmpty()) {
            sql.append(" WHERE ");
            int index = 0;
            for (Map.Entry<String, Object> entry : searchCriteria.entrySet()) {
                if (index > 0) {
                    sql.append(" AND ");
                }
                sql.append("`").append(entry.getKey()).append("` = ?");
                params.add(entry.getValue());
                index++;
            }
        }

        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, normalizeParamValue(params.get(i)));
            }

            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getLong(1);
                }
            }
        }
        return 0;
    }

    /**
     * Executes a dynamic UPDATE query on a table.
     * @param dbName Database name.
     * @param tableName Table name.
     * @param updateValues Map of column names to new values (these must be whitelisted as editable).
     * @param whereCriteria Map of column names to match values (e.g. primary key / search key).
     * @return number of rows updated.
     */
    public int updateRecord(String dbName, String tableName, Map<String, Object> updateValues, Map<String, Object> whereCriteria) throws SQLException {
        if (updateValues.isEmpty()) {
            return 0; // Nothing to update
        }

        // 1. Guard against SQL Injection by validating table name and all column names (update cols and where cols)
        if (!SqlInjectionGuard.isValidTable(dbName, tableName)) {
            throw new SecurityException("Access Denied: Invalid table name - " + tableName);
        }
        
        Set<String> allColumns = new HashSet<>();
        allColumns.addAll(updateValues.keySet());
        allColumns.addAll(whereCriteria.keySet());
        if (!SqlInjectionGuard.isValidColumns(dbName, tableName, allColumns)) {
            throw new SecurityException("Access Denied: Invalid update or target columns - " + allColumns);
        }

        // 2. Build the UPDATE SQL statement
        StringBuilder sql = new StringBuilder("UPDATE ");
        sql.append("`").append(dbName).append("`.`").append(tableName).append("` SET ");

        List<Object> params = new ArrayList<>();
        int index = 0;
        for (Map.Entry<String, Object> entry : updateValues.entrySet()) {
            if (index > 0) {
                sql.append(", ");
            }
            sql.append("`").append(entry.getKey()).append("` = ?");
            params.add(entry.getValue());
            index++;
        }

        if (!whereCriteria.isEmpty()) {
            sql.append(" WHERE ");
            index = 0;
            for (Map.Entry<String, Object> entry : whereCriteria.entrySet()) {
                if (index > 0) {
                    sql.append(" AND ");
                }
                sql.append("`").append(entry.getKey()).append("` = ?");
                params.add(entry.getValue());
                index++;
            }
        }

        // 3. Execute the update
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, normalizeParamValue(params.get(i)));
            }
            return ps.executeUpdate();
        }
    }

    /**
     * Fetches distinct values of a column, ordered.
     */
    public List<String> getDistinctColumnValues(String dbName, String tableName, String columnName) throws SQLException {
        if (!SqlInjectionGuard.isValidTable(dbName, tableName)) {
            throw new SecurityException("Access Denied: Invalid table name - " + tableName);
        }
        Set<String> cols = new HashSet<>();
        cols.add(columnName);
        if (!SqlInjectionGuard.isValidColumns(dbName, tableName, cols)) {
            throw new SecurityException("Access Denied: Invalid column name - " + columnName);
        }

        String sql = "SELECT DISTINCT `" + columnName + "` FROM `" + dbName + "`.`" + tableName + "` " +
                     "WHERE `" + columnName + "` IS NOT NULL " +
                     "ORDER BY `" + columnName + "`";
        List<String> values = new ArrayList<>();
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            while (rs.next()) {
                Object val = rs.getObject(1);
                if (val != null && !val.toString().trim().isEmpty()) {
                    values.add(val.toString());
                }
            }
        }
        return values;
    }

    /**
     * Resolves the primary key column name dynamically using JDBC DatabaseMetaData.
     */
    public String getPrimaryKeyColumn(String dbName, String tableName) throws SQLException {
        try (Connection conn = DBConnectionUtil.getConnection()) {
            DatabaseMetaData metaData = conn.getMetaData();
            try (ResultSet rs = metaData.getPrimaryKeys(dbName, null, tableName)) {
                if (rs.next()) {
                    return rs.getString("COLUMN_NAME");
                }
            }
        }
        // Fallback default
        return "id";
    }

    /**
     * Checks if a record exists in the table matching the primary key column and value.
     */
    public boolean recordExists(String dbName, String tableName, String pkColumn, Object pkValue) throws SQLException {
        if (!SqlInjectionGuard.isValidTable(dbName, tableName)) {
            throw new SecurityException("Access Denied: Invalid table name - " + tableName);
        }
        Set<String> cols = new HashSet<>();
        cols.add(pkColumn);
        if (!SqlInjectionGuard.isValidColumns(dbName, tableName, cols)) {
            throw new SecurityException("Access Denied: Invalid column name - " + pkColumn);
        }

        String sql = "SELECT COUNT(*) FROM `" + dbName + "`.`" + tableName + "` WHERE `" + pkColumn + "` = ?";
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql)) {
            ps.setObject(1, normalizeParamValue(pkValue));
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    return rs.getInt(1) > 0;
                }
            }
        }
        return false;
    }

    /**
     * Executes an UPDATE query targeting a single record matching the primary key column and value.
     */
    public int updateRecordByPrimaryKey(String dbName, String tableName, String pkColumn, Object pkValue, Map<String, Object> updateValues) throws SQLException {
        if (updateValues.isEmpty()) {
            return 0;
        }
        if (!SqlInjectionGuard.isValidTable(dbName, tableName)) {
            throw new SecurityException("Access Denied: Invalid table name - " + tableName);
        }
        Set<String> cols = new HashSet<>();
        cols.addAll(updateValues.keySet());
        cols.add(pkColumn);
        if (!SqlInjectionGuard.isValidColumns(dbName, tableName, cols)) {
            throw new SecurityException("Access Denied: Invalid columns - " + cols);
        }

        StringBuilder sql = new StringBuilder("UPDATE `").append(dbName).append("`.`").append(tableName).append("` SET ");
        List<Object> params = new ArrayList<>();
        int index = 0;
        for (Map.Entry<String, Object> entry : updateValues.entrySet()) {
            if (index > 0) {
                sql.append(", ");
            }
            sql.append("`").append(entry.getKey()).append("` = ?");
            params.add(entry.getValue());
            index++;
        }
        sql.append(" WHERE `").append(pkColumn).append("` = ?");
        params.add(pkValue);

        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql.toString())) {
            for (int i = 0; i < params.size(); i++) {
                ps.setObject(i + 1, normalizeParamValue(params.get(i)));
            }
            return ps.executeUpdate();
        }
    }

    private static Object normalizeParamValue(Object val) {
        if (val instanceof String) {
            String str = (String) val;
            if (str.matches("^\\d{4}-\\d{2}-\\d{2} \\d{2}:\\d{2}:\\d{2}(\\.\\d+)?$")) {
                try {
                    return java.sql.Timestamp.valueOf(str);
                } catch (Exception e) {
                    // Ignore and keep as string
                }
            }
        }
        return val;
    }
}
