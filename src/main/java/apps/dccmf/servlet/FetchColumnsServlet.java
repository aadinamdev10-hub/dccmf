package apps.dccmf.servlet;

import apps.dccmf.util.ColumnConfig;
import apps.dccmf.util.TableConfig;
import apps.dccmf.util.ConfigService;
import apps.dccmf.util.JsonUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * AJAX API Endpoint to fetch the columns of a selected table,
 * merging with any existing configuration if found.
 */
@WebServlet("/apps/dccmf/admin/api/columns")
public class FetchColumnsServlet extends HttpServlet {
    private final ConfigService configService = new ConfigService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String db = request.getParameter("db");
        String table = request.getParameter("table");
        Map<String, Object> jsonResponse = new HashMap<>();

        if (db == null || db.trim().isEmpty() || table == null || table.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Database ('db') and Table ('table') parameters are required.");
            response.getWriter().write(JsonUtil.toJson(jsonResponse));
            return;
        }

        try {
            // Check if config already exists
            TableConfig existingConfig = configService.getConfigByDbAndTable(db, table);
            
            if (existingConfig != null) {
                jsonResponse.put("success", true);
                jsonResponse.put("isNew", false);
                jsonResponse.put("config", existingConfig);
            } else {
                // Fetch fresh metadata columns
                List<ColumnConfig> columns = configService.getTableColumns(db, table);
                TableConfig newConfig = new TableConfig(db, table, columns, "", "");
                jsonResponse.put("success", true);
                jsonResponse.put("isNew", true);
                jsonResponse.put("config", newConfig);
            }
        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Database error: " + e.getMessage());
            e.printStackTrace();
        }

        response.getWriter().write(JsonUtil.toJson(jsonResponse));
    }
}
