package apps.dccmf.util;

import java.io.IOException;
import java.io.InputStream;
import java.net.URI;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.net.http.HttpTimeoutException;
import java.time.Duration;
import java.util.*;

public class DepartmentLookupService {
    private static final DepartmentLookupService INSTANCE = new DepartmentLookupService();
    
    private final HttpClient httpClient;
    private String apiUrl;
    private String apiToken;
    private int timeoutMs;
    
    // In-memory cache
    private List<Map<String, String>> cachedData = null;
    private long cacheExpiry = 0;
    private static final long CACHE_TTL_MS = 5 * 60 * 1000L; // 5 minutes

    private DepartmentLookupService() {
        this.httpClient = HttpClient.newBuilder()
            .version(HttpClient.Version.HTTP_1_1)
            .build();
    }

    public static DepartmentLookupService getInstance() {
        return INSTANCE;
    }

    /**
     * Exception class representing failure from the external API lookup
     */
    public static class ExternalApiException extends Exception {
        private final int statusCode;
        
        public ExternalApiException(String message, int statusCode) {
            super(message);
            this.statusCode = statusCode;
        }
        
        public int getStatusCode() {
            return statusCode;
        }
    }

    private synchronized void loadConfig() {
        Properties props = new Properties();
        try (InputStream input = DepartmentLookupService.class.getClassLoader().getResourceAsStream("db.properties")) {
            if (input != null) {
                props.load(input);
            }
        } catch (Exception e) {
            System.err.println("Warning: failed to load db.properties: " + e.getMessage());
        }

        String urlEnv = System.getenv("EXTERNAL_API_DEPT_URL");
        this.apiUrl = (urlEnv != null && !urlEnv.trim().isEmpty()) ? urlEnv.trim() : props.getProperty("external.api.dept.url", "http://localhost:8080/dccmf/api/departments");

        String tokenEnv = System.getenv("EXTERNAL_API_DEPT_TOKEN");
        this.apiToken = (tokenEnv != null) ? tokenEnv : props.getProperty("external.api.dept.token", "Bearer dummy_token_value_12345");

        String timeoutEnv = System.getenv("EXTERNAL_API_TIMEOUT_MS");
        int parsedTimeout = 5000;
        if (timeoutEnv != null) {
            try {
                parsedTimeout = Integer.parseInt(timeoutEnv);
            } catch (NumberFormatException ignored) {}
        } else {
            String propTimeout = props.getProperty("external.api.timeout.ms");
            if (propTimeout != null) {
                try {
                    parsedTimeout = Integer.parseInt(propTimeout);
                } catch (NumberFormatException ignored) {}
            }
        }
        this.timeoutMs = parsedTimeout;
    }

    /**
     * Retrieve the list of departments, serving from cache if valid.
     */
    public synchronized List<Map<String, String>> getDepartments(boolean forceRefresh) throws ExternalApiException {
        long now = System.currentTimeMillis();
        if (!forceRefresh && cachedData != null && now < cacheExpiry) {
            return cachedData;
        }

        List<Map<String, String>> data = fetchFromExternalApi();
        cachedData = data;
        cacheExpiry = System.currentTimeMillis() + CACHE_TTL_MS;
        return cachedData;
    }

    private List<Map<String, String>> fetchFromExternalApi() throws ExternalApiException {
        loadConfig(); // dynamically reload settings

        try {
            HttpRequest.Builder reqBuilder = HttpRequest.newBuilder()
                .uri(URI.create(apiUrl))
                .header("Accept", "application/json")
                .timeout(Duration.ofMillis(timeoutMs));

            if (apiToken != null && !apiToken.trim().isEmpty()) {
                reqBuilder.header("Authorization", apiToken);
            }

            HttpRequest request = reqBuilder.build();
            HttpResponse<String> response = httpClient.send(request, HttpResponse.BodyHandlers.ofString());

            int status = response.statusCode();
            if (status != 200) {
                throw new ExternalApiException("External API returned HTTP " + status, 502);
            }

            String body = response.body();
            if (body == null || body.trim().isEmpty()) {
                throw new ExternalApiException("External API returned empty response body", 502);
            }

            java.lang.reflect.Type listType = new com.google.gson.reflect.TypeToken<List<ExternalDept>>(){}.getType();
            List<ExternalDept> externalList;
            try {
                externalList = JsonUtil.fromJson(body, listType);
            } catch (Exception e) {
                throw new ExternalApiException("Malformed JSON response from external API: " + e.getMessage(), 502);
            }

            if (externalList == null) {
                throw new ExternalApiException("Parsed external API response is null", 502);
            }

            return reshape(externalList);

        } catch (HttpTimeoutException e) {
            throw new ExternalApiException("External API request timed out: " + e.getMessage(), 504);
        } catch (IOException e) {
            throw new ExternalApiException("Network error connecting to external API: " + e.getMessage(), 502);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new ExternalApiException("External API call interrupted", 502);
        }
    }

    /**
     * Reshapes the response from external API contract to [{code, value}] contract.
     */
    private List<Map<String, String>> reshape(List<ExternalDept> externalList) {
        List<Map<String, String>> reshaped = new ArrayList<>();
        for (ExternalDept ext : externalList) {
            if (ext.getDeptId() != null && ext.getDeptName() != null) {
                Map<String, String> item = new LinkedHashMap<>();
                item.put("code", ext.getDeptId());
                item.put("value", ext.getDeptName());
                reshaped.add(item);
            }
        }
        return reshaped;
    }

    /**
     * DTO matching the external API's response schema: [{"deptId": "...", "deptName": "..."}]
     */
    private static class ExternalDept {
        private String deptId;
        private String deptName;

        public String getDeptId() { return deptId; }
        public void setDeptId(String deptId) { this.deptId = deptId; }
        public String getDeptName() { return deptName; }
        public void setDeptName(String deptName) { this.deptName = deptName; }
    }
}
