<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="apps.dccmf.util.LinkEntity" %>
<%@ page import="apps.dccmf.util.TableConfig" %>
<%@ page import="apps.dccmf.util.ConfigService" %>
<%@ page import="apps.dccmf.util.LinkService" %>
<%@ page import="apps.dccmf.util.JsonUtil" %>
<%@ page import="apps.dccmf.util.DynamicQueryDAO" %>
<%@ page import="java.sql.SQLException" %>
<%
    // =========================================================================
    // DCCMF USER DYNAMIC FORM CONTROLLER & ENTRY POINT
    // File: /apps/dccmf/user/userForm.jsp
    // Description: Serves as the user-facing interface for searching, editing,
    //              uploading, and downloading dynamic database records.
    //              This JSP is accessed via shareable token links.
    // =========================================================================

    // 1. Extract the secure shareable token from request parameters
    String token = request.getParameter("token");

    // 2. Validate token presence. If missing, forward to error page.
    if (token == null || token.trim().isEmpty()) {
        request.setAttribute("errorTitle", "Missing Token");
        request.setAttribute("errorMessage", "Access token is missing in the request URL.");
        request.getRequestDispatcher("error.jsp").forward(request, response);
        return;
    }

    // 3. Initialize background services for database operations
    LinkService linkService = new LinkService();
    ConfigService configService = new ConfigService();

    try {
        // 4. Retrieve link metadata associated with this token
        LinkEntity link = linkService.getLinkByToken(token);
        if (link == null) {
            request.setAttribute("errorTitle", "Link Not Found");
            request.setAttribute("errorMessage", "The link you are trying to access does not exist.");
            request.getRequestDispatcher("error.jsp").forward(request, response);
            return;
        }

        // 5. Enforce link lifecycle schedule and status checks (ACTIVE/INACTIVE/EXPIRED)
        if (!link.isActive()) {
            String errorMsg = "This link is no longer active. It may have been disabled or expired.";
            if ("INACTIVE".equalsIgnoreCase(link.status())) {
                errorMsg = "This link has been marked inactive by the administrator.";
            } else if (link.isExpired()) {
                errorMsg = "This link expired on " + link.expiresAt() + " and is no longer active.";
            } else if (link.isNotStartedYet()) {
                errorMsg = "This link is not active yet. It is scheduled to be active starting " + link.startsAt() + ".";
            }
            request.setAttribute("errorTitle", "Link Inactive");
            request.setAttribute("errorMessage", errorMsg);
            request.getRequestDispatcher("error.jsp").forward(request, response);
            return;
        }

        // 6. Retrieve the dynamic column map configurations saved for this link
        TableConfig tableConfig = configService.getConfigById(link.configId());
        if (tableConfig == null) {
            request.setAttribute("errorTitle", "Config Error");
            request.setAttribute("errorMessage", "No active table configuration is mapped to this link.");
            request.getRequestDispatcher("error.jsp").forward(request, response);
            return;
        }

        // 7. Auto-resolve primary key column using database JDBC metadata
        String pkColumn = new DynamicQueryDAO().getPrimaryKeyColumn(tableConfig.database(), tableConfig.table());
        
        // 8. Bind variables to request attributes for browser-side JSP and Javascript access
        request.setAttribute("token", token);
        request.setAttribute("configJson", JsonUtil.toJson(tableConfig));
        request.setAttribute("primaryKey", pkColumn);

    } catch (SQLException e) {
        // Handle database communication failures gracefully
        request.setAttribute("errorTitle", "Database Error");
        request.setAttribute("errorMessage", "An error occurred while communicating with the database.");
        e.printStackTrace();
        request.getRequestDispatcher("error.jsp").forward(request, response);
        return;
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Manage Record - DCCMF</title>
    <link rel="stylesheet" href="/apps/apps/dccmf/css/style.css">
</head>
<body>
    <!-- ── App Banner Header ── -->
    <div class="App-banner">
        <img src="/apps/apps/dccmf/images/App_banner.png" class="App-logo-img" alt="App Portal Logo">
    </div>

    <!-- Main Container -->
    <div class="container">
        <!-- Back Navigation Button (placed right under the logo banner and blue line) -->
        <div id="back-nav-container" style="display: none; margin-bottom: 1.5rem; align-self: flex-start;">
            <button class="btn btn-secondary" onclick="handleBackNavigation()">
                ← Back
            </button>
        </div>
        <!-- 1. Search Panel -->
        <div id="search-section" class="card">
            <div class="page-header" style="border-left-color: var(--secondary-color);">
                <h2>Find Record</h2>
                <p>Provide search filters below to retrieve and edit your records.</p>
            </div>
            
            <div id="search-alert-container"></div>

            <form id="search-form" onsubmit="performSearch(event)">
                <div id="search-fields-container" class="search-grid">
                    <!-- Loaded dynamically via JS -->
                </div>
                <button type="submit" class="btn btn-primary" style="width: 100%;">
                    Search Records
                </button>
            </form>
        </div>

        <!-- 2. Search Results List -->
        <div id="results-section" class="card" style="display: none; margin-top: 2rem;">
            <div style="display: flex; justify-content: space-between; align-items: center; border-bottom: 2px solid var(--primary); padding-bottom: 0.5rem; margin-bottom: 1rem;">
                <h3 style="margin: 0; color: var(--primary);">
                    Search Results
                </h3>
                <div style="display: flex; gap: 0.5rem;">
                    <button class="btn btn-outline btn-sm" id="btn-download-csv" onclick="downloadCSV()" style="padding: 0.35rem 0.75rem; font-size: 0.8rem; font-weight: 600; border-color: var(--primary); color: var(--primary);">Download CSV</button>
                    <button class="btn btn-primary btn-sm" id="btn-upload-csv" onclick="triggerCSVUpload()" style="padding: 0.35rem 0.75rem; font-size: 0.8rem; font-weight: 600; margin: 0;">Upload CSV</button>
                    <input type="file" id="csv-file-input" accept=".csv" style="display: none;" onchange="handleCSVUpload(event)">
                </div>
            </div>
            <p style="color: var(--muted); margin-bottom: 1rem;">Select a record from the list below to edit its contents.</p>
            <div id="results-container">
                <!-- Records loaded dynamically via JS -->
            </div>
            <!-- Pagination Controls -->
            <div id="pagination-controls" style="margin-top: 1.5rem; display: flex; justify-content: space-between; align-items: center; padding-top: 1rem; border-top: 1px solid var(--border); flex-wrap: wrap; gap: 1rem;">
                <!-- Page Info and buttons built in JS -->
            </div>

        </div>

        <!-- 3. Edit Record Panel -->
        <div id="edit-section" class="card" style="display: none; margin-top: 2rem;">
            <div class="page-header" style="border-left-color: var(--primary-color);">
                <h2>Edit Record Information</h2>
                <p>Modify the allowed fields below. Non-editable fields are locked for security.</p>
            </div>

            <div id="edit-alert-container"></div>

            <form id="edit-form" onsubmit="saveRecord(event)">
                <div id="edit-fields-container" class="edit-grid">
                    <!-- Form fields generated dynamically via JS -->
                </div>

                <div style="margin-top: 2rem;">
                    <button type="submit" class="btn btn-primary" style="width: 100%;">
                        Save Modifications
                    </button>
                </div>
            </form>
        </div>
    </div>

    <footer>
        <p>&copy; 2026 Application Portal (App), Main Campus. All Rights Reserved.</p>
    </footer>

    <!-- JS logic -->
    <script>
        // Set context and token from JSP EL expression variables
        const token = "${token}";
        const config = ${configJson};
        const contextPath = "/apps";
        const primaryKey = "${primaryKey}";

        let searchResultsList = [];
        let activeRecord = null;
        let currentPage = 1;
        let currentServerPage = 0;
        let totalRecords = 0;
        let lastSearchCriteria = null; // Track last fetched criteria to detect changes

        // Initialize user portal
        document.addEventListener("DOMContentLoaded", () => {
            renderSearchForm();
        });

        // 1. Render Search Fields dynamically from JSON configurations
        async function renderSearchForm() {
            const container = document.getElementById("search-fields-container");
            container.innerHTML = "";

            for (const col of config.columns) {
                if (col.visible === false) {
                    continue;
                }
                if (col.searchKey) {
                    const formGrp = document.createElement("div");
                    formGrp.className = "form-group";

                    const label = document.createElement("label");
                    label.className = "form-label";
                    label.textContent = col.name.toUpperCase();
                    formGrp.appendChild(label);

                    // Render search key as a dropdown containing distinct database values
                    const select = document.createElement("select");
                    select.className = "form-control search-input";
                    select.name = col.name;
                    select.innerHTML = '<option value="">-- Select ' + col.name.toUpperCase() + ' --</option>';
                    
                    // Fetch dynamic unique column values from database via API
                    const apiUrl = "/apps/dccmf/user/api/searchOptions?token=" + token + "&column=" + col.name;
                    fetchDropdownOptions(apiUrl, select);
                    
                    formGrp.appendChild(select);
                    container.appendChild(formGrp);
                }
            }
        }

        function formatDateForDisplay(dateStr) {
            if (!dateStr) return "";
            const parts = dateStr.split("-");
            if (parts.length === 3 && parts[0].length === 4) {
                return parts[2] + "-" + parts[1] + "-" + parts[0];
            }
            return dateStr;
        }

        function formatDateForBackend(dateStr) {
            if (!dateStr) return "";
            const parts = dateStr.split("-");
            if (parts.length === 3 && parts[2].length === 4) {
                return parts[2] + "-" + parts[1] + "-" + parts[0];
            }
            return dateStr;
        }

        // Helper to load dropdown options from dynamic API Source URL
        async function fetchDropdownOptions(apiUrl, selectEl, selectValue = null) {
            try {
                // Ensure context path is prepended correctly if URL starts with /api
                const targetUrl = apiUrl.startsWith("/") ? (contextPath + apiUrl) : apiUrl;
                const response = await fetch(targetUrl);
                const options = await response.json();
                
                // Auto-detect whether the column stores code (e.g. DEPT01) or value (e.g. Finance)
                let useValueAsKey = false;
                const columnName = selectEl.name;
                const sampleValue = columnName ? searchResultsList.map(r => r[columnName]).find(v => v !== undefined && v !== null && v !== "") : null;
                const checkValue = (selectValue !== null && selectValue !== "") ? selectValue : sampleValue;
                
                if (checkValue !== null && checkValue !== "") {
                    const hasValueMatch = options.some(opt => opt.value !== undefined && String(opt.value) === String(checkValue));
                    const hasCodeMatch = options.some(opt => opt.code !== undefined && String(opt.code) === String(checkValue));
                    if (hasValueMatch && !hasCodeMatch) {
                        useValueAsKey = true;
                    }
                }
                
                options.forEach(opt => {
                    const option = document.createElement("option");
                    // Support both {code, value} and {value, label} shapes
                    const val = (useValueAsKey && opt.value !== undefined) ? opt.value : (opt.code !== undefined ? opt.code : opt.value);
                    let label = opt.value !== undefined ? opt.value : opt.label;
                    
                    if (label && String(label).match(/^\d{4}-\d{2}-\d{2}$/)) {
                        label = formatDateForDisplay(label);
                    }
                    
                    option.value = val;
                    option.textContent = label;
                    if (selectValue !== null && String(val) === String(selectValue)) {
                        option.selected = true;
                    }
                    selectEl.appendChild(option);
                });
            } catch (err) {
                console.error("Failed to load options from: " + apiUrl, err);
                const errorOpt = document.createElement("option");
                errorOpt.value = "";
                errorOpt.textContent = "Failed to load options";
                selectEl.appendChild(errorOpt);
            }
        }

        // 2. Perform Dynamic Search
        async function performSearch(e, targetPage = 1) {
            if (e) e.preventDefault();
            const alertContainer = document.getElementById("search-alert-container");
            alertContainer.innerHTML = "";

            const searchForm = document.getElementById("search-form");
            const inputs = searchForm.querySelectorAll(".search-input");
            const criteria = {};

            inputs.forEach(input => {
                if (input.value && input.value.trim() !== "") {
                    criteria[input.name] = input.value;
                }
            });

            // Require at least one filter value
            if (Object.keys(criteria).length === 0) {
                alertContainer.innerHTML = 
                    '<div class="alert alert-danger">' +
                        'Please select at least one search filter.' +
                    '</div>';
                return;
            }

            // If this is a fresh search (not a pagination click), always force a new server fetch
            // by resetting the cached server page so the criteria-change check below works correctly
            if (targetPage === 1) {
                currentServerPage = 0;
                lastSearchCriteria = null;
            }


            const serverPaging = config.serverSidePaging === true;
            const clientPaging = config.clientSidePaging === true;
            const clientPageSize = config.clientSidePageSize || 200;
            const serverPageSize = config.serverSidePageSize || 1000;

            // Determine which server page to fetch
            let requestedServerPage = 1;
            if (serverPaging) {
                if (clientPaging) {
                    requestedServerPage = Math.ceil((targetPage * clientPageSize) / serverPageSize);
                } else {
                    requestedServerPage = targetPage;
                }
            }

            // If server-side paging is active and BOTH the requested server page AND search criteria
            // match what was last fetched, we can skip the network call and just re-render locally.
            const criteriaKey = JSON.stringify(Object.keys(criteria).sort().reduce((o, k) => { o[k] = criteria[k]; return o; }, {}));
            if (serverPaging && requestedServerPage === currentServerPage && criteriaKey === lastSearchCriteria) {
                currentPage = targetPage;
                showResultsList();
                return;
            }

            if (serverPaging) {
                criteria.page = requestedServerPage;
            }

            try {
                // Show loading spinner
                alertContainer.innerHTML = '<div style="text-align: center; margin: 20px;"><div class="spinner" style="margin: 0 auto;"></div></div>';

                const response = await fetch(contextPath + "/apps/dccmf/user/api/search?token=" + token, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify(criteria)
                });
                const data = await response.json();
                alertContainer.innerHTML = "";

                if (data.success) {
                    searchResultsList = data.data || data.records || [];
                    totalRecords = data.totalCount !== undefined ? data.totalCount : searchResultsList.length;
                    
                    if (serverPaging) {
                        currentServerPage = requestedServerPage;
                        lastSearchCriteria = criteriaKey; // Remember what we fetched for this server page
                    } else {
                        currentServerPage = 1;
                        lastSearchCriteria = null;
                    }

                    currentPage = targetPage;


                    if (totalRecords === 0) {
                        alertContainer.innerHTML = 
                            '<div class="alert alert-danger">' +
                                'No records found matching the search criteria.' +
                            '</div>';
                    } else if (totalRecords === 1) {
                        // Directly load the single matching record into Edit mode
                        openEditForm(searchResultsList[0]);
                    } else {
                        // Show multi-results matching
                        showResultsList();
                    }
                } else {
                    alertContainer.innerHTML = 
                        '<div class="alert alert-danger">' +
                            'Error: ' + data.message +
                        '</div>';
                }
            } catch (err) {
                console.error(err);
                alertContainer.innerHTML = 
                    '<div class="alert alert-danger">' +
                        'Failed to connect to search service. Check database or network.' +
                    '</div>';
            }
        }

        function showResultsList() {
            document.getElementById("search-section").style.display = "none";
            document.getElementById("results-section").style.display = "block";
            document.getElementById("edit-section").style.display = "none";
            renderResultsTable();
            updateBackButtonVisibility();
        }

        function renderResultsTable() {
            const container = document.getElementById("results-container");
            container.innerHTML = "";
            container.className = "config-table-container";

            const table = document.createElement("table");
            table.className = "config-table";

            // Get all visible columns configured by the admin
            const displayCols = config.columns.filter(col => col.visible !== false);

            // Create table header
            const thead = document.createElement("thead");
            const trHead = document.createElement("tr");

            // Add default SR. NO. column header
            const thSr = document.createElement("th");
            thSr.textContent = "SR. NO.";
            trHead.appendChild(thSr);

            displayCols.forEach(col => {
                const th = document.createElement("th");
                th.textContent = col.name.toUpperCase();
                trHead.appendChild(th);
            });

            // Action header
            const thAction = document.createElement("th");
            thAction.textContent = "ACTION";
            thAction.style.textAlign = "center";
            trHead.appendChild(thAction);

            thead.appendChild(trHead);
            table.appendChild(thead);

            const clientPaging = config.clientSidePaging === true;
            const serverPaging = config.serverSidePaging === true;
            const clientPageSize = config.clientSidePageSize || 200;
            const serverPageSize = config.serverSidePageSize || 1000;

            let recordsToDisplay = [];
            if (clientPaging && serverPaging) {
                let localOffset = ((currentPage - 1) * clientPageSize) % serverPageSize;
                recordsToDisplay = searchResultsList.slice(localOffset, localOffset + clientPageSize);
            } else if (clientPaging) {
                recordsToDisplay = searchResultsList.slice((currentPage - 1) * clientPageSize, currentPage * clientPageSize);
            } else {
                recordsToDisplay = searchResultsList;
            }

            const pageSizeForSr = clientPaging ? clientPageSize : (serverPaging ? serverPageSize : null);
            const startSrNo = pageSizeForSr ? (currentPage - 1) * pageSizeForSr + 1 : 1;

            // Create table body
            const tbody = document.createElement("tbody");
            recordsToDisplay.forEach((record, index) => {
                const tr = document.createElement("tr");

                // Add default SR. NO. cell
                const tdSr = document.createElement("td");
                tdSr.textContent = startSrNo + index;
                tr.appendChild(tdSr);

                displayCols.forEach(col => {
                    const td = document.createElement("td");
                    let val = record[col.name];
                    if (val === undefined || val === null) {
                        val = "";
                    }
                    
                    if (col.uiType === "FileUpload" && val) {
                        td.innerHTML = '<a href="' + contextPath + val + '" target="_blank" style="color: var(--primary); text-decoration: underline; font-size: 0.9rem;">View File</a>';
                    } else if (col.uiType === "DateBox" || col.validation === "Date") {
                        td.textContent = formatDateForDisplay(val);
                    } else {
                        td.textContent = val;
                    }
                    tr.appendChild(td);
                });

                // Action cell
                const tdAction = document.createElement("td");
                tdAction.style.textAlign = "center";
                tdAction.innerHTML = '<button class="btn btn-primary btn-sm" style="padding: 0.35rem 0.75rem; font-size: 0.8rem; margin: 0;">Edit</button>';
                tdAction.querySelector("button").onclick = () => openEditForm(record);
                tr.appendChild(tdAction);

                tbody.appendChild(tr);
            });

            table.appendChild(tbody);
            container.appendChild(table);

            // Render pagination controls
            renderPaginationControls();
        }

        function renderPaginationControls() {
            const clientPaging = config.clientSidePaging === true;
            const serverPaging = config.serverSidePaging === true;
            const clientPageSize = config.clientSidePageSize || 200;
            const serverPageSize = config.serverSidePageSize || 1000;

            const hasPaging = clientPaging || serverPaging;
            const container = document.getElementById("pagination-controls");
            if (!hasPaging || totalRecords <= 0) {
                container.style.display = "none";
                return;
            }
            container.style.display = "flex";
            container.innerHTML = "";

            const pageSize = clientPaging ? clientPageSize : serverPageSize;
            const totalPages = Math.ceil(totalRecords / pageSize);

            if (totalPages <= 1) {
                container.innerHTML = 
                    '<div style="color: var(--text-secondary); font-size: 0.9rem; font-weight: 500;">' +
                        'Showing all ' + totalRecords + ' records' +
                    '</div>';
                return;
            }

            // 1. Info Label (e.g., Showing 1-200 of 1234 records)
            const startItem = (currentPage - 1) * pageSize + 1;
            const endItem = Math.min(currentPage * pageSize, totalRecords);
            const infoDiv = document.createElement("div");
            infoDiv.style.color = "var(--text-secondary)";
            infoDiv.style.fontSize = "0.9rem";
            infoDiv.style.fontWeight = "500";
            infoDiv.textContent = 'Showing ' + startItem + ' to ' + endItem + ' of ' + totalRecords + ' records';
            container.appendChild(infoDiv);

            // 2. Button container
            const btnContainer = document.createElement("div");
            btnContainer.style.display = "flex";
            btnContainer.style.gap = "0.35rem";
            btnContainer.style.alignItems = "center";

            // Helper to create page buttons
            function createPageBtn(label, targetPage, disabled = false, active = false) {
                const btn = document.createElement("button");
                btn.textContent = label;
                
                // Style button
                btn.style.padding = "0.4rem 0.75rem";
                btn.style.fontSize = "0.85rem";
                btn.style.fontWeight = "600";
                btn.style.borderRadius = "6px";
                btn.style.border = "1px solid var(--border)";
                btn.style.minWidth = "36px";
                btn.style.height = "36px";
                btn.style.display = "inline-flex";
                btn.style.alignItems = "center";
                btn.style.justifyContent = "center";
                btn.style.cursor = disabled ? "not-allowed" : "pointer";
                btn.style.transition = "all 0.2s ease";
                
                if (active) {
                    btn.style.background = "var(--primary)";
                    btn.style.color = "white";
                    btn.style.borderColor = "var(--primary)";
                } else if (disabled) {
                    btn.style.background = "transparent";
                    btn.style.color = "var(--text-muted)";
                    btn.style.borderColor = "var(--border)";
                    btn.style.opacity = "0.5";
                } else {
                    btn.style.background = "white";
                    btn.style.color = "var(--primary)";
                    
                    btn.onmouseenter = () => {
                        btn.style.background = "var(--primary-light)";
                    };
                    btn.onmouseleave = () => {
                        btn.style.background = "white";
                    };
                }

                if (!disabled && !active) {
                    btn.onclick = () => changePage(targetPage);
                }

                return btn;
            }

            // Prev Button
            btnContainer.appendChild(createPageBtn("←", currentPage - 1, currentPage === 1));

            // Page numbers
            let startPage, endPage;
            if (clientPaging && serverPaging) {
                const K = Math.floor(serverPageSize / clientPageSize);
                startPage = (currentServerPage - 1) * K + 1;
                endPage = Math.min(currentServerPage * K, totalPages);
            } else {
                const maxVisibleButtons = 5;
                startPage = Math.max(1, currentPage - Math.floor(maxVisibleButtons / 2));
                endPage = Math.min(totalPages, startPage + maxVisibleButtons - 1);

                if (endPage - startPage + 1 < maxVisibleButtons) {
                    startPage = Math.max(1, endPage - maxVisibleButtons + 1);
                }
            }

            if (!clientPaging || !serverPaging) {
                if (startPage > 1) {
                    btnContainer.appendChild(createPageBtn("1", 1));
                    if (startPage > 2) {
                        const dots = document.createElement("span");
                        dots.textContent = "...";
                        dots.style.color = "var(--text-muted)";
                        dots.style.padding = "0 0.25rem";
                        btnContainer.appendChild(dots);
                    }
                }
            }

            for (let i = startPage; i <= endPage; i++) {
                btnContainer.appendChild(createPageBtn(i.toString(), i, false, i === currentPage));
            }

            if (!clientPaging || !serverPaging) {
                if (endPage < totalPages) {
                    if (endPage < totalPages - 1) {
                        const dots = document.createElement("span");
                        dots.textContent = "...";
                        dots.style.color = "var(--text-muted)";
                        dots.style.padding = "0 0.25rem";
                        btnContainer.appendChild(dots);
                    }
                    btnContainer.appendChild(createPageBtn(totalPages.toString(), totalPages));
                }
            }

            // Next Button
            btnContainer.appendChild(createPageBtn("→", currentPage + 1, currentPage === totalPages));

            container.appendChild(btnContainer);
        }

        function changePage(targetPage) {
            const serverPaging = config.serverSidePaging === true;
            const clientPaging = config.clientSidePaging === true;
            const clientPageSize = config.clientSidePageSize || 200;
            const serverPageSize = config.serverSidePageSize || 1000;

            let requestedServerPage = 1;
            if (serverPaging) {
                if (clientPaging) {
                    requestedServerPage = Math.ceil((targetPage * clientPageSize) / serverPageSize);
                } else {
                    requestedServerPage = targetPage;
                }
            }

            if (serverPaging && requestedServerPage !== currentServerPage) {
                performSearch(null, targetPage);
            } else {
                currentPage = targetPage;
                renderResultsTable();
            }
        }

        // 3. Render Edit Fields dynamically from JSON configurations
        function openEditForm(record) {
            activeRecord = record;
            document.getElementById("search-section").style.display = "none";
            document.getElementById("results-section").style.display = "none";
            document.getElementById("edit-section").style.display = "block";
            updateBackButtonVisibility();

            const container = document.getElementById("edit-fields-container");
            container.innerHTML = "";
            container.className = "config-table-container";
            document.getElementById("edit-alert-container").innerHTML = "";

            const table = document.createElement("table");
            table.className = "config-table";

            const tbody = document.createElement("tbody");

            config.columns.forEach(col => {
                if (col.visible === false) {
                    return;
                }
                const tr = document.createElement("tr");

                // Label cell (Left column)
                const tdLabel = document.createElement("td");
                tdLabel.style.fontWeight = "600";
                tdLabel.style.width = "30%";
                tdLabel.style.verticalAlign = "middle";
                tdLabel.textContent = col.name.toUpperCase();

                // Add visual indicator for required and editable fields
                if (col.editable && col.required) {
                    tdLabel.innerHTML = col.name.toUpperCase() + ' <span style="color: var(--error); font-weight: bold; margin-left: 0.25rem;">*</span>';
                }

                // Fetch original record value
                const value = record[col.name] !== undefined ? record[col.name] : "";

                // Field input element per uiType
                let inputElement;

                if (col.uiType === "Dropdown" && col.apiSource) {
                    const select = document.createElement("select");
                    select.className = "form-control edit-input";
                    select.name = col.name;
                    select.style.width = "100%";
                    select.innerHTML = '<option value="">-- Select Option --</option>';
                    fetchDropdownOptions(col.apiSource, select, value);
                    inputElement = select;
                } else if (col.uiType === "TextArea") {
                    const textarea = document.createElement("textarea");
                    textarea.className = "form-control edit-input";
                    textarea.name = col.name;
                    textarea.style.width = "100%";
                    textarea.rows = 4;
                    textarea.value = value;
                    inputElement = textarea;
                } else if (col.uiType === "DateBox") {
                    const input = document.createElement("input");
                    input.type = "text";
                    input.className = "form-control edit-input";
                    input.name = col.name;
                    input.style.width = "100%";
                    input.placeholder = "DD-MM-YYYY";
                    input.value = formatDateForDisplay(value);
                    inputElement = input;
                } else if (col.uiType === "FileUpload") {
                    const wrapper = document.createElement("div");
                    
                    let fileInfoHtml = '';
                    if (value) {
                        fileInfoHtml = '<div style="margin-bottom: 0.5rem;"><a href="' + contextPath + value + '" target="_blank" class="navbar-link" style="color: var(--primary); text-decoration: underline; font-size: 0.9rem;" id="file-link-' + col.name + '">View Current File</a></div>';
                    } else {
                        fileInfoHtml = '<div style="margin-bottom: 0.5rem; font-size: 0.9rem; color: var(--muted);" id="file-link-' + col.name + '">No file uploaded</div>';
                    }
                    
                    wrapper.innerHTML = fileInfoHtml + 
                        '<div style="display: flex; gap: 1rem; align-items: center;">' +
                            '<input type="hidden" class="edit-input" name="' + col.name + '" id="file-hidden-' + col.name + '" value="' + value + '">' +
                            '<input type="file" id="file-input-' + col.name + '" style="display: none;" onchange="uploadFile(this, \'' + col.name + '\')">' +
                            '<button type="button" class="btn btn-outline btn-sm" onclick="document.getElementById(\'file-input-' + col.name + '\').click()"' + (col.editable ? '' : ' disabled') + '>Choose & Upload File</button>' +
                            '<div id="file-status-' + col.name + '" style="font-size: 0.9rem; color: var(--muted);"></div>' +
                        '</div>';
                    inputElement = wrapper;
                } else {
                    // TextBox default
                    const input = document.createElement("input");
                    input.type = "text";
                    input.className = "form-control edit-input";
                    input.name = col.name;
                    input.style.width = "100%";
                    if (col.validation === "Date") {
                        input.placeholder = "DD-MM-YYYY";
                        input.value = formatDateForDisplay(value);
                    } else {
                        input.value = value;
                    }
                    inputElement = input;
                }

                // Server-side + client-side lock for non-editable columns
                if (!col.editable) {
                    if (inputElement.tagName === "INPUT" || inputElement.tagName === "SELECT" || inputElement.tagName === "TEXTAREA") {
                        inputElement.disabled = true;
                    } else {
                        const hiddenInput = inputElement.querySelector("input[type='hidden']");
                        if (hiddenInput) hiddenInput.disabled = true;
                    }
                    // Provide a visual lock icon indicator
                    tdLabel.innerHTML = col.name.toUpperCase() + ' <span style="font-size: 0.8rem; color: var(--muted); font-weight: normal; margin-left: 0.25rem;">🔒 Locked</span>';
                }

                const tdInput = document.createElement("td");
                tdInput.appendChild(inputElement);
                tr.appendChild(tdLabel);
                tr.appendChild(tdInput);
                tbody.appendChild(tr);
            });

            table.appendChild(tbody);
            container.appendChild(table);
        }

        // 4. Save modifications (dynamic update)
        async function saveRecord(e) {
            e.preventDefault();
            const alertContainer = document.getElementById("edit-alert-container");
            alertContainer.innerHTML = "";

            const editForm = document.getElementById("edit-form");
            const inputs = editForm.querySelectorAll(".edit-input");

            for (let i = 0; i < config.columns.length; i++) {
                const col = config.columns[i];
                if (col.visible === false) {
                    continue;
                }
                if (col.editable) {
                    // Find actual input element (select, textarea, or input)
                    const input = editForm.querySelector('[name="' + col.name + '"]');
                    const val = input ? input.value : "";
                    const valStr = val.trim();

                    // Remove previous error state
                    if (input) {
                        input.classList.remove("input-error");
                    }

                    // Required Validation
                    if (col.required && valStr === "") {
                        alertContainer.innerHTML = 
                            '<div class="alert alert-danger">' +
                                'Field \'' + col.name.toUpperCase() + '\' is required and cannot be empty.' +
                            '</div>';
                        if (input) {
                            input.focus();
                            input.classList.add("input-error");
                        }
                        return;
                    }

                    // Validation Type Check (if value is provided)
                    if (valStr !== "") {
                        const vType = col.validation;
                        if (vType === "Numeric") {
                            if (!/^-?\d+(\.\d+)?$/.test(valStr)) {
                                alertContainer.innerHTML = 
                                    '<div class="alert alert-danger">' +
                                        'Field \'' + col.name.toUpperCase() + '\' must be a numeric value.' +
                                    '</div>';
                                if (input) {
                                    input.focus();
                                    input.classList.add("input-error");
                                }
                                return;
                            }
                        } else if (vType === "Email") {
                            if (!/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/.test(valStr)) {
                                alertContainer.innerHTML = 
                                    '<div class="alert alert-danger">' +
                                        'Field \'' + col.name.toUpperCase() + '\' must be a valid email address.' +
                                    '</div>';
                                if (input) {
                                    input.focus();
                                    input.classList.add("input-error");
                                }
                                return;
                            }
                        } else if (vType === "Date") {
                            if (!/^\d{2}-\d{2}-\d{4}$/.test(valStr)) {
                                alertContainer.innerHTML = 
                                    '<div class="alert alert-danger">' +
                                        'Field \'' + col.name.toUpperCase() + '\' must be a valid date format (DD-MM-YYYY).' +
                                    '</div>';
                                if (input) {
                                    input.focus();
                                    input.classList.add("input-error");
                                }
                                return;
                            }
                        } else if (vType === "Regex") {
                            if (col.regex) {
                                try {
                                    const rx = new RegExp(col.regex);
                                    if (!rx.test(valStr)) {
                                        alertContainer.innerHTML = 
                                            '<div class="alert alert-danger">' +
                                                'Field \'' + col.name.toUpperCase() + '\' does not match the required format.' +
                                            '</div>';
                                        if (input) {
                                            input.focus();
                                            input.classList.add("input-error");
                                        }
                                        return;
                                    }
                                } catch (e) {
                                    console.error("Invalid regex format:", col.regex);
                                }
                            }
                        } else if (vType === "Range") {
                            if (!/^-?\d+(\.\d+)?$/.test(valStr)) {
                                alertContainer.innerHTML = 
                                    '<div class="alert alert-danger">' +
                                        'Field \'' + col.name.toUpperCase() + '\' must be a numeric value.' +
                                    '</div>';
                                if (input) {
                                    input.focus();
                                    input.classList.add("input-error");
                                }
                                return;
                            }
                            const num = parseFloat(valStr);
                            if (col.min !== undefined && col.min !== null && num < col.min) {
                                alertContainer.innerHTML = 
                                    '<div class="alert alert-danger">' +
                                        'Field \'' + col.name.toUpperCase() + '\' must be at least ' + col.min + '.' +
                                    '</div>';
                                if (input) {
                                    input.focus();
                                    input.classList.add("input-error");
                                }
                                return;
                            }
                            if (col.max !== undefined && col.max !== null && num > col.max) {
                                alertContainer.innerHTML = 
                                    '<div class="alert alert-danger">' +
                                        'Field \'' + col.name.toUpperCase() + '\' must be at most ' + col.max + '.' +
                                    '</div>';
                                if (input) {
                                    input.focus();
                                    input.classList.add("input-error");
                                }
                                return;
                            }
                        }
                    }
                }
            }
            
            // Build body including:
            // 1. Whitelisted editable parameters
            // 2. The matching search key criteria (derived from activeRecord)
            const payload = {};

            // Always include primary key to guarantee update accuracy
            if (primaryKey && activeRecord && activeRecord[primaryKey] !== undefined) {
                payload[primaryKey] = activeRecord[primaryKey];
            }

            // Add original record keys for WHERE clause verification (search keys)
            config.columns.forEach(col => {
                if (col.searchKey) {
                    payload[col.name] = activeRecord[col.name];
                }
            });

            // Add submitted editable inputs
            inputs.forEach(input => {
                // Read value only if input is enabled (editable = true)
                if (!input.disabled) {
                    let val = input.value;
                    const col = config.columns.find(c => c.name === input.name);
                    if (col && (col.uiType === "DateBox" || col.validation === "Date")) {
                        val = formatDateForBackend(val);
                    }
                    payload[input.name] = val;
                }
            });

            try {
                const response = await fetch(contextPath + "/apps/dccmf/user/api/update?token=" + token, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify(payload)
                });
                const data = await response.json();

                if (data.success) {
                    alertContainer.innerHTML = 
                        '<div class="alert alert-success">' +
                            'Record saved successfully!' +
                        '</div>';
                    // Update current activeRecord in memory
                    for (const [key, val] of Object.entries(payload)) {
                        activeRecord[key] = val;
                    }
                    // Refresh search results in background to ensure DOM table and dropdowns sync
                    refreshSearchResultsInBackground();
                } else {
                    alertContainer.innerHTML = 
                        '<div class="alert alert-danger">' +
                            'Save failed: ' + data.message +
                        '</div>';
                }
            } catch (err) {
                console.error(err);
                alertContainer.innerHTML = 
                    '<div class="alert alert-danger">' +
                        'Network error occurred while saving the record.' +
                    '</div>';
            }
        }

        async function uploadFile(fileInput, columnName) {
            const file = fileInput.files[0];
            if (!file) return;

            const statusEl = document.getElementById("file-status-" + columnName);
            
            // Resolve constraints from config columns
            const col = config.columns.find(c => c.name === columnName);
            if (col) {
                const maxSizeMb = col.maxSizeMb !== undefined ? col.maxSizeMb : 5;
                const allowedExtensions = col.allowedExtensions !== undefined ? col.allowedExtensions : "png,jpg,pdf,zip";
                
                // 1. Size Validation
                const maxSizeBytes = maxSizeMb * 1024 * 1024;
                if (file.size > maxSizeBytes) {
                    statusEl.textContent = "Upload failed: File size exceeds the max allowed limit of " + maxSizeMb + " MB.";
                    statusEl.style.color = "var(--error)";
                    fileInput.value = ""; // reset input
                    return;
                }
                
                // 2. Extension Validation
                const ext = file.name.split('.').pop().toLowerCase();
                const allowedList = allowedExtensions.split(',').map(s => s.trim().toLowerCase()).filter(s => s !== "");
                if (allowedList.length > 0 && !allowedList.includes(ext)) {
                    statusEl.textContent = "Upload failed: Invalid file type. Allowed formats: " + allowedExtensions.toUpperCase() + ".";
                    statusEl.style.color = "var(--error)";
                    fileInput.value = ""; // reset input
                    return;
                }
            }

            statusEl.innerHTML = '<div class="spinner" style="width: 16px; height: 16px; display: inline-block; vertical-align: middle; margin-right: 8px;"></div> Uploading...';

            const formData = new FormData();
            formData.append("file", file);

            try {
                const response = await fetch(contextPath + "/apps/dccmf/user/api/upload?token=" + token + "&column=" + encodeURIComponent(columnName), {
                    method: "POST",
                    body: formData
                });
                const data = await response.json();

                if (data.success) {
                    document.getElementById("file-hidden-" + columnName).value = data.filePath;
                    const linkEl = document.getElementById("file-link-" + columnName);
                    linkEl.innerHTML = '<a href="' + contextPath + data.filePath + '" target="_blank" class="navbar-link" style="color: var(--primary); text-decoration: underline; font-size: 0.9rem;">View Uploaded File</a>';
                    statusEl.textContent = "Upload successful!";
                    statusEl.style.color = "var(--success)";
                } else {
                    statusEl.textContent = "Upload failed: " + data.message;
                    statusEl.style.color = "var(--error)";
                }
            } catch (err) {
                console.error(err);
                statusEl.textContent = "Network error during upload.";
                statusEl.style.color = "var(--error)";
            }
        }

        function downloadCSV() {
            if (!searchResultsList || searchResultsList.length === 0) {
                alert("No search results to download.");
                return;
            }

            // Always put primary key first
            const csvCols = [];
            const pkCol = config.columns.find(col => col.name.toLowerCase() === primaryKey.toLowerCase());
            if (pkCol) {
                csvCols.push(pkCol);
            } else {
                csvCols.push({ name: primaryKey });
            }

            // Append all visible columns (avoiding duplication of the primary key)
            config.columns.forEach(col => {
                if (col.visible !== false) {
                    if (!csvCols.some(c => c.name.toLowerCase() === col.name.toLowerCase())) {
                        csvCols.push(col);
                    }
                }
            });
            const headers = ["SR. NO.", ...csvCols.map(col => col.name)];

            // Build CSV content
            let csvContent = headers.join(",") + "\n";

            searchResultsList.forEach((record, idx) => {
                const row = csvCols.map(col => {
                    let val = record[col.name];
                    if (val === undefined || val === null) {
                        val = "";
                    }
                    // Escape double quotes and wrap in quotes if contains comma/newline/quotes
                    val = String(val).replace(/"/g, '""');
                    if (val.includes(",") || val.includes("\n") || val.includes('"')) {
                        val = '"' + val + '"';
                    }
                    return val;
                });
                csvContent += [idx + 1, ...row].join(",") + "\n";
            });

            // Create dynamic download link
            const blob = new Blob([csvContent], { type: "text/csv;charset=utf-8;" });
            const url = URL.createObjectURL(blob);
            const link = document.createElement("a");
            link.setAttribute("href", url);
            link.setAttribute("download", (config.table || "records") + "_records.csv");
            link.style.visibility = "hidden";
            document.body.appendChild(link);
            link.click();
            document.body.removeChild(link);
        }

        function triggerCSVUpload() {
            document.getElementById("csv-file-input").click();
        }

        async function handleCSVUpload(event) {
            const file = event.target.files[0];
            if (!file) return;

            const reader = new FileReader();
            reader.onload = async function(e) {
                const text = e.target.result;
                const rows = parseCSVText(text);
                if (rows.length < 2) {
                    alert("The uploaded CSV file is empty or invalid.");
                    return;
                }

                const headers = rows[0].map(h => h.trim().toLowerCase());
                
                // Verify that primary key is present in the CSV headers
                const pkIndex = headers.indexOf(primaryKey.toLowerCase());
                if (pkIndex === -1) {
                    alert('Primary key column "' + primaryKey + '" is missing in the CSV headers.');
                    event.target.value = "";
                    return;
                }

                const rowObjects = [];
                for (let i = 1; i < rows.length; i++) {
                    const rowData = rows[i];
                    if (rowData.length === 0 || (rowData.length === 1 && rowData[0] === "")) {
                        continue;
                    }
                    
                    const rowDataObj = {};
                    headers.forEach((header, index) => {
                        if (index < rowData.length) {
                            const val = rowData[index];
                            rowDataObj[header] = (val !== undefined && val !== null) ? val.trim() : "";
                        }
                    });
                    
                    rowObjects.push({
                        rowIndex: i,
                        data: rowDataObj
                    });
                }

                try {
                    const response = await fetch(contextPath + "/apps/dccmf/user/api/bulkUpdate?token=" + token, {
                        method: "POST",
                        headers: { "Content-Type": "application/json" },
                        body: JSON.stringify({ rows: rowObjects })
                    });
                    
                    const data = await response.json();
                    
                    if (data.success) {
                        let resultMsg = 'CSV processing complete!\nSuccessfully updated: ' + data.successCount + ' records.';
                        if (data.failCount > 0) {
                            resultMsg += '\nFailed to update: ' + data.failCount + ' records.\nDetails:\n' + data.errors.slice(0, 10).join("\n");
                            if (data.errors.length > 10) {
                                resultMsg += '\n... and ' + (data.errors.length - 10) + ' more errors.';
                            }
                        }
                        if (data.warnings && data.warnings.length > 0) {
                            resultMsg += '\n\nNotice:\n' + data.warnings.join("\n");
                        }
                        alert(resultMsg);
                    } else {
                        alert("CSV Upload Error: " + data.message);
                    }
                } catch (err) {
                    console.error(err);
                    alert("Network error occurred during bulk CSV upload.");
                }
                
                event.target.value = "";
                // Re-run search to refresh results table with updated values
                performSearch();
            };
            reader.readAsText(file);
        }

        function parseCSVText(text) {
            const lines = [];
            let row = [""];
            let inQuotes = false;

            for (let i = 0; i < text.length; i++) {
                const c = text[i];
                const next = text[i+1];

                if (c === '"') {
                    if (inQuotes && next === '"') {
                        row[row.length - 1] += '"';
                        i++;
                    } else {
                        inQuotes = !inQuotes;
                    }
                } else if (c === ',' && !inQuotes) {
                    row.push("");
                } else if ((c === '\r' || c === '\n') && !inQuotes) {
                    if (c === '\r' && next === '\n') {
                        i++;
                    }
                    lines.push(row);
                    row = [""];
                } else {
                    row[row.length - 1] += c;
                }
            }
            if (row.length > 1 || row[0] !== "") {
                lines.push(row);
            }
            return lines;
        }

        function backToSearch() {
            document.getElementById("search-section").style.display = "block";
            document.getElementById("results-section").style.display = "none";
            document.getElementById("edit-section").style.display = "none";
            document.getElementById("search-alert-container").innerHTML = "";
            updateBackButtonVisibility();
        }

        async function refreshSearchResultsInBackground() {
            const searchForm = document.getElementById("search-form");
            const inputs = searchForm.querySelectorAll(".search-input");
            const criteria = {};

            inputs.forEach(input => {
                if (input.value && input.value.trim() !== "") {
                    criteria[input.name] = input.value;
                }
            });

            if (Object.keys(criteria).length === 0) return;

            const serverPaging = config.serverSidePaging === true;
            const clientPaging = config.clientSidePaging === true;
            const clientPageSize = config.clientSidePageSize || 200;
            const serverPageSize = config.serverSidePageSize || 1000;

            let requestedServerPage = 1;
            if (serverPaging) {
                if (clientPaging) {
                    requestedServerPage = Math.ceil((currentPage * clientPageSize) / serverPageSize);
                } else {
                    requestedServerPage = currentPage;
                }
                criteria.page = requestedServerPage;
            }

            try {
                const response = await fetch(contextPath + "/apps/dccmf/user/api/search?token=" + token, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify(criteria)
                });
                const data = await response.json();

                if (data.success) {
                    searchResultsList = data.data || data.records || [];
                    totalRecords = data.totalCount !== undefined ? data.totalCount : searchResultsList.length;
                    if (serverPaging) {
                        currentServerPage = requestedServerPage;
                    }
                    renderResultsTable();
                    renderSearchForm();
                }
            } catch (err) {
                console.error("Failed to refresh search results in background:", err);
            }
        }

        function backToResults() {
            if (searchResultsList.length <= 1) {
                backToSearch();
            } else {
                showResultsList();
            }
        }

        function updateBackButtonVisibility() {
            const searchSection = document.getElementById("search-section");
            const backNav = document.getElementById("back-nav-container");
            if (searchSection.style.display === "none") {
                backNav.style.display = "block";
            } else {
                backNav.style.display = "none";
            }
        }

        function handleBackNavigation() {
            const editSection = document.getElementById("edit-section");
            const resultsSection = document.getElementById("results-section");

            if (editSection.style.display === "block") {
                backToResults();
            } else if (resultsSection.style.display === "block") {
                backToSearch();
            }
        }
    </script>
</body>
</html>
