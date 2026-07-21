package apps.dccmf.servlet;

import apps.dccmf.util.TableConfig;
import apps.dccmf.util.ConfigService;
import apps.dccmf.util.JsonUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.BufferedReader;
import java.io.IOException;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

/**
 * AJAX API Endpoint to save table JSON configurations.
 */
@WebServlet("/apps/dccmf/admin/api/saveConfig")
public class SaveConfigServlet extends HttpServlet {
    private final ConfigService configService = new ConfigService();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        HttpSession session = request.getSession(false);
        String username = (session != null) ? (String) session.getAttribute("adminUser") : "system";

        Map<String, Object> jsonResponse = new HashMap<>();

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
        if (jsonPayload.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Empty request body payload.");
            response.getWriter().write(JsonUtil.toJson(jsonResponse));
            return;
        }

        try {
            TableConfig config = JsonUtil.fromJson(jsonPayload, TableConfig.class);
            
            // Basic validation
            if (config.database() == null || config.table() == null || config.columns() == null) {
                throw new IllegalArgumentException("Invalid configuration format. Missing fields.");
            }

            // Read optional configId parameter for edit mode
            String configIdParam = request.getParameter("configId");
            Integer editConfigId = null;
            if (configIdParam != null && !configIdParam.trim().isEmpty()) {
                try {
                    editConfigId = Integer.parseInt(configIdParam);
                } catch (NumberFormatException e) {
                    // Keep null if invalid format
                }
            }

            int configId = configService.saveConfig(config, editConfigId, username);
            
            jsonResponse.put("success", true);
            jsonResponse.put("configId", configId);
            jsonResponse.put("message", "Configuration successfully saved.");
        } catch (IllegalArgumentException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", e.getMessage());
        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Database error: " + e.getMessage());
            e.printStackTrace();
        }

        response.getWriter().write(JsonUtil.toJson(jsonResponse));
    }
}
