package apps.dccmf.servlet;

import apps.dccmf.util.LookupDAO;
import apps.dccmf.util.JsonUtil;
import apps.dccmf.util.DBConnectionUtil;
import apps.dccmf.util.EncryptionUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Endpoint serving dynamic dropdown options based on database lookup queries.
 * Returns a JSON array of objects, e.g., [{"code": "DEPT01", "value": "Finance"}].
 */
@WebServlet("/apps/dccmf/api/lookup/*")
public class LookupApiServlet extends HttpServlet {
    private final LookupDAO lookupDAO = new LookupDAO();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String pathInfo = request.getPathInfo();
        if (pathInfo == null || pathInfo.equals("/")) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            Map<String, String> err = new HashMap<>();
            err.put("error", "No lookup path specified. Try /deptList");
            response.getWriter().write(JsonUtil.toJson(err));
            return;
        }

        // Parse path parameter (e.g. /deptList -> deptList)
        String lookupName = pathInfo.substring(1);

        if ("generic".equalsIgnoreCase(lookupName)) {
            String t = request.getParameter("t");
            if (t == null || t.trim().isEmpty()) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                Map<String, String> err = new HashMap<>();
                err.put("error", "Encrypted lookup token parameter 't' is required.");
                response.getWriter().write(JsonUtil.toJson(err));
                return;
            }

            try {
                // Decrypt token
                String decrypted = EncryptionUtil.decrypt(t);
                String[] parts = decrypted.split(":");
                
                String dbName;
                String tableName;
                String keyCol;
                String valCol;

                if (parts.length == 2) {
                    dbName = parts[0];
                    tableName = parts[1];
                    keyCol = "code";
                    valCol = "value";
                } else if (parts.length == 4) {
                    dbName = parts[0];
                    tableName = parts[1];
                    keyCol = parts[2];
                    valCol = parts[3];
                } else {
                    response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    Map<String, String> err = new HashMap<>();
                    err.put("error", "Invalid lookup token format.");
                    response.getWriter().write(JsonUtil.toJson(err));
                    return;
                }

                // Validate SQL identifiers
                String identRegex = "^[a-zA-Z0-9_]+$";
                if (!dbName.matches(identRegex) || !tableName.matches(identRegex) ||
                    !keyCol.matches(identRegex) || !valCol.matches(identRegex)) {
                    response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    Map<String, String> err = new HashMap<>();
                    err.put("error", "Security validation failed: Invalid database, table, or column names.");
                    response.getWriter().write(JsonUtil.toJson(err));
                    return;
                }

                // Query and fetch options
                List<Map<String, String>> options = new ArrayList<>();
                String sql = "SELECT `" + keyCol + "`, `" + valCol + "` FROM `" + dbName + "`.`" + tableName + "`";

                try (Connection conn = DBConnectionUtil.getConnection();
                     Statement stmt = conn.createStatement();
                     ResultSet rs = stmt.executeQuery(sql)) {
                    
                    while (rs.next()) {
                        Map<String, String> option = new HashMap<>();
                        option.put("code", rs.getString(1));
                        option.put("value", rs.getString(2));
                        options.add(option);
                    }
                }

                response.getWriter().write(JsonUtil.toJson(options));
            } catch (Exception e) {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                Map<String, String> err = new HashMap<>();
                err.put("error", "Failed to retrieve lookup options: " + e.getMessage());
                response.getWriter().write(JsonUtil.toJson(err));
                e.printStackTrace();
            }
            return;
        }

        if ("deptList".equalsIgnoreCase(lookupName)) {
            try {
                List<Map<String, String>> data = apps.dccmf.util.DepartmentLookupService.getInstance().getDepartments(false);
                response.getWriter().write(JsonUtil.toJson(data));
            } catch (apps.dccmf.util.DepartmentLookupService.ExternalApiException e) {
                response.setStatus(e.getStatusCode());
                Map<String, String> err = new HashMap<>();
                err.put("error", e.getMessage());
                response.getWriter().write(JsonUtil.toJson(err));
            } catch (Exception e) {
                response.setStatus(HttpServletResponse.SC_BAD_GATEWAY);
                Map<String, String> err = new HashMap<>();
                err.put("error", "Failed to retrieve department list: " + e.getMessage());
                response.getWriter().write(JsonUtil.toJson(err));
            }
            return;
        }

        try {
            List<Map<String, String>> data = lookupDAO.getLookupData(lookupName);
            if (data == null) {
                response.setStatus(HttpServletResponse.SC_NOT_FOUND);
                Map<String, String> err = new HashMap<>();
                err.put("error", "Unknown lookup name: " + lookupName);
                response.getWriter().write(JsonUtil.toJson(err));
            } else {
                response.getWriter().write(JsonUtil.toJson(data));
            }
        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            Map<String, String> err = new HashMap<>();
            err.put("error", "Database failure: " + e.getMessage());
            response.getWriter().write(JsonUtil.toJson(err));
            e.printStackTrace();
        }
    }
}
