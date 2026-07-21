package apps.dccmf.servlet;

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
 * AJAX API Endpoint to fetch tables of a selected database.
 */
@WebServlet("/apps/dccmf/admin/api/tables")
public class FetchTablesServlet extends HttpServlet {
    private final ConfigService configService = new ConfigService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String db = request.getParameter("db");
        Map<String, Object> jsonResponse = new HashMap<>();

        if (db == null || db.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Database parameter 'db' is required.");
            response.getWriter().write(JsonUtil.toJson(jsonResponse));
            return;
        }

        try {
            List<String> tables = configService.getTables(db);
            jsonResponse.put("success", true);
            jsonResponse.put("tables", tables);
        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Database error: " + e.getMessage());
            e.printStackTrace();
        }

        response.getWriter().write(JsonUtil.toJson(jsonResponse));
    }
}
