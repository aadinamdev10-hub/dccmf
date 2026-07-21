<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="apps.dccmf.util.ConfigService" %>
<%@ page import="apps.dccmf.util.EncryptionUtil" %>
<%@ page import="apps.dccmf.util.JsonUtil" %>
<%@ page import="apps.dccmf.util.LookupApiService" %>
<%@ page import="apps.dccmf.util.LookupApiEntity" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%
    // =========================================================================
    // DCCMF ADMIN DROPDOWN LOOKUP API GENERATOR
    // File: /apps/dccmf/admin/generateApi.jsp
    // Description: Admin page to package lookup tables (code/value maps) into
    //              secure, encrypted API tokens for options dropdowns.
    // =========================================================================

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");

        String action = request.getParameter("action");
        Map<String, Object> jsonResponse = new HashMap<>();

        // Handle delete request
        if ("delete".equalsIgnoreCase(action)) {
            String idStr = request.getParameter("id");
            if (idStr != null && !idStr.trim().isEmpty()) {
                try {
                    int id = Integer.parseInt(idStr);
                    new LookupApiService().deleteLookupApi(id);
                    jsonResponse.put("success", true);
                    jsonResponse.put("message", "Lookup API deleted successfully.");
                } catch (Exception e) {
                    response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                    jsonResponse.put("success", false);
                    jsonResponse.put("message", "Error deleting API: " + e.getMessage());
                }
            } else {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Parameter 'id' is required for deletion.");
            }
            out.write(JsonUtil.toJson(jsonResponse));
            return;
        }

        // Handle API Token Generation Request
        String db = request.getParameter("db");
        String table = request.getParameter("table");

        if (db == null || db.trim().isEmpty() ||
            table == null || table.trim().isEmpty()) {
            
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Database and Table fields are required.");
            out.write(JsonUtil.toJson(jsonResponse));
            return;
        }

        try {
            // Package lookup details into a colon-separated identifier plain-text string
            String rawText = db.trim() + ":" + table.trim();
            // Encrypt identifier using symmetric encryption AES
            String encryptedToken = EncryptionUtil.encrypt(rawText);

            String scheme = request.getScheme();
            String serverName = request.getServerName();
            int port = request.getServerPort();
            String contextPath = request.getContextPath();
            
            String portStr = (port == 80 || port == 443) ? "" : ":" + port;
            String relativeUrl = "/apps/dccmf/api/lookup/generic?t=" + encryptedToken;
            String absoluteUrl = scheme + "://" + serverName + portStr + contextPath + relativeUrl;

            // Automatically save generated API relative link to dynamic APIs store
            new LookupApiService().saveLookupApi(relativeUrl);

            // Return relative and absolute API routes containing the lookup token
            jsonResponse.put("success", true);
            jsonResponse.put("relativeUrl", relativeUrl);
            jsonResponse.put("absoluteUrl", absoluteUrl);
            jsonResponse.put("token", encryptedToken);
        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Error generating encrypted API URL: " + e.getMessage());
            e.printStackTrace();
        }

        out.write(JsonUtil.toJson(jsonResponse));
        return;
    }

    try {
        // Fetch databases to populate Lookup API generation selectors
        List<String> databases = new ConfigService().getDatabases();
        request.setAttribute("databases", databases);
        
        // Fetch all generated Lookup APIs from dynamic APIs store
        List<LookupApiEntity> lookupApis = new LookupApiService().getAllLookupApis();
        request.setAttribute("lookupApis", lookupApis);
    } catch (Exception e) {
        request.setAttribute("dbError", "Failed to retrieve databases or APIs: " + e.getMessage());
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Generate Lookup API - DCCMF</title>
    <link rel="stylesheet" href="/apps/apps/dccmf/css/style.css">
    <style>
        .api-result-box {
            margin-top: 1.5rem;
            padding: 1.25rem;
            background: rgba(255, 255, 255, 0.05);
            border: 1px solid var(--border-color);
            border-radius: 8px;
        }
        .copy-group {
            display: flex;
            gap: 10px;
            margin-bottom: 1rem;
        }
        .copy-group input {
            flex-grow: 1;
            font-family: monospace;
            font-size: 0.9rem;
            background: rgba(0, 0, 0, 0.2);
            border-color: var(--border-color);
            color: var(--text-primary);
        }
        .info-note {
            padding: 1rem;
            background: rgba(13, 45, 119, 0.15);
            border-left: 4px solid var(--primary-color);
            border-radius: 4px;
            margin-top: 1rem;
            font-size: 0.95rem;
            line-height: 1.5;
        }
        /* Centered Compact Table overrides */
        .config-table th, 
        .config-table td {
            padding: 0.5rem 0.35rem !important; /* Tight padding */
            text-align: center !important; /* Center all column text and content */
        }
        .config-table th {
            font-size: 0.8rem;
        }
        .config-table td {
            font-size: 0.8rem;
        }
        /* Make action buttons compact inside the table */
        .config-table .btn {
            padding: 0.22rem 0.45rem !important;
            font-size: 0.75rem !important;
            line-height: 1.2 !important;
            margin: 0 !important;
            height: auto !important;
            min-height: 0 !important;
        }
        /* Centered column alignments */
        .text-center {
            text-align: center !important;
        }
    </style>
</head>
<body>
    <!-- ── App Banner Header ── -->
    <div class="App-banner">
        <img src="/apps/apps/dccmf/images/App_banner.png" class="App-logo-img" alt="App Portal Logo">
    </div>

    <!-- Navbar -->
    <nav class="navbar">
        <a href="/apps/apps/dccmf/admin/dashboard.jsp" class="navbar-brand">
             <span>ADMIN</span>
        </a>
        <ul class="navbar-nav">
            <li><a href="/apps/apps/dccmf/admin/dashboard.jsp" class="navbar-link">Configure Tables</a></li>
            <li><a href="/apps/apps/dccmf/admin/generateApi.jsp" class="navbar-link active">Generate API</a></li>
            <li><a href="/apps/apps/dccmf/admin/manageLinks.jsp" class="navbar-link">Manage Links</a></li>
            <li>
                <a href="/apps/apps/dccmf/admin/login.jsp?action=logout" class="btn-logout" style="text-decoration: none; display: inline-block;">Logout</a>
            </li>
        </ul>
    </nav>

    <!-- Main Container -->
    <div class="container">
        <div class="page-header">
            <h2>Generate Dropdown Lookup API</h2>
            <p>Select a database table to generate a secure encrypted dropdown lookup endpoint. The selected table must contain <strong>code</strong> and <strong>value</strong> columns.</p>
        </div>

        <div class="glass-card">
            <div class="grid-2">
                <div class="form-group">
                    <label for="db-select" class="form-label">Database Name</label>
                    <select id="db-select" class="form-control" onchange="loadTables()">
                        <option value="">-- Select Database --</option>
                        <c:forEach var="db" items="${databases}">
                            <option value="${db}">${db}</option>
                        </c:forEach>
                    </select>
                </div>
                <div class="form-group">
                    <label for="table-select" class="form-label">Database Table</label>
                    <select id="table-select" class="form-control" onchange="onTableSelect()" disabled>
                        <option value="">-- Select Database First --</option>
                    </select>
                </div>
            </div>

            <div style="margin-top: 2rem; display: flex; justify-content: flex-end;">
                <button id="generate-btn" class="btn btn-primary" onclick="generateApiUrl()" disabled>Generate Lookup API</button>
            </div>
        </div>

        <!-- Result Container -->
        <div id="result-card" class="glass-card" style="display: none; margin-top: 2rem;">
            <h3 style="margin-bottom: 1rem; color: var(--secondary-color);">Generated API Lookup Endpoint</h3>
            
            <div class="form-group">
                <label class="form-label">Relative API Lookup Path</label>
                <div class="copy-group">
                    <input type="text" id="relative-url-output" class="form-control" readonly>
                    <button class="btn btn-secondary" onclick="copyValue('relative-url-output', this)">Copy</button>
                </div>
            </div>

            
        </div>

        <!-- Generated Lookup APIs Grid Table -->
        <div class="glass-card" style="margin-top: 2rem;">
            <h3 style="margin-bottom: 1rem; color: var(--secondary-color);">Generated Lookup APIs</h3>
            
            <c:choose>
                <c:when test="${empty lookupApis}">
                    <div style="text-align: center; padding: 2rem; color: var(--text-muted);">
                        No dropdown lookup APIs generated yet. Select a table above to create one.
                    </div>
                </c:when>
                <c:otherwise>
                    <div class="config-table-container">
                        <table class="config-table" style="table-layout: fixed; width: 100%;">
                            <thead>
                                <tr>
                                    <th style="text-align: center; width: 8%;">ID</th>
                                    <th style="text-align: center; width: 25%;">Database</th>
                                    <th style="text-align: center; width: 25%;">Table Name</th>
                                    <th style="text-align: center; width: 27%;">Created At</th>
                                    <th style="text-align: center; width: 15%;">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:forEach var="api" items="${lookupApis}">
                                    <%
                                        LookupApiEntity apiVal = (LookupApiEntity) pageContext.findAttribute("api");
                                        String formattedCreated = "";
                                        if (apiVal.createdAt() != null) {
                                            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
                                            formattedCreated = apiVal.createdAt().format(formatter) + " IST";
                                        }
                                        pageContext.setAttribute("formattedCreated", formattedCreated);
                                    %>
                                    <tr id="api-row-${api.id()}">
                                        <td class="text-center"><strong>${api.id()}</strong></td>
                                        <td class="text-center" style="font-family: monospace; font-size: 0.82rem; color: var(--text-secondary);">${api.database()}</td>
                                        <td class="text-center" style="font-family: monospace; font-size: 0.82rem; color: var(--text-secondary);">${api.tableName()}</td>
                                        <td class="text-center" style="font-size: 0.82rem; color: var(--text-secondary);">${formattedCreated}</td>
                                        <td class="text-center">
                                            <div style="display: flex; gap: 0.35rem; justify-content: center; align-items: center;">
                                                <button class="btn btn-secondary btn-sm" onclick="copyApiLink('${api.apiLink()}', this)">
                                                    Copy Link
                                                </button>
                                                <button class="btn btn-sm" style="padding: 0.22rem 0.45rem; display: inline-flex; align-items: center; justify-content: center; margin: 0; background-color: #fee2e2; color: #ef4444; border: 1px solid #fca5a5;" 
                                                        onclick="deleteApi(${api.id()})" title="Delete API">
                                                    <svg xmlns="http://www.w3.org/2000/svg" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="display: block;">
                                                        <path d="M3 6h18"/>
                                                        <path d="M19 6v14c0 1-1 2-2 2H7c-1 0-2-1-2-2V6"/>
                                                        <path d="M8 6V4c0-1 1-2 2-2h4c1 0 2 1 2 2v2"/>
                                                        <line x1="10" x2="10" y1="11" y2="17"/>
                                                        <line x1="14" x2="14" y1="11" y2="17"/>
                                                    </svg>
                                                </button>
                                            </div>
                                        </td>
                                    </tr>
                                </c:forEach>
                            </tbody>
                        </table>
                    </div>
                </c:otherwise>
            </c:choose>
        </div>
    </div>

    <script>
        const contextPath = "/apps";



        async function loadTables() {
            const dbSelect = document.getElementById("db-select");
            const tableSelect = document.getElementById("table-select");
            const generateBtn = document.getElementById("generate-btn");
            const resultCard = document.getElementById("result-card");
            
            resultCard.style.display = "none";
            const db = dbSelect.value;

            if (!db) {
                tableSelect.disabled = true;
                tableSelect.innerHTML = "<option value=''>-- Select Database First --</option>";
                generateBtn.disabled = true;
                return;
            }

            try {
                const response = await fetch(contextPath + "/apps/dccmf/admin/api/tables?db=" + encodeURIComponent(db));
                const data = await response.json();
                
                if (data.success) {
                    tableSelect.innerHTML = "<option value=''>-- Select Table --</option>";
                    data.tables.forEach(table => {
                        const opt = document.createElement("option");
                        opt.value = table;
                        opt.textContent = table;
                        tableSelect.appendChild(opt);
                    });
                    tableSelect.disabled = false;
                } else {
                    alert("Error loading tables: " + data.message);
                }
            } catch (err) {
                console.error(err);
                alert("Failed to load tables.");
            }
        }

        function onTableSelect() {
            const tableSelect = document.getElementById("table-select");
            const generateBtn = document.getElementById("generate-btn");
            const resultCard = document.getElementById("result-card");

            resultCard.style.display = "none";
            generateBtn.disabled = !tableSelect.value;
        }

        async function generateApiUrl() {
            const db = document.getElementById("db-select").value;
            const table = document.getElementById("table-select").value;
            const resultCard = document.getElementById("result-card");

            if (!db || !table) {
                alert("Please select both Database and Table parameters first.");
                return;
            }

            try {
                const params = new URLSearchParams();
                params.append("db", db);
                params.append("table", table);

                const response = await fetch(contextPath + "/apps/dccmf/admin/generateApi.jsp", {
                    method: "POST",
                    headers: { "Content-Type": "application/x-www-form-urlencoded" },
                    body: params.toString()
                });
                const data = await response.json();

                if (data.success) {
                    document.getElementById("relative-url-output").value = data.relativeUrl;
                    resultCard.style.display = "block";
                    resultCard.scrollIntoView({ behavior: "smooth" });
                    
                    // Reload page after a delay to show the new link in the table below
                    setTimeout(() => {
                        window.location.reload();
                    }, 1000);
                } else {
                    alert("Error: " + data.message);
                }
            } catch (err) {
                console.error(err);
                alert("Failed to generate lookup API.");
            }
        }

        function copyValue(inputId, btnEl) {
            const copyText = document.getElementById(inputId);
            copyText.select();
            copyText.setSelectionRange(0, 99999);
            navigator.clipboard.writeText(copyText.value);
            
            const originalText = btnEl.textContent;
            btnEl.textContent = "Copied!";
            btnEl.style.background = "var(--success-color)";
            btnEl.style.color = "var(--text-primary)";
            
            setTimeout(() => {
                btnEl.textContent = originalText;
                btnEl.style.background = "";
                btnEl.style.color = "";
            }, 2000);
        }

        function copyApiLink(relativeLink, btnEl) {
            navigator.clipboard.writeText(relativeLink);
            
            const originalText = btnEl.textContent;
            btnEl.textContent = "Copied!";
            btnEl.style.background = "var(--success-color)";
            btnEl.style.color = "var(--text-primary)";
            
            setTimeout(() => {
                btnEl.textContent = originalText;
                btnEl.style.background = "";
                btnEl.style.color = "";
            }, 2000);
        }

        async function deleteApi(id) {
            if (!confirm("Are you sure you want to delete this lookup API?")) {
                return;
            }

            try {
                const params = new URLSearchParams();
                params.append("action", "delete");
                params.append("id", id);

                const response = await fetch(contextPath + "/apps/dccmf/admin/generateApi.jsp", {
                    method: "POST",
                    headers: { "Content-Type": "application/x-www-form-urlencoded" },
                    body: params.toString()
                });
                const data = await response.json();

                if (data.success) {
                    const row = document.getElementById("api-row-" + id);
                    if (row) {
                        row.style.opacity = "0";
                        setTimeout(() => {
                            row.remove();
                            // If table is empty, reload page to show empty state
                            const tbody = document.querySelector(".config-table tbody");
                            if (tbody && tbody.children.length === 0) {
                                window.location.reload();
                            }
                        }, 300);
                    }
                } else {
                    alert("Delete failed: " + data.message);
                }
            } catch (err) {
                console.error(err);
                alert("Failed to delete API.");
            }
        }

        // Auto-load tables on page load if browser pre-selects/restores a database selection
        window.addEventListener("DOMContentLoaded", () => {
            const dbSelect = document.getElementById("db-select");
            if (dbSelect && dbSelect.value) {
                loadTables();
            }
        });
    </script>
</body>
</html>
