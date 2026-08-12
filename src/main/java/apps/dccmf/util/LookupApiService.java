package apps.dccmf.util;

import java.sql.SQLException;
import java.util.List;

/**
 * Service class orchestrating lookup API registration operations.
 */
public class LookupApiService {
    private final LookupApiDAO lookupApiDAO = new LookupApiDAO();

    public void saveLookupApi(String apiLink) throws SQLException {
        lookupApiDAO.saveLookupApi(apiLink);
    }

    public List<LookupApiEntity> getAllLookupApis() throws SQLException {
        return lookupApiDAO.getAllLookupApis();
    }

    public void deleteLookupApi(int id) throws SQLException {
        lookupApiDAO.deleteLookupApi(id);
    }
}
