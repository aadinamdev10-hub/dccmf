package apps.dccmf.util;

import java.util.List;

/**
 * Entire table configurations.
 * Converted to standard POJO class for universal Gson compatibility (fixes "Cannot set final field" on older Gson versions).
 */
public class TableConfig {
    private String database;
    private String table;
    private List<ColumnConfig> columns;
    private String rowField;
    private String columnField;
    private Boolean clientSidePaging = false;
    private Integer clientSidePageSize = 200;
    private Boolean serverSidePaging = false;
    private Integer serverSidePageSize = 1000;

    // No-arg constructor for Gson
    public TableConfig() {
    }

    public TableConfig(String database, String table, List<ColumnConfig> columns, String rowField, String columnField) {
        this.database = database;
        this.table = table;
        this.columns = columns;
        this.rowField = rowField;
        this.columnField = columnField;
        this.clientSidePaging = false;
        this.clientSidePageSize = 200;
        this.serverSidePaging = false;
        this.serverSidePageSize = 1000;
    }

    public TableConfig(String database, String table, List<ColumnConfig> columns, String rowField, String columnField,
                       Boolean clientSidePaging, Integer clientSidePageSize, Boolean serverSidePaging, Integer serverSidePageSize) {
        this.database = database;
        this.table = table;
        this.columns = columns;
        this.rowField = rowField;
        this.columnField = columnField;
        this.clientSidePaging = clientSidePaging != null ? clientSidePaging : false;
        this.clientSidePageSize = clientSidePageSize != null ? clientSidePageSize : 200;
        this.serverSidePaging = serverSidePaging != null ? serverSidePaging : false;
        this.serverSidePageSize = serverSidePageSize != null ? serverSidePageSize : 1000;
    }

    // Accessors matching record style for backward compatibility
    public String database() { return database; }
    public String table() { return table; }
    public List<ColumnConfig> columns() { return columns; }
    public String rowField() { return rowField; }
    public String columnField() { return columnField; }
    public Boolean clientSidePaging() { return clientSidePaging != null ? clientSidePaging : false; }
    public Integer clientSidePageSize() { return clientSidePageSize != null ? clientSidePageSize : 200; }
    public Boolean serverSidePaging() { return serverSidePaging != null ? serverSidePaging : false; }
    public Integer serverSidePageSize() { return serverSidePageSize != null ? serverSidePageSize : 1000; }

    // Setters (if needed)
    public void setDatabase(String database) { this.database = database; }
    public void setTable(String table) { this.table = table; }
    public void setColumns(List<ColumnConfig> columns) { this.columns = columns; }
    public void setRowField(String rowField) { this.rowField = rowField; }
    public void setColumnField(String columnField) { this.columnField = columnField; }
    public void setClientSidePaging(Boolean clientSidePaging) { this.clientSidePaging = clientSidePaging; }
    public void setClientSidePageSize(Integer clientSidePageSize) { this.clientSidePageSize = clientSidePageSize; }
    public void setServerSidePaging(Boolean serverSidePaging) { this.serverSidePaging = serverSidePaging; }
    public void setServerSidePageSize(Integer serverSidePageSize) { this.serverSidePageSize = serverSidePageSize; }
}
