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
import java.util.Map;

/**
 * AJAX API Endpoint to update record values based on dynamic configuration permissions.
 */
@WebServlet("/apps/dccmf/user/api/update")
public class UpdateRecordServlet extends HttpServlet {
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

        // Read JSON updated values from request body
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
        Map<String, Object> submittedData = new HashMap<>();
        if (!jsonPayload.trim().isEmpty()) {
            try {
                @SuppressWarnings("unchecked")
                Map<String, Object> parsed = JsonUtil.fromJson(jsonPayload, Map.class);
                if (parsed != null) {
                    submittedData = parsed;
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
            int rowsUpdated = sqlBuilderService.update(token, submittedData, ipAddress);
            if (rowsUpdated > 0) {
                jsonResponse.put("success", true);
                jsonResponse.put("rowsUpdated", rowsUpdated);
                jsonResponse.put("message", "Record successfully updated.");
            } else {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                jsonResponse.put("success", false);
                jsonResponse.put("message", "No records matched the key criteria to update.");
            }
        } catch (IllegalArgumentException | IllegalStateException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", e.getMessage());
        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Database update execution failed: " + e.getMessage());
            e.printStackTrace();
        }

        response.getWriter().write(JsonUtil.toJson(jsonResponse));
    }
}
