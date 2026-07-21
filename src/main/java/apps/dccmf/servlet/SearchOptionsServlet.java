package apps.dccmf.servlet;

import apps.dccmf.util.DynamicSqlBuilderService;
import apps.dccmf.util.JsonUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

/**
 * Endpoint for fetching unique column values to populate search key dropdowns.
 */
@WebServlet("/apps/dccmf/user/api/searchOptions")
public class SearchOptionsServlet extends HttpServlet {
    private final DynamicSqlBuilderService sqlBuilderService = new DynamicSqlBuilderService();

    @Override
    protected void doGet(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String token = request.getParameter("token");
        String column = request.getParameter("column");
        Map<String, Object> jsonResponse = new HashMap<>();

        if (token == null || token.trim().isEmpty() || column == null || column.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Parameters 'token' and 'column' are required.");
            response.getWriter().write(JsonUtil.toJson(jsonResponse));
            return;
        }

        try {
            List<String> values = sqlBuilderService.getDistinctValues(token, column);
            List<Map<String, String>> options = new ArrayList<>();
            for (String val : values) {
                Map<String, String> option = new HashMap<>();
                option.put("value", val);
                option.put("label", val);
                options.add(option);
            }
            // Return raw options list directly
            response.getWriter().write(JsonUtil.toJson(options));
        } catch (IllegalArgumentException | IllegalStateException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", e.getMessage());
            response.getWriter().write(JsonUtil.toJson(jsonResponse));
        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Database error: " + e.getMessage());
            response.getWriter().write(JsonUtil.toJson(jsonResponse));
            e.printStackTrace();
        }
    }
}
