package apps.dccmf.servlet;

import apps.dccmf.util.DynamicSqlBuilderService;
import apps.dccmf.util.JsonUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.BufferedReader;
import java.io.IOException;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Endpoint for bulk updating records via CSV upload.
 */
@WebServlet("/apps/dccmf/user/api/bulkUpdate")
public class BulkUpdateServlet extends HttpServlet {
    private final DynamicSqlBuilderService sqlBuilderService = new DynamicSqlBuilderService();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String token = request.getParameter("token");
        String ipAddress = request.getRemoteAddr();
        Map<String, Object> jsonResponse = new HashMap<>();

        if (token == null || token.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Parameter 'token' is required.");
            response.getWriter().write(JsonUtil.toJson(jsonResponse));
            return;
        }

        // Read JSON payload from request body
        StringBuilder jsonBuilder = new StringBuilder();
        try (BufferedReader reader = request.getReader()) {
            String line;
            while ((line = reader.readLine()) != null) {
                jsonBuilder.append(line);
            }
        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Error reading request body: " + e.getMessage());
            response.getWriter().write(JsonUtil.toJson(jsonResponse));
            return;
        }

        String jsonPayload = jsonBuilder.toString();
        List<Map<String, Object>> rows = null;
        if (!jsonPayload.trim().isEmpty()) {
            try {
                @SuppressWarnings("unchecked")
                Map<String, Object> parsed = JsonUtil.fromJson(jsonPayload, Map.class);
                if (parsed != null && parsed.containsKey("rows")) {
                    rows = (List<Map<String, Object>>) parsed.get("rows");
                }
            } catch (Exception e) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Malformed JSON payload: " + e.getMessage());
                response.getWriter().write(JsonUtil.toJson(jsonResponse));
                return;
            }
        }

        if (rows == null || rows.isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "No rows provided for bulk update.");
            response.getWriter().write(JsonUtil.toJson(jsonResponse));
            return;
        }

        try {
            Map<String, Object> bulkResult = sqlBuilderService.bulkUpdate(token, rows, ipAddress);
            response.getWriter().write(JsonUtil.toJson(bulkResult));
        } catch (IllegalArgumentException | IllegalStateException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", e.getMessage());
            response.getWriter().write(JsonUtil.toJson(jsonResponse));
        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Database update execution failed: " + e.getMessage());
            e.printStackTrace();
            response.getWriter().write(JsonUtil.toJson(jsonResponse));
        }
    }
}
