package apps.dccmf.util;

import java.sql.SQLException;
import java.util.List;

/**
 * Service class handling configuration logic and DB metadata queries.
 */
public class ConfigService {
    private final ConfigDAO configDAO = new ConfigDAO();

    public List<String> getDatabases() throws SQLException {
        return configDAO.getDatabases();
    }

    public List<String> getTables(String dbName) throws SQLException {
        return configDAO.getTables(dbName);
    }

    public List<ColumnConfig> getTableColumns(String dbName, String tableName) throws SQLException {
        return configDAO.getTableColumns(dbName, tableName);
    }

    public int saveConfig(TableConfig config, String createdBy) throws SQLException {
        return saveConfig(config, null, createdBy);
    }

    public int saveConfig(TableConfig config, Integer editConfigId, String createdBy) throws SQLException {
        return configDAO.saveConfig(config, editConfigId, createdBy);
    }

    public TableConfig getConfigById(int configId) throws SQLException {
        return configDAO.getConfigById(configId);
    }

    public TableConfig getConfigByDbAndTable(String dbName, String tableName) throws SQLException {
        return configDAO.getConfigByDbAndTable(dbName, tableName);
    }
}
