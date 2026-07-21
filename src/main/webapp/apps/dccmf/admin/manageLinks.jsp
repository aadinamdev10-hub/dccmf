<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="apps.dccmf.util.LinkService" %>
<%@ page import="apps.dccmf.util.LinkEntity" %>
<%@ page import="apps.dccmf.util.ConfigService" %>
<%@ page import="apps.dccmf.util.TableConfig" %>
<%@ page import="apps.dccmf.util.JsonUtil" %>
<%@ page import="java.util.List" %>
<%@ page import="java.util.Map" %>
<%@ page import="java.util.HashMap" %>
<%@ page import="java.sql.SQLException" %>
<%
    // =========================================================================
    // DCCMF ADMIN ACTIVE SHAREABLE LINKS MANAGER
    // File: /apps/dccmf/admin/manageLinks.jsp
    // Description: Admin interface to list, schedule, activate, and delete
    //              shareable token links distributed to target departments.
    // =========================================================================

    LinkService linkService = new LinkService();

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        // Handle AJAC request calls (revoke/delete/updateSchedule)
        response.setContentType("application/json");
        response.setCharacterEncoding("UTF-8");
        
        String action = request.getParameter("action");
        String token = request.getParameter("token");
        Map<String, Object> jsonResponse = new HashMap<>();

        if ("revoke".equalsIgnoreCase(action) && token != null) {
            try {
                // Instantly disable token access by setting status to INACTIVE
                linkService.revokeLink(token);
                jsonResponse.put("success", true);
                jsonResponse.put("message", "Link successfully revoked.");
            } catch (SQLException e) {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Database error: " + e.getMessage());
                e.printStackTrace();
            }
        } else if ("delete".equalsIgnoreCase(action) && token != null) {
            try {
                // Permanently delete link token record from database
                linkService.deleteLink(token);
                jsonResponse.put("success", true);
                jsonResponse.put("message", "Link successfully deleted.");
            } catch (SQLException e) {
                response.setStatus(HttpServletResponse.SC_INTERNAL_SERVER_ERROR);
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Database error: " + e.getMessage());
                e.printStackTrace();
            }
        } else if ("updateSchedule".equalsIgnoreCase(action) && token != null) {
            try {
                // Update start time, expiration time and status schedules of the token link
                String startsAtParam = request.getParameter("startsAt");
                String expiresAtParam = request.getParameter("expiresAt");
                String statusParam = request.getParameter("status");

                java.time.LocalDateTime startsAt = null;
                if (startsAtParam != null && !startsAtParam.trim().isEmpty()) {
                    startsAt = java.time.LocalDateTime.parse(startsAtParam);
                }

                java.time.LocalDateTime expiresAt = null;
                if (expiresAtParam != null && !expiresAtParam.trim().isEmpty()) {
                    expiresAt = java.time.LocalDateTime.parse(expiresAtParam);
                }

                if (statusParam == null || statusParam.trim().isEmpty()) {
                    statusParam = "ACTIVE";
                }

                linkService.updateLinkSchedule(token, startsAt, expiresAt, statusParam);
                jsonResponse.put("success", true);
                jsonResponse.put("message", "Link schedule updated successfully.");
            } catch (Exception e) {
                response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
                jsonResponse.put("success", false);
                jsonResponse.put("message", "Error: " + e.getMessage());
                e.printStackTrace();
            }
        } else {
            response.setStatus(HttpServletResponse.SC_BAD_REQUEST);
            jsonResponse.put("success", false);
            jsonResponse.put("message", "Invalid parameters.");
        }

        out.write(JsonUtil.toJson(jsonResponse));
        return;
    }

    try {
        // Fetch all generated dynamic links from links metadata store
        List<LinkEntity> links = linkService.getAllLinks();
        request.setAttribute("links", links);

        // Fetch corresponding table configurations for database/table mapping
        ConfigService configService = new ConfigService();
        Map<Integer, TableConfig> configMap = new HashMap<>();
        for (LinkEntity link : links) {
            int cid = link.configId();
            if (!configMap.containsKey(cid)) {
                TableConfig tc = configService.getConfigById(cid);
                if (tc != null) {
                    configMap.put(cid, tc);
                }
            }
        }
        request.setAttribute("configMap", configMap);
    } catch (Exception e) {
        request.setAttribute("dbError", "Failed to retrieve links: " + e.getMessage());
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Links - DCCMF</title>
    <link rel="stylesheet" href="/apps/apps/dccmf/css/style.css">
    <style>
        /* Compact Table styles to prevent horizontal scrollbars */
        .config-table th, 
        .config-table td {
            padding: 0.5rem 0.35rem !important; /* Tight padding */
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
            <li><a href="/apps/apps/dccmf/admin/generateApi.jsp" class="navbar-link">Generate API</a></li>
            <li><a href="/apps/apps/dccmf/admin/manageLinks.jsp" class="navbar-link active">Manage Links</a></li>
            <li>
                <a href="/apps/apps/dccmf/admin/login.jsp?action=logout" class="btn-logout" style="text-decoration: none; display: inline-block;">Logout</a>
            </li>
        </ul>
    </nav>

    <!-- Main Container -->
    <div class="container">
        <div class="page-header">
            <h2>Active Shareable Links</h2>
            <p>View, manage, and revoke active data collection or editing tokens.</p>
        </div>

        <% if (request.getAttribute("dbError") != null) { %>
            <div class="alert alert-danger">
                <%= request.getAttribute("dbError") %>
            </div>
        <% } %>

        <div class="glass-card">
            <h3>Registered Link Configurations</h3>
            
            <c:choose>
                <c:when test="${empty links}">
                    <div style="text-align: center; padding: 2rem; color: var(--text-muted);">
                        No shareable links generated yet. Visit the Table Configuration page to create one.
                    </div>
                </c:when>
                <c:otherwise>
                    <div class="config-table-container">
                        <table class="config-table" style="table-layout: fixed; width: 100%;">
                            <thead>
                                <tr>
                                    <th style="width: 32%;">Shareable Link</th>
                                    <th style="text-align: center; width: 6%;">Config ID</th>
                                    <th style="text-align: center; width: 15%;">Database & Table</th>
                                    <th style="text-align: center; width: 15%;">Created At</th>
                                    <th style="text-align: center; width: 11%;">Active To / Expires</th>
                                    <th style="text-align: center; width: 8%;">Status</th>
                                    <th style="text-align: center; width: 13%; min-width: 140px;">Actions</th>
                                </tr>
                            </thead>
                            <tbody>
                                <c:forEach var="link" items="${links}">
                                    <%
                                        LinkEntity linkVal = (LinkEntity) pageContext.findAttribute("link");
                                        @SuppressWarnings("unchecked")
                                        java.util.Map<Integer, TableConfig> cMap = (java.util.Map<Integer, TableConfig>) request.getAttribute("configMap");
                                        TableConfig tcVal = cMap != null ? cMap.get(linkVal.configId()) : null;
                                        pageContext.setAttribute("tc", tcVal);

                                        // Format Created At date to IST format (e.g. 2026-07-14 16:38:20 IST)
                                        String formattedCreated = "";
                                        if (linkVal.createdAt() != null) {
                                            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
                                            formattedCreated = linkVal.createdAt().format(formatter) + " IST";
                                        }
                                        pageContext.setAttribute("formattedCreated", formattedCreated);

                                        // Format Expires At date to IST format (e.g. 2026-07-14 16:38:20 IST)
                                        String formattedExpires = "Never";
                                        if (linkVal.expiresAt() != null) {
                                            java.time.format.DateTimeFormatter formatter = java.time.format.DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
                                            formattedExpires = linkVal.expiresAt().format(formatter) + " IST";
                                        }
                                        pageContext.setAttribute("formattedExpires", formattedExpires);
                                    %>
                                    <tr id="link-row-${link.token()}">
                                        <td>
                                            <c:set var="reqPort" value="${pageContext.request.serverPort}" />
                                            <c:set var="portSuffix" value="${reqPort == 80 || reqPort == 443 ? '' : ':'.concat(reqPort)}" />
                                            <c:set var="fullUrl" value="${pageContext.request.scheme}://${pageContext.request.serverName}${portSuffix}${pageContext.request.contextPath}/apps/dccmf/user/userForm.jsp?token=${link.token()}" />
                                            <div style="display: flex; gap: 8px; align-items: center;">
                                                <a href="${fullUrl}" target="_blank" title="${fullUrl}" style="flex: 1; min-width: 0; font-family: monospace; font-size: 0.82rem; color: var(--primary-color); text-decoration: underline; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; margin-right: 0.2rem;">
                                                    ${fullUrl}
                                                </a>
                                                <button class="btn btn-secondary btn-sm" onclick="copyLinkText('${fullUrl}', this)" style="padding: 0.25rem 0.5rem; font-size: 0.75rem; margin: 0; white-space: nowrap;">
                                                    Copy
                                                </button>
                                            </div>
                                        </td>
                                        <td style="text-align: center;"><strong>${link.configId()}</strong></td>
                                        <td class="text-center">
                                            <c:choose>
                                                <c:when test="${not empty tc}">
                                                    <span style="font-family: monospace; font-size: 0.82rem; color: var(--text-secondary); word-break: break-all;">
                                                        ${tc.database()} / ${tc.table()}
                                                    </span>
                                                </c:when>
                                                <c:otherwise>
                                                    <span style="color: var(--text-muted); font-size: 0.82rem;">N/A</span>
                                                </c:otherwise>
                                            </c:choose>
                                        </td>
                                        <td class="text-center" style="font-size: 0.82rem; color: var(--text-secondary);">${formattedCreated}</td>
                                        <td class="text-center" style="font-size: 0.82rem;" id="expires-text-${link.token()}">${formattedExpires}</td>
                                        <td class="text-center">
                                            <span id="badge-${link.token()}" class="badge <c:choose>
                                                <c:when test="${link.isActive()}">badge-active</c:when>
                                                <c:otherwise>badge-inactive</c:otherwise>
                                            </c:choose>">
                                                <c:choose>
                                                    <c:when test="${link.isActive()}">Active</c:when>
                                                    <c:when test="${link.status() == 'ACTIVE' and link.isNotStartedYet()}">ACTIVE (Pending)</c:when>
                                                    <c:when test="${link.status() == 'ACTIVE' and link.isExpired()}">EXPIRED</c:when>
                                                    <c:otherwise>INACTIVE</c:otherwise>
                                                </c:choose>
                                            </span>
                                        </td>
                                        <td class="text-center">
                                            <div style="display: flex; gap: 0.35rem; justify-content: center; align-items: center;" id="actions-cell-${link.token()}">
                                                <c:choose>
                                                    <c:when test="${not empty tc}">
                                                        <a href="/apps/apps/dccmf/admin/dashboard.jsp?db=${tc.database()}&table=${tc.table()}&configId=${link.configId()}" 
                                                           class="btn btn-secondary btn-sm" 
                                                           style="padding: 0.35rem 0.75rem; font-size: 0.8rem; text-decoration: none; display: inline-flex; align-items: center; justify-content: center; margin: 0;">
                                                            Edit
                                                        </a>
                                                    </c:when>
                                                    <c:otherwise>
                                                        <button class="btn btn-secondary btn-sm" style="padding: 0.35rem 0.75rem; font-size: 0.8rem;" disabled>
                                                            Edit
                                                        </button>
                                                    </c:otherwise>
                                                </c:choose>

                                                <button class="btn btn-outline btn-sm" style="padding: 0.35rem 0.75rem; font-size: 0.8rem;"
                                                        data-token="${link.token()}"
                                                        data-configid="${link.configId()}"
                                                        data-starts="${link.startsAt()}"
                                                        data-expires="${link.expiresAt()}"
                                                        data-status="${link.status()}"
                                                        onclick="openScheduleModal(this)">
                                                    Schedule
                                                </button>
                                                


                                                <button class="btn btn-sm" style="padding: 0.35rem 0.5rem; display: inline-flex; align-items: center; justify-content: center; margin: 0; background-color: #fee2e2; color: #ef4444; border: 1px solid #fca5a5;" 
                                                        onclick="deleteToken('${link.token()}')" title="Delete Link">
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

    <!-- Edit Schedule Modal -->
    <div id="schedule-modal" class="modal">
        <div class="modal-content">
            <h3 style="margin-bottom: 1.5rem; color: var(--primary);">Schedule Link Access</h3>
            
            <div id="modal-alert-container"></div>
            
            <form id="schedule-form" onsubmit="saveSchedule(event)">
                <input type="hidden" id="modal-token">
                
                <div class="form-group" style="margin-bottom: 1rem;">
                    <label class="form-label" style="font-weight: 600;">TOKEN</label>
                    <input type="text" id="modal-token-display" class="form-control" readonly style="background-color: #f1f5f9; color: var(--text-secondary);">
                </div>
                
                <div class="form-group" style="margin-bottom: 1.5rem;">
                    <label class="form-label" style="font-weight: 600;">MAPPED CONFIG ID</label>
                    <span id="modal-config-id" style="font-weight: bold; font-size: 1.1rem; color: var(--primary);"></span>
                </div>
                
                <div class="form-group" style="margin-bottom: 1.25rem;">
                    <label class="form-label" style="font-weight: 600;">ACTIVE FROM (START TIME)</label>
                    <input type="datetime-local" id="modal-starts" class="form-control">
                    <small style="color: var(--text-muted); font-size: 0.8rem;">Leave blank to start immediately.</small>
                </div>
                
                <div class="form-group" style="margin-bottom: 1.25rem;">
                    <label class="form-label" style="font-weight: 600;">ACTIVE TO (EXPIRATION TIME)</label>
                    <input type="datetime-local" id="modal-expires" class="form-control">
                    <small style="color: var(--text-muted); font-size: 0.8rem;">Leave blank for no expiration limit.</small>
                </div>
                
                <div class="form-group" style="margin-bottom: 1.5rem;">
                    <label class="form-label" style="font-weight: 600;">STATUS</label>
                    <select id="modal-status" class="form-control">
                        <option value="ACTIVE">ACTIVE</option>
                        <option value="INACTIVE">INACTIVE</option>
                    </select>
                </div>
                
                <div style="display: flex; gap: 1rem; justify-content: flex-end; margin-top: 2rem;">
                    <button type="button" class="btn btn-secondary" onclick="closeScheduleModal()">Cancel</button>
                    <button type="submit" class="btn btn-primary">Save Changes</button>
                </div>
            </form>
        </div>
    </div>

    <footer>
        <p>&copy; 2026 Application Portal (App), Main Campus. All Rights Reserved.</p>
    </footer>

    <script>
        const contextPath = "/apps";



        function copyLinkText(text, btnEl) {
            navigator.clipboard.writeText(text).then(() => {
                const originalText = btnEl.textContent;
                btnEl.textContent = "Copied!";
                const originalBg = btnEl.style.background;
                const originalColor = btnEl.style.color;
                const originalBorder = btnEl.style.borderColor;
                btnEl.style.background = "var(--success-color)";
                btnEl.style.color = "#ffffff";
                btnEl.style.borderColor = "var(--success-color)";
                setTimeout(() => {
                    btnEl.textContent = originalText;
                    btnEl.style.background = originalBg;
                    btnEl.style.color = originalColor;
                    btnEl.style.borderColor = originalBorder;
                }, 2000);
            }).catch(err => {
                console.error("Failed to copy text: ", err);
                alert("Failed to copy link. Please copy manually.");
            });
        }



        async function deleteToken(token) {
            try {
                 const response = await fetch(contextPath + "/apps/dccmf/admin/manageLinks.jsp?action=delete&token=" + token, {
                    method: "POST"
                });
                const data = await response.json();

                if (data.success) {
                    const row = document.getElementById("link-row-" + token);
                    if (row) row.remove();
                } else {
                    alert("Failed to delete link: " + data.message);
                }
            } catch (err) {
                console.error(err);
                alert("Network error occurred.");
            }
        }

         function copyValue(token) {
            // Helper to copy the full user link URL directly
            const linkUrl = window.location.origin + contextPath + "/apps/dccmf/user/userForm.jsp?token=" + token;
            navigator.clipboard.writeText(linkUrl);
            alert("Shareable user form link copied to clipboard!\n" + linkUrl);
        }

        function openScheduleModal(button) {
            const token = button.getAttribute("data-token");
            const configId = button.getAttribute("data-configid");
            let starts = button.getAttribute("data-starts") || "";
            let expires = button.getAttribute("data-expires") || "";
            const status = button.getAttribute("data-status");

            // Format LocalDateTime strings (e.g. 2026-06-23T14:47:09 to 2026-06-23T14:47)
            if (starts.length > 16) starts = starts.substring(0, 16);
            if (expires.length > 16) expires = expires.substring(0, 16);

            document.getElementById("modal-token").value = token;
            document.getElementById("modal-token-display").value = token;
            document.getElementById("modal-config-id").textContent = configId;
            document.getElementById("modal-starts").value = starts;
            document.getElementById("modal-expires").value = expires;
            document.getElementById("modal-status").value = status;
            
            document.getElementById("modal-alert-container").innerHTML = "";
            document.getElementById("schedule-modal").classList.add("active");
        }

        function closeScheduleModal() {
            document.getElementById("schedule-modal").classList.remove("active");
        }

        async function saveSchedule(e) {
            e.preventDefault();
            const alertContainer = document.getElementById("modal-alert-container");
            alertContainer.innerHTML = "";

            const token = document.getElementById("modal-token").value;
            const startsAt = document.getElementById("modal-starts").value;
            const expiresAt = document.getElementById("modal-expires").value;
            const status = document.getElementById("modal-status").value;

            // Validate that expiresAt > startsAt if both are set
            if (startsAt && expiresAt) {
                const sDate = new Date(startsAt);
                const eDate = new Date(expiresAt);
                if (eDate <= sDate) {
                    alertContainer.innerHTML = '<div class="alert alert-danger">Expiration time must be after the start time.</div>';
                    return;
                }
            }

            try {
                const params = new URLSearchParams();
                params.append("action", "updateSchedule");
                params.append("token", token);
                params.append("startsAt", startsAt);
                params.append("expiresAt", expiresAt);
                params.append("status", status);

                 const response = await fetch(contextPath + "/apps/dccmf/admin/manageLinks.jsp", {
                    method: "POST",
                    headers: {
                        "Content-Type": "application/x-www-form-urlencoded"
                    },
                    body: params.toString()
                });
                const data = await response.json();

                if (data.success) {
                    const startsText = startsAt ? startsAt.replace("T", " ") : "Immediate";
                    const expiresText = expiresAt ? expiresAt.replace("T", " ") : "Never";
                    
                    document.getElementById("starts-text-" + token).textContent = startsText;
                    document.getElementById("expires-text-" + token).textContent = expiresText;
                    
                    // Update button data attributes for next edit
                    const editBtn = document.querySelector(`button[data-token="${token}"]`);
                    if (editBtn) {
                        editBtn.setAttribute("data-starts", startsAt);
                        editBtn.setAttribute("data-expires", expiresAt);
                        editBtn.setAttribute("data-status", status);
                    }

                    // Update Badge Status
                    const badge = document.getElementById("badge-" + token);
                    badge.textContent = status;
                    
                    // Calculate if it is currently active to set the right badge class
                    const now = new Date();
                    let isCurrentActive = status === "ACTIVE";
                    if (isCurrentActive) {
                        if (startsAt && new Date(startsAt) > now) {
                            isCurrentActive = false;
                            badge.textContent = "ACTIVE (Pending)";
                        }
                        if (expiresAt && new Date(expiresAt) < now) {
                            isCurrentActive = false;
                            badge.textContent = "EXPIRED";
                        }
                    }
                    
                    if (isCurrentActive) {
                        badge.className = "badge badge-active";
                    } else {
                        badge.className = "badge badge-inactive";
                    }


                    
                    closeScheduleModal();
                } else {
                    alertContainer.innerHTML = '<div class="alert alert-danger">' + data.message + '</div>';
                }
            } catch (err) {
                console.error(err);
                alertContainer.innerHTML = '<div class="alert alert-danger">Network error occurred.</div>';
            }
        }
    </script>
</body>
</html>
</body>
</html>
