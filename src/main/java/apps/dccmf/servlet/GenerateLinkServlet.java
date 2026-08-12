package apps.dccmf.servlet;

import apps.dccmf.util.LinkService;
import apps.dccmf.util.JsonUtil;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import java.io.IOException;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

/**
 * AJAX API Endpoint to generate a shareable user link.
 */
@WebServlet("/apps/dccmf/admin/api/generateLink")
public class GenerateLinkServlet extends HttpServlet {
    private final LinkService linkService = new LinkService();

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        Map<String, Object> jsonResponse = new HashMap<>();
        String configIdStr = request.getParameter("configId");
        String expiryHoursStr = request.getParameter("expiryHours");

        if (configIdStr == null || configIdStr.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Parameter 'configId' is required.");
            response.getWriter().write(JsonUtil.toJson(jsonResponse));
            return;
        }

        try {
            int configId = Integer.parseInt(configIdStr);
            int expiryHours = 0;
            if (expiryHoursStr != null && !expiryHoursStr.trim().isEmpty()) {
                expiryHours = Integer.parseInt(expiryHoursStr);
            }

            String token = linkService.generateLink(configId, expiryHours);

            // Construct host dynamic URL
            String scheme = request.getScheme();
            String serverName = request.getServerName();
            int serverPort = request.getServerPort();
            String contextPath = "/apps";
            
            // Build absolute path
            String portPart = (("http".equals(scheme) && serverPort == 80) || ("https".equals(scheme) && serverPort == 443)) ? "" : ":" + serverPort;
            String shareableUrl = scheme + "://" + serverName + portPart + contextPath + "/apps/dccmf/user/userForm.jsp?token=" + token;

            jsonResponse.put("success", true);
            jsonResponse.put("token", token);
            jsonResponse.put("url", shareableUrl);
            jsonResponse.put("message", "Shareable link generated successfully.");
        } catch (NumberFormatException e) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Invalid format for numeric inputs.");
        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Database error: " + e.getMessage());
            e.printStackTrace();
        }

        response.getWriter().write(JsonUtil.toJson(jsonResponse));
    }
}
