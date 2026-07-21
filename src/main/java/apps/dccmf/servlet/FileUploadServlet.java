package apps.dccmf.servlet;

import apps.dccmf.util.LinkEntity;
import apps.dccmf.util.LinkService;
import apps.dccmf.util.JsonUtil;
import apps.dccmf.util.ConfigService;
import apps.dccmf.util.TableConfig;
import apps.dccmf.util.ColumnConfig;

import javax.servlet.ServletException;
import javax.servlet.annotation.MultipartConfig;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.Part;
import java.io.File;
import java.io.IOException;
import java.nio.file.Paths;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

/**
 * Endpoint for handling file uploads for columns configured with the FileUpload UI type.
 */
@WebServlet("/apps/dccmf/user/api/upload")
@MultipartConfig(
    fileSizeThreshold = 1024 * 1024 * 2,  // 2 MB
    maxFileSize = 1024 * 1024 * 10,       // 10 MB
    maxRequestSize = 1024 * 1024 * 50     // 50 MB
)
public class FileUploadServlet extends HttpServlet {
    private final LinkService linkService = new LinkService();    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String token = request.getParameter("token");
        String column = request.getParameter("column");
        Map<String, Object> jsonResponse = new HashMap<>();

        // 1. Verify link authorization
        if (token == null || token.trim().isEmpty()) {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Parameter 'token' is required.");
            response.getWriter().write(JsonUtil.toJson(jsonResponse));
            return;
        }

        LinkEntity link = null;
        try {
            link = linkService.getLinkByToken(token);
            if (link == null || !link.isActive()) {
                response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Invalid or inactive token link.");
                response.getWriter().write(JsonUtil.toJson(jsonResponse));
                return;
            }
        } catch (SQLException e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Database error: " + e.getMessage());
            response.getWriter().write(JsonUtil.toJson(jsonResponse));
            return;
        }

        // 2. Process file part
        try {
            Part filePart = request.getPart("file");
            if (filePart == null || filePart.getSize() == 0) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                jsonResponse.put("success", false);
                jsonResponse.put("message", "No file found in the request or file is empty.");
                response.getWriter().write(JsonUtil.toJson(jsonResponse));
                return;
            }

            // Perform dynamic file upload constraints validation on the server side
            if (column != null && !column.trim().isEmpty()) {
                try {
                    ConfigService configService = new ConfigService();
                    TableConfig config = configService.getConfigById(link.configId());
                    if (config != null) {
                        ColumnConfig colConfig = null;
                        for (ColumnConfig c : config.columns()) {
                            if (c.name().equalsIgnoreCase(column)) {
                                colConfig = c;
                                break;
                            }
                        }
                        if (colConfig != null) {
                            // Validate Size
                            int maxSizeMb = colConfig.maxSizeMb() != null ? colConfig.maxSizeMb() : 5;
                            long maxSizeBytes = maxSizeMb * 1024L * 1024L;
                            if (filePart.getSize() > maxSizeBytes) {
                                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                                jsonResponse.put("success", false);
                                jsonResponse.put("message", "File size exceeds the allowed limit of " + maxSizeMb + " MB.");
                                response.getWriter().write(JsonUtil.toJson(jsonResponse));
                                return;
                            }

                            // Validate Extension
                            String allowedExtensions = colConfig.allowedExtensions();
                            if (allowedExtensions != null && !allowedExtensions.trim().isEmpty()) {
                                String submittedFileName = filePart.getSubmittedFileName();
                                String ext = "";
                                if (submittedFileName != null) {
                                    int dotIndex = submittedFileName.lastIndexOf('.');
                                    if (dotIndex >= 0) {
                                        ext = submittedFileName.substring(dotIndex + 1).toLowerCase();
                                    }
                                }
                                String[] allowedList = allowedExtensions.split(",");
                                boolean isAllowed = false;
                                for (String allowed : allowedList) {
                                    if (allowed.trim().equalsIgnoreCase(ext)) {
                                        isAllowed = true;
                                        break;
                                    }
                                }
                                if (!isAllowed) {
                                    response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                                    jsonResponse.put("success", false);
                                    jsonResponse.put("message", "Invalid file type. Allowed formats: " + allowedExtensions.toUpperCase());
                                    response.getWriter().write(JsonUtil.toJson(jsonResponse));
                                    return;
                                }
                            }
                        }
                    }
                } catch (Exception e) {
                    System.err.println("Warning: failed server-side file validation: " + e.getMessage());
                }
            }

            String submittedFileName = filePart.getSubmittedFileName();
            if (submittedFileName == null || submittedFileName.trim().isEmpty()) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Unable to resolve filename.");
                response.getWriter().write(JsonUtil.toJson(jsonResponse));
                return;
            }

            String fileName = Paths.get(submittedFileName).getFileName().toString();

            // 3. Define upload path under web application context
            String uploadPath = getServletContext().getRealPath("/uploads");
            File uploadDir = new File(uploadPath);
            if (!uploadDir.exists()) {
                uploadDir.mkdirs();
            }

            // Create unique filename to prevent overwrites
            String uniqueFileName = System.currentTimeMillis() + "_" + fileName;
            String fullPath = uploadPath + File.separator + uniqueFileName;
            
            // Save file to disk
            filePart.write(fullPath);

            jsonResponse.put("success", true);
            jsonResponse.put("filePath", "/uploads/" + uniqueFileName);
            jsonResponse.put("message", "File uploaded successfully.");
        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "File upload failed: " + e.getMessage());
            e.printStackTrace();
        }

        response.getWriter().write(JsonUtil.toJson(jsonResponse));
    }
}
