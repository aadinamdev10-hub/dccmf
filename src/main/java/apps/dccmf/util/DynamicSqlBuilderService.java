package apps.dccmf.util;

import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Service orchestrating dynamic SQL queries, linking validation, and auditing.
 */
public class DynamicSqlBuilderService {
    private final LinkService linkService = new LinkService();
    private final ConfigService configService = new ConfigService();
    private final DynamicQueryDAO dynamicQueryDAO = new DynamicQueryDAO();

    /**
     * Executes a dynamic SELECT search on the database using searchKeys.
     * @param token Shareable link token.
     * @param criteria User search input map.
     * @param ipAddress Client IP address.
     * @return List of matching records.
     */
    public SearchResult search(String token, Map<String, Object> criteria, String ipAddress) throws SQLException {
        // 1. Resolve and validate link token
        LinkEntity link = linkService.getLinkByToken(token);
        if (link == null) {
            throw new IllegalArgumentException("Invalid token provided.");
        }
        if (!link.isActive()) {
            throw new IllegalStateException("This link is no longer active, has been disabled, or has expired.");
        }

        // 2. Resolve table configuration
        TableConfig config = configService.getConfigById(link.configId());
        if (config == null) {
            throw new IllegalStateException("Table configuration not found for the link.");
        }

        // 3. Extract and filter search keys
        Map<String, Object> searchCriteria = new HashMap<>();
        for (ColumnConfig col : config.columns()) {
            if (col.searchKey() && col.isVisible() && criteria.containsKey(col.name())) {
                Object val = criteria.get(col.name());
                if (val != null && !val.toString().trim().isEmpty()) {
                    searchCriteria.put(col.name(), val);
                }
            }
        }

        boolean serverSide = config.serverSidePaging() != null && config.serverSidePaging();
        
        List<Map<String, Object>> results;
        long totalCount;
        int currentPage = 1;
        int pageSize;

        if (serverSide) {
            pageSize = config.serverSidePageSize() != null ? config.serverSidePageSize() : 1000;
            if (criteria.containsKey("page")) {
                try {
                    Object pageVal = criteria.get("page");
                    if (pageVal instanceof Number) {
                        currentPage = ((Number) pageVal).intValue();
                    } else {
                        currentPage = (int) Double.parseDouble(pageVal.toString());
                    }
                    if (currentPage < 1) currentPage = 1;
                } catch (Exception e) {
                    // Ignore, fallback to 1
                }
            }
            int offset = (currentPage - 1) * pageSize;
            
            // Get count first
            totalCount = dynamicQueryDAO.countRecords(config.database(), config.table(), searchCriteria);
            
            // Fetch the paginated chunk
            results = dynamicQueryDAO.searchRecords(
                config.database(), 
                config.table(), 
                searchCriteria,
                pageSize,
                offset
            );
        } else {
            // Fetch all records
            results = dynamicQueryDAO.searchRecords(
                config.database(), 
                config.table(), 
                searchCriteria
            );
            totalCount = results.size();
            pageSize = results.size();
        }

        return new SearchResult(results, totalCount, currentPage, pageSize);
    }

    /**
     * Executes a dynamic UPDATE statement on the database using editable columns and search keys.
     * @param token Shareable link token.
     * @param submittedData All request parameters submitted by the client.
     * @param ipAddress Client IP address.
     * @return Number of updated rows.
     */
    /**
     * Reusable validation helper matching single-record form validation logic.
     */
    public void validateFieldValue(ColumnConfig col, Object val) {
        String valStr = val != null ? val.toString().trim() : "";

        // Required Validation
        if (col.required() && valStr.isEmpty()) {
            throw new IllegalArgumentException("Field '" + col.name() + "' is required and cannot be empty.");
        }

        // Data Type & Regex Validations
        if (!valStr.isEmpty()) {
            String vType = col.validation();
            if ("Numeric".equalsIgnoreCase(vType)) {
                if (!valStr.matches("^-?\\d+(\\.\\d+)?$")) {
                    throw new IllegalArgumentException("Field '" + col.name() + "' must be a numeric value.");
                }
            } else if ("Email".equalsIgnoreCase(vType)) {
                if (!valStr.matches("^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$")) {
                    throw new IllegalArgumentException("Field '" + col.name() + "' must be a valid email address.");
                }
            } else if ("Date".equalsIgnoreCase(vType)) {
                // DateBox matches YYYY-MM-DD
                if (!valStr.matches("^\\d{4}-\\d{2}-\\d{2}$")) {
                    throw new IllegalArgumentException("Field '" + col.name() + "' must be a valid date format (YYYY-MM-DD).");
                }
            } else if ("Regex".equalsIgnoreCase(vType) && col.regex() != null && !col.regex().trim().isEmpty()) {
                try {
                    if (!valStr.matches(col.regex())) {
                        throw new IllegalArgumentException("Field '" + col.name() + "' does not match required custom format.");
                    }
                } catch (Exception e) {
                    throw new IllegalArgumentException("Invalid custom validation regex expression: " + col.regex());
                }
            } else if ("Range".equalsIgnoreCase(vType)) {
                if (!valStr.matches("^-?\\d+(\\.\\d+)?$")) {
                    throw new IllegalArgumentException("Field '" + col.name() + "' must be a numeric value for range checks.");
                }
                double parsed = Double.parseDouble(valStr);
                if (col.min() != null && parsed < col.min()) {
                    throw new IllegalArgumentException("Field '" + col.name() + "' must be at least " + col.min() + ".");
                }
                if (col.max() != null && parsed > col.max()) {
                    throw new IllegalArgumentException("Field '" + col.name() + "' must be at most " + col.max() + ".");
                }
            }
        }

        // Dropdown option database validation
        if ("Dropdown".equalsIgnoreCase(col.uiType()) && col.apiSource() != null && !col.apiSource().trim().isEmpty() && !valStr.isEmpty()) {
            String apiSource = col.apiSource().trim();
            String lookupName = apiSource;
            if (apiSource.startsWith("/api/lookup/")) {
                lookupName = apiSource.substring("/api/lookup/".length());
            } else if (apiSource.contains("/")) {
                lookupName = apiSource.substring(apiSource.lastIndexOf("/") + 1);
            }
            try {
                boolean isValid = new apps.dccmf.util.LookupDAO().isValidLookupCode(lookupName, valStr);
                if (!isValid) {
                    throw new IllegalArgumentException("Field '" + col.name() + "' has an invalid option: " + valStr);
                }
            } catch (SQLException e) {
                System.err.println("Lookup validation failed: " + e.getMessage());
                throw new IllegalArgumentException("Field '" + col.name() + "' verification failed due to database connection error.");
            }
        }
    }

    public int update(String token, Map<String, Object> submittedData, String ipAddress) throws SQLException {
        // 1. Resolve and validate link token
        LinkEntity link = linkService.getLinkByToken(token);
        if (link == null) {
            throw new IllegalArgumentException("Invalid token provided.");
        }
        if (!link.isActive()) {
            throw new IllegalStateException("This link is no longer active, has been disabled, or has expired.");
        }

        // 2. Resolve table configuration
        TableConfig config = configService.getConfigById(link.configId());
        if (config == null) {
            throw new IllegalStateException("Table configuration not found for the link.");
        }

        // 3. Separate input data into whitelisted editable columns and search key criteria (WHERE parameters)
        Map<String, Object> updateValues = new HashMap<>();
        Map<String, Object> whereCriteria = new HashMap<>();

        for (ColumnConfig col : config.columns()) {
            // If the column is configured as a searchKey, use it for locating the record (WHERE clause)
            if (col.searchKey()) {
                Object val = submittedData.get(col.name());
                if (val != null && !val.toString().trim().isEmpty()) {
                    whereCriteria.put(col.name(), val);
                }
            }
            
            // If column is configured as editable and visible, and is provided in the update payload, validate and add it
            if (col.editable() && col.isVisible() && submittedData.containsKey(col.name())) {
                Object val = submittedData.get(col.name());
                validateFieldValue(col, val);
                updateValues.put(col.name(), val);
            }
        }

        // Auto-detect and override WHERE criteria with the primary key if provided
        try {
            String pkColumn = dynamicQueryDAO.getPrimaryKeyColumn(config.database(), config.table());
            if (pkColumn != null && submittedData.containsKey(pkColumn)) {
                Object pkVal = submittedData.get(pkColumn);
                if (pkVal != null && !pkVal.toString().trim().isEmpty()) {
                    whereCriteria.clear(); // clear other search keys to prevent value mismatches
                    whereCriteria.put(pkColumn, pkVal);
                }
            }
        } catch (Exception e) {
            // Fall back to configured search keys
        }

        if (whereCriteria.isEmpty()) {
            throw new IllegalArgumentException("Key columns (search keys) must be provided to perform an update.");
        }
        if (updateValues.isEmpty()) {
            throw new IllegalArgumentException("No editable field values were provided to update.");
        }

        // 4. Execute dynamic update
        int rowsUpdated = dynamicQueryDAO.updateRecord(
            config.database(), 
            config.table(), 
            updateValues, 
            whereCriteria
        );



        return rowsUpdated;
    }

    /**
     * Executes bulk updates on rows parsed from CSV.
     */
    public Map<String, Object> bulkUpdate(String token, List<Map<String, Object>> rows, String ipAddress) throws SQLException {
        LinkEntity link = linkService.getLinkByToken(token);
        if (link == null) {
            throw new IllegalArgumentException("Invalid token provided.");
        }
        if (!link.isActive()) {
            throw new IllegalStateException("This link is no longer active.");
        }

        TableConfig config = configService.getConfigById(link.configId());
        if (config == null) {
            throw new IllegalStateException("Table configuration not found for the link.");
        }

        String dbName = config.database();
        String tableName = config.table();

        // Dynamically find primary key column
        String pkColumn = dynamicQueryDAO.getPrimaryKeyColumn(dbName, tableName);

        int successCount = 0;
        int failCount = 0;
        List<String> errorMessages = new java.util.ArrayList<>();
        java.util.Set<String> warnings = new java.util.LinkedHashSet<>();

        for (Map<String, Object> row : rows) {
            Object rowIndexObj = row.get("rowIndex");
            int rowIndex = rowIndexObj != null ? ((Number) rowIndexObj).intValue() : 0;

            @SuppressWarnings("unchecked")
            Map<String, Object> rowData = (Map<String, Object>) row.get("data");
            if (rowData == null) {
                failCount++;
                errorMessages.add("Row " + rowIndex + ": Missing row data.");
                continue;
            }

            // Case-insensitive key lookup for primary key
            Object pkValue = null;
            for (String key : rowData.keySet()) {
                if (key.equalsIgnoreCase(pkColumn)) {
                    pkValue = rowData.get(key);
                    break;
                }
            }

            if (pkValue == null || pkValue.toString().trim().isEmpty()) {
                failCount++;
                errorMessages.add("Row " + rowIndex + ": Primary key column '" + pkColumn + "' is missing or empty.");
                continue;
            }

            String pkValStr = pkValue.toString().trim();

            try {
                // Check if the record exists
                boolean exists = dynamicQueryDAO.recordExists(dbName, tableName, pkColumn, pkValStr);
                if (!exists) {
                    failCount++;
                    errorMessages.add("Row " + rowIndex + " (id=" + pkValStr + "): " + pkColumn + " not found.");
                    continue;
                }

                // Filter editable and visible fields from rowData
                Map<String, Object> updateValues = new HashMap<>();
                for (ColumnConfig col : config.columns()) {
                    if (col.editable() && col.isVisible()) {
                        String matchedKey = null;
                        for (String key : rowData.keySet()) {
                            if (key.equalsIgnoreCase(col.name())) {
                                matchedKey = key;
                                break;
                            }
                        }

                        if (matchedKey != null) {
                            Object val = rowData.get(matchedKey);
                            if ("FileUpload".equalsIgnoreCase(col.uiType())) {
                                warnings.add("Column '" + col.name() + "' has UI Type 'FileUpload'. Changes to this field were skipped. File uploads must be done individually.");
                                continue;
                            }
                            validateFieldValue(col, val);
                            updateValues.put(col.name(), val);
                        }
                    }
                }

                if (updateValues.isEmpty()) {
                    // No editable columns provided, row is considered successfully processed (no-op)
                    successCount++;
                    continue;
                }

                int updated = dynamicQueryDAO.updateRecordByPrimaryKey(dbName, tableName, pkColumn, pkValStr, updateValues);
                if (updated > 0) {
                    successCount++;
                } else {
                    failCount++;
                    errorMessages.add("Row " + rowIndex + " (id=" + pkValStr + "): Database update failed.");
                }

            } catch (Exception e) {
                failCount++;
                errorMessages.add("Row " + rowIndex + " (id=" + pkValStr + "): " + e.getMessage());
            }
        }



        Map<String, Object> result = new HashMap<>();
        result.put("success", true);
        result.put("successCount", successCount);
        result.put("failCount", failCount);
        result.put("errors", errorMessages);
        result.put("warnings", new java.util.ArrayList<>(warnings));
        return result;
    }

    /**
     * Fetches distinct values for a search key column.
     */
    public List<String> getDistinctValues(String token, String columnName) throws SQLException {
        LinkEntity link = linkService.getLinkByToken(token);
        if (link == null || !link.isActive()) {
            throw new IllegalArgumentException("Invalid or inactive token link.");
        }

        TableConfig config = configService.getConfigById(link.configId());
        if (config == null) {
            throw new IllegalStateException("Table configuration not found.");
        }

        boolean isSearchKey = false;
        for (ColumnConfig col : config.columns()) {
            if (col.name().equalsIgnoreCase(columnName) && col.searchKey()) {
                isSearchKey = true;
                break;
            }
        }
        if (!isSearchKey) {
            throw new IllegalArgumentException("Column is not configured as a search key.");
        }

        return dynamicQueryDAO.getDistinctColumnValues(config.database(), config.table(), columnName);
    }
}
