package apps.dccmf.util;

import java.sql.*;
import java.util.*;

/**
 * DAO for fetching options from dynamic lookup queries.
 */
public class LookupDAO {
    
    // Mapping of lookup names to database queries
    private static final Map<String, String> LOOKUP_QUERIES = new HashMap<>();
    
    static {
        LOOKUP_QUERIES.put("statusList", "SELECT 'ACTIVE' AS code, 'Active' AS value UNION SELECT 'INACTIVE', 'Inactive'");
    }
    
    public List<Map<String, String>> getLookupData(String lookupName) throws SQLException {
        if (lookupName != null && (lookupName.startsWith("generic?t=") || lookupName.startsWith("generic/"))) {
            String encryptedToken = null;
            if (lookupName.contains("t=")) {
                encryptedToken = lookupName.substring(lookupName.indexOf("t=") + 2);
                if (encryptedToken.contains("&")) {
                    encryptedToken = encryptedToken.substring(0, encryptedToken.indexOf("&"));
                }
            }
            if (encryptedToken != null && !encryptedToken.trim().isEmpty()) {
                try {
                    String decrypted = EncryptionUtil.decrypt(encryptedToken);
                    String[] parts = decrypted.split(":");
                    
                    String dbName = null;
                    String tableName = null;
                    String keyCol = null;
                    String valCol = null;
                    boolean valid = false;

                    if (parts.length == 2) {
                        dbName = parts[0];
                        tableName = parts[1];
                        keyCol = "code";
                        valCol = "value";
                        valid = true;
                    } else if (parts.length == 4) {
                        dbName = parts[0];
                        tableName = parts[1];
                        keyCol = parts[2];
                        valCol = parts[3];
                        valid = true;
                    }

                    if (valid) {
                        String identRegex = "^[a-zA-Z0-9_]+$";
                        if (dbName.matches(identRegex) && tableName.matches(identRegex) &&
                            keyCol.matches(identRegex) && valCol.matches(identRegex)) {
                            
                            List<Map<String, String>> results = new ArrayList<>();
                            String sql = "SELECT `" + keyCol + "`, `" + valCol + "` FROM `" + dbName + "`.`" + tableName + "`";
                            try (Connection conn = DBConnectionUtil.getConnection();
                                 Statement stmt = conn.createStatement();
                                 ResultSet rs = stmt.executeQuery(sql)) {
                                
                                while (rs.next()) {
                                    Map<String, String> row = new LinkedHashMap<>();
                                    row.put("code", rs.getString(1));
                                    row.put("value", rs.getString(2));
                                    results.add(row);
                                }
                            }
                            return results;
                        }
                    }
                } catch (Exception e) {
                    throw new SQLException("Failed to decrypt or run generic lookup validation: " + e.getMessage(), e);
                }
            }
        }

        if ("deptList".equalsIgnoreCase(lookupName)) {
            try {
                return apps.dccmf.util.DepartmentLookupService.getInstance().getDepartments(false);
            } catch (Exception e) {
                throw new SQLException("Failed to retrieve departments from external API: " + e.getMessage(), e);
            }
        }

        String sql = LOOKUP_QUERIES.get(lookupName);
        if (sql == null) {
            return null;
        }
        
        List<Map<String, String>> results = new ArrayList<>();
        try (Connection conn = DBConnectionUtil.getConnection();
             PreparedStatement ps = conn.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {
            
            while (rs.next()) {
                Map<String, String> row = new LinkedHashMap<>();
                row.put("code", rs.getString("code"));
                row.put("value", rs.getString("value"));
                results.add(row);
            }
        }
        return results;
    }
    
    public boolean isValidLookupCode(String lookupName, String code) throws SQLException {
        List<Map<String, String>> data = getLookupData(lookupName);
        if (data == null) {
            return false;
        }
        for (Map<String, String> item : data) {
            if (item.get("code") != null && item.get("code").equalsIgnoreCase(code)) {
                return true;
            }
            if (item.get("value") != null && item.get("value").equalsIgnoreCase(code)) {
                return true;
            }
        }
        return false;
    }
}
