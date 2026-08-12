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
 * AJAX API Endpoint for searching records dynamically based on search keys.
 */
@WebServlet("/apps/dccmf/user/api/search")
public class SearchRecordServlet extends HttpServlet {
    private final DynamicSqlBuilderService sqlBuilderService = new DynamicSqlBuilderService();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        // Set standard JSON response headers
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String token = request.getParameter("token");
        String ipAddress = request.getRemoteAddr(); // Retrieve request source IP for logging/auditing
        Map<String, Object> jsonResponse = new HashMap<>();

        // 1. Verify token is present in the request query parameters
        if (token == null || token.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Parameter 'token' is required.");
            response.getWriter().write(JsonUtil.toJson(jsonResponse));
            return;
        }

        // 2. Read the JSON-encoded search criteria sent in the POST request body
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
        Map<String, Object> criteria = new HashMap<>();
        if (!jsonPayload.trim().isEmpty()) {
            try {
                @SuppressWarnings("unchecked")
                Map<String, Object> parsed = JsonUtil.fromJson(jsonPayload, Map.class);
                if (parsed != null) {
                    criteria = parsed;
                }
            } catch (Exception e) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Malformed JSON payload: " + e.getMessage());
                response.getWriter().write(JsonUtil.toJson(jsonResponse));
                return;
            }
        }

        try {
            apps.dccmf.util.SearchResult result = sqlBuilderService.search(token, criteria, ipAddress);
            jsonResponse.put("success", true);
            jsonResponse.put("records", result.data());
            jsonResponse.put("data", result.data());
            jsonResponse.put("totalCount", result.totalCount());
            jsonResponse.put("page", result.page());
            jsonResponse.put("pageSize", result.pageSize());
        } catch (IllegalArgumentException | IllegalStateException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", e.getMessage());
        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Database query execution failed: " + e.getMessage());
            e.printStackTrace();
        }

        response.getWriter().write(JsonUtil.toJson(jsonResponse));
    }
}
