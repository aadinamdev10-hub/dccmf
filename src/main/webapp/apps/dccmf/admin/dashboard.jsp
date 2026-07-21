<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ page import="apps.dccmf.util.ConfigService" %>
<%@ page import="java.util.List" %>
<%
    // =========================================================================
    // DCCMF ADMIN CONFIGURATION DASHBOARD PAGE
    // File: /apps/dccmf/admin/dashboard.jsp
    // Description: Admin panel for selecting databases/tables, defining columns
    //              mapping metadata configuration and dynamic validation setups.
    // =========================================================================

    try {
        // Fetch list of databases in the system to populate database selector dropdown
        List<String> databases = new ConfigService().getDatabases();
        request.setAttribute("databases", databases);
    } catch (Exception e) {
        // Handle database list fetch failures gracefully
        request.setAttribute("dbError", "Failed to retrieve databases: " + e.getMessage());
        e.printStackTrace();
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Admin Dashboard - DCCMF</title>
    <link rel="stylesheet" href="/apps/apps/dccmf/css/style.css">
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
            <li><a href="/apps/apps/dccmf/admin/dashboard.jsp" class="navbar-link active">Configure Tables</a></li>
            <li><a href="/apps/apps/dccmf/admin/generateApi.jsp" class="navbar-link">Generate API</a></li>
            <li><a href="/apps/apps/dccmf/admin/manageLinks.jsp" class="navbar-link">Manage Links</a></li>
            <li>
                <a href="/apps/apps/dccmf/admin/login.jsp?action=logout" class="btn-logout" style="text-decoration: none; display: inline-block;">Logout</a>
            </li>
        </ul>
    </nav>

    <!-- Main Container -->
    <div class="container">
        <div class="page-header">
            <h2>Data Collection Setup</h2>
            <p>Select a database table to define searchable fields, editable columns, and validation parameters.</p>
        </div>

        <div class="glass-card" style="margin-bottom: 2rem;">
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
                    <select id="table-select" class="form-control" onchange="loadColumns()" disabled>
                        <option value="">-- Select Database First --</option>
                    </select>
                </div>
            </div>
        </div>

        <!-- Configuration Grid (Loaded Dynamically) -->
        <div id="config-card" class="glass-card" style="display: none;">
            <h3 id="config-title" style="margin-bottom: 1rem; border-bottom: 1px solid var(--border-color); padding-bottom: 0.75rem;"></h3>
            
            <!-- Paging Configuration -->
            <div class="paging-config-section" style="margin-bottom: 2rem; padding: 1.25rem; background: var(--primary-light); border-radius: var(--radius); border: 1px solid var(--border-color);">
                <h4 style="margin-bottom: 1rem; color: var(--primary); font-size: 1.1rem; display: flex; align-items: center; gap: 0.5rem;">
                    Pagination & Paging Settings
                </h4>
                <div style="display: grid; grid-template-columns: repeat(auto-fit, minmax(280px, 1fr)); gap: 1.5rem;">
                    <!-- Client-Side Paging -->
                    <div style="display: flex; flex-direction: column; gap: 0.5rem; padding: 0.5rem; border-right: 1px solid var(--border);">
                        <label style="display: flex; align-items: center; gap: 0.5rem; font-weight: 600; color: var(--text-primary); cursor: pointer; font-size: 0.95rem;">
                            <input type="checkbox" id="client-side-paging-checkbox" onchange="togglePagingInputs()" style="width: 18px; height: 18px; accent-color: var(--primary);">
                            Enable Client-Side Paging (yes/no)
                        </label>
                        <div id="client-size-container" style="margin-top: 0.5rem; display: none;">
                            <label for="client-page-size-input" class="form-label" style="font-size: 0.85rem; font-weight: 500; color: var(--text-secondary);">Client Page Size (e.g. 200)</label>
                            <input type="number" id="client-page-size-input" class="form-control" value="200" min="1" style="max-width: 150px; margin-top: 0.25rem;">
                        </div>
                    </div>
                    
                    <!-- Server-Side Paging -->
                    <div style="display: flex; flex-direction: column; gap: 0.5rem; padding: 0.5rem;">
                        <label style="display: flex; align-items: center; gap: 0.5rem; font-weight: 600; color: var(--text-primary); cursor: pointer; font-size: 0.95rem;">
                            <input type="checkbox" id="server-side-paging-checkbox" onchange="togglePagingInputs()" style="width: 18px; height: 18px; accent-color: var(--primary);">
                            Enable Server-Side Paging (yes/no)
                        </label>
                        <div id="server-size-container" style="margin-top: 0.5rem; display: none;">
                            <label for="server-page-size-input" class="form-label" style="font-size: 0.85rem; font-weight: 500; color: var(--text-secondary);">Server Page Size (e.g. 1000)</label>
                            <input type="number" id="server-page-size-input" class="form-control" value="1000" min="1" style="max-width: 150px; margin-top: 0.25rem;">
                        </div>
                    </div>
                </div>
            </div>

            <div class="config-table-container">
                <table class="config-table">
                    <thead>
                        <tr>
                            <th>Column Name</th>
                            <th>Search Key</th>
                            <th>Editable</th>
                            <th>Visible</th>
                            <th>Required</th>
                            <th>UI Type</th>
                            <th>API Lookup Source / URL</th>
                            <th>Validation Rule</th>
                        </tr>
                    </thead>
                    <tbody id="columns-tbody">
                        <!-- Filled by JavaScript -->
                    </tbody>
                </table>
            </div>



            <div style="margin-top: 2rem; display: flex; justify-content: flex-end; gap: 1rem;">
                <div id="save-status-msg" style="align-self: center; font-size: 0.95rem; font-weight: 500;"></div>
                <button class="btn btn-secondary" onclick="resetConfigGrid()">Cancel</button>
                <button class="btn btn-primary" onclick="saveConfiguration()">Save Schema Configuration</button>
            </div>
        </div>
    </div>

    <!-- Link Generation Modal -->
    <div id="link-modal" class="modal">
        <div class="glass-card modal-content">
            <h3 style="margin-bottom: 1rem; color: var(--secondary-color);">Link Generated Successfully</h3>
            <p style="color: var(--text-secondary); margin-bottom: 1.5rem;">
                The shareable link has been registered. You can copy this link and share it with users to collect or manage record data.
            </p>

            <div class="copy-box" style="margin-bottom: 1.5rem;">
                <input type="text" id="share-link-input" class="copy-input" readonly>
                <button class="btn btn-accent" style="padding: 0.5rem 1rem;" onclick="copyLink()">Copy URL</button>
            </div>

            <div style="margin-top: 2rem; text-align: right;">
                <button class="btn btn-secondary" onclick="closeModal()">Close Panel</button>
            </div>
        </div>
    </div>

    <!-- File Upload Constraints Modal -->
    <div id="constraints-modal" class="modal">
        <div class="glass-card modal-content" style="max-width: 480px;">
            <h3 style="margin-bottom: 1rem; color: var(--secondary-color); display: flex; align-items: center; gap: 0.5rem;">
                📁 File Upload Constraints
            </h3>
            <p id="constraints-modal-subtitle" style="color: var(--text-secondary); margin-bottom: 1.5rem; font-size: 0.9rem;">
                Configure file size and format constraints for column: <strong id="constraints-modal-colname" style="color: var(--primary);"></strong>
            </p>
            
            <div class="form-group" style="margin-bottom: 1.25rem;">
                <label for="modal-max-size" class="form-label" style="font-weight: 600;">Max Allowed Size (MB)</label>
                <input type="number" id="modal-max-size" class="form-control" min="1" value="5" style="width: 100%;">
            </div>
            
            <div class="form-group" style="margin-bottom: 2rem;">
                <label class="form-label" style="font-weight: 600; margin-bottom: 0.75rem; display: block;">Accepted Mime Types</label>
                <div style="display: grid; grid-template-columns: repeat(2, 1fr); gap: 0.75rem;">
                    <label style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer; font-size: 0.95rem; font-weight: normal; color: var(--text-primary);">
                        <input type="checkbox" id="modal-mime-png" value="png" style="width: 16px; height: 16px; accent-color: var(--primary);"> PNG (.png)
                    </label>
                    <label style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer; font-size: 0.95rem; font-weight: normal; color: var(--text-primary);">
                        <input type="checkbox" id="modal-mime-jpg" value="jpg" style="width: 16px; height: 16px; accent-color: var(--primary);"> JPG (.jpg)
                    </label>
                    <label style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer; font-size: 0.95rem; font-weight: normal; color: var(--text-primary);">
                        <input type="checkbox" id="modal-mime-pdf" value="pdf" style="width: 16px; height: 16px; accent-color: var(--primary);"> PDF (.pdf)
                    </label>
                    <label style="display: flex; align-items: center; gap: 0.5rem; cursor: pointer; font-size: 0.95rem; font-weight: normal; color: var(--text-primary);">
                        <input type="checkbox" id="modal-mime-zip" value="zip" style="width: 16px; height: 16px; accent-color: var(--primary);"> ZIP (.zip)
                    </label>
                </div>
            </div>
            
            <div style="display: flex; justify-content: flex-end; gap: 1rem; margin-top: 2rem;">
                <button class="btn btn-secondary" onclick="closeConstraintsModal()">Cancel</button>
                <button class="btn btn-primary" onclick="saveConstraintsFromModal()">Save Constraints</button>
            </div>
        </div>
    </div>

    <footer>
        <p>&copy; 2026 Dynamic Data Collection Framework (DCCMF). All rights reserved.</p>
    </footer>

    <!-- JavaScript logic -->
    <script>
        let currentConfigId = null;
        const contextPath = "/apps";
        
        // Check for configId parameter to identify edit mode (Case B)
        const urlParams = new URLSearchParams(window.location.search);
        const editConfigId = urlParams.get('configId') || null;



        function togglePagingInputs() {
            const clientChecked = document.getElementById("client-side-paging-checkbox").checked;
            const serverChecked = document.getElementById("server-side-paging-checkbox").checked;
            document.getElementById("client-size-container").style.display = clientChecked ? "block" : "none";
            document.getElementById("server-size-container").style.display = serverChecked ? "block" : "none";
        }

        async function loadTables() {
            const dbSelect = document.getElementById("db-select");
            const tableSelect = document.getElementById("table-select");
            const configCard = document.getElementById("config-card");
            
            configCard.style.display = "none";
            const db = dbSelect.value;

            if (!db) {
                tableSelect.disabled = true;
                tableSelect.innerHTML = "<option value=''>-- Select Database First --</option>";
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
                alert("Failed to communicate with tables api.");
            }
        }

        async function loadColumns() {
            const db = document.getElementById("db-select").value;
            const table = document.getElementById("table-select").value;
            const configCard = document.getElementById("config-card");
            const tbody = document.getElementById("columns-tbody");
            const title = document.getElementById("config-title");

            if (!table) {
                configCard.style.display = "none";
                return;
            }

            title.textContent = "Configuring: " + db + "." + table;
            tbody.innerHTML = '<tr><td colspan="5" style="text-align: center;"><div class="spinner" style="margin: 20px auto;"></div></td></tr>';
            configCard.style.display = "block";

            try {
                const response = await fetch(contextPath + "/apps/dccmf/admin/api/columns?db=" + encodeURIComponent(db) + "&table=" + encodeURIComponent(table));
                const data = await response.json();

                if (data.success) {
                    tbody.innerHTML = "";
                    const config = data.config;
                    currentConfigId = config.configId || null;
                    
                    // Populate Paging configuration fields
                    document.getElementById("client-side-paging-checkbox").checked = config.clientSidePaging === true;
                    document.getElementById("client-page-size-input").value = config.clientSidePageSize !== undefined ? config.clientSidePageSize : 200;
                    document.getElementById("server-side-paging-checkbox").checked = config.serverSidePaging === true;
                    document.getElementById("server-page-size-input").value = config.serverSidePageSize !== undefined ? config.serverSidePageSize : 1000;
                    togglePagingInputs();

                    config.columns.forEach(col => {
                        const tr = document.createElement("tr");
                        tr.dataset.columnName = col.name;
                        tr.dataset.maxSizeMb = col.maxSizeMb !== undefined ? col.maxSizeMb : 5;
                        tr.dataset.allowedExtensions = col.allowedExtensions !== undefined ? col.allowedExtensions : "png,jpg,pdf,zip";

                        // Column Name Label
                        const tdName = document.createElement("td");
                        tdName.innerHTML = "<strong>" + col.name + "</strong>";
                        tr.appendChild(tdName);

                        // Search Key Toggle
                        const tdSearch = document.createElement("td");
                        tdSearch.innerHTML = 
                            '<label class="toggle-switch">' +
                                '<input type="checkbox" class="col-search" ' + (col.searchKey ? 'checked' : '') + '>' +
                                '<span class="slider"></span>' +
                            '</label>';
                        tr.appendChild(tdSearch);

                        // Editable Toggle
                        const tdEditable = document.createElement("td");
                        tdEditable.innerHTML = 
                            '<label class="toggle-switch">' +
                                '<input type="checkbox" class="col-editable" ' + (col.editable ? 'checked' : '') + '>' +
                                '<span class="slider"></span>' +
                            '</label>';
                        tr.appendChild(tdEditable);

                        // Visible Toggle
                        const tdVisible = document.createElement("td");
                        const isVisibleVal = (col.visible !== undefined && col.visible !== null) ? col.visible : true;
                        tdVisible.innerHTML = 
                            '<label class="toggle-switch">' +
                                '<input type="checkbox" class="col-visible" ' + (isVisibleVal ? 'checked' : '') + '>' +
                                '<span class="slider"></span>' +
                            '</label>';
                        tr.appendChild(tdVisible);

                        // Required checkbox toggle (MOVED BEFORE UI TYPE)
                        const tdRequired = document.createElement("td");
                        tdRequired.innerHTML = 
                            '<label class="toggle-switch">' +
                                '<input type="checkbox" class="col-required" ' + (col.required ? 'checked' : '') + '>' +
                                '<span class="slider"></span>' +
                            '</label>';
                        tr.appendChild(tdRequired);

                        // UI Type Selector
                        const tdUi = document.createElement("td");
                        const uiTypes = ["TextBox", "TextArea", "DateBox", "FileUpload", "Dropdown"];
                        let selectHtml = '<div style="display: flex; flex-direction: column; align-items: flex-start; gap: 0.25rem;">' +
                                         '<select class="form-control col-uitype" onchange="toggleApiSourceField(this)" style="width: 100%;">';
                        uiTypes.forEach(t => {
                            selectHtml += '<option value="' + t + '" ' + (col.uiType === t ? 'selected' : '') + '>' + t + '</option>';
                        });
                        selectHtml += '</select>';
                        const displayLinkStyle = col.uiType === "FileUpload" ? "block" : "none";
                        selectHtml += '<a href="javascript:void(0)" class="constraints-link" onclick="openConstraintsModal(\'' + col.name + '\')" ' +
                                      'style="display: ' + displayLinkStyle + '; font-size: 0.8rem; color: var(--primary); text-decoration: underline; font-weight: 600;">' +
                                      '⚙️ Edit Constraints' +
                                      '</a>' +
                                      '</div>';
                        tdUi.innerHTML = selectHtml;
                        tr.appendChild(tdUi);

                        // API Source field
                        const tdApi = document.createElement("td");
                        const displayStyle = col.uiType === "Dropdown" ? "block" : "none";
                        tdApi.innerHTML = 
                            '<input type="text" class="form-control col-apisource" ' +
                                   'value="' + (col.apiSource || '') + '" ' +
                                   'placeholder="/apps/dccmf/api/lookup/deptList" ' +
                                   'style="display: ' + displayStyle + '; width: 100%;">';
                        tr.appendChild(tdApi);

                        // Validation rule selector
                        const tdVal = document.createElement("td");
                        const valRules = ["None", "Email", "Numeric", "Date", "Regex", "Range"];
                        let valHtml = '<select class="form-control col-validation" onchange="toggleValidationParams(this)">';
                        valRules.forEach(v => {
                            valHtml += '<option value="' + v + '" ' + (col.validation === v ? 'selected' : '') + '>' + v + '</option>';
                        });
                        valHtml += '</select>';
                        
                        // Regex pattern input
                        const regexDisplay = col.validation === "Regex" ? "block" : "none";
                        valHtml += '<input type="text" class="form-control col-regex" placeholder="Regex Pattern" ' +
                                   'value="' + (col.regex || '') + '" ' +
                                   'style="display: ' + regexDisplay + '; margin-top: 5px; font-size: 0.85rem; width: 100%;">';
                        
                        // Range bounds container
                        const rangeDisplay = col.validation === "Range" ? "flex" : "none";
                        valHtml += '<div class="range-container" style="display: ' + rangeDisplay + '; margin-top: 5px; gap: 5px;">' +
                                       '<input type="number" step="any" class="form-control col-min" placeholder="Min" value="' + (col.min !== undefined && col.min !== null ? col.min : '') + '" style="width: 48%; font-size: 0.85rem; display: inline-block;">' +
                                       '<input type="number" step="any" class="form-control col-max" placeholder="Max" value="' + (col.max !== undefined && col.max !== null ? col.max : '') + '" style="width: 48%; font-size: 0.85rem; display: inline-block;">' +
                                   '</div>';
                        
                        tdVal.innerHTML = valHtml;
                        tr.appendChild(tdVal);

                        // Append cells in exact order
                        tr.appendChild(tdName);
                        tr.appendChild(tdSearch);
                        tr.appendChild(tdEditable);
                        tr.appendChild(tdVisible);
                        tr.appendChild(tdRequired);
                        tr.appendChild(tdUi);
                        tr.appendChild(tdApi);
                        tr.appendChild(tdVal);

                        tbody.appendChild(tr);
                    });
                } else {
                    alert("Error loading columns: " + data.message);
                }
            } catch (err) {
                console.error(err);
                alert("Failed to load columns configuration.");
            }
        }

        function toggleApiSourceField(selectEl) {
            const tr = selectEl.closest("tr");
            const apiField = tr.querySelector(".col-apisource");
            if (selectEl.value === "Dropdown") {
                apiField.style.display = "block";
            } else {
                apiField.style.display = "none";
                apiField.value = "";
            }
            
            const constraintsLink = tr.querySelector(".constraints-link");
            if (selectEl.value === "FileUpload") {
                constraintsLink.style.display = "block";
                openConstraintsModal(tr.dataset.columnName);
            } else {
                constraintsLink.style.display = "none";
            }
        }

        let activeConstraintsColumn = null;

        function openConstraintsModal(columnName) {
            const tr = document.querySelector('#columns-tbody tr[data-column-name="' + columnName + '"]');
            if (!tr) return;
            
            activeConstraintsColumn = columnName;
            document.getElementById("constraints-modal-colname").textContent = columnName;
            
            // Load current values from dataset attributes
            const maxSizeMb = tr.dataset.maxSizeMb !== undefined ? tr.dataset.maxSizeMb : 5;
            const allowedExtensions = tr.dataset.allowedExtensions !== undefined ? tr.dataset.allowedExtensions : "png,jpg,pdf,zip";
            
            document.getElementById("modal-max-size").value = maxSizeMb;
            
            const extList = allowedExtensions.split(",").map(s => s.trim().toLowerCase());
            document.getElementById("modal-mime-png").checked = extList.includes("png");
            document.getElementById("modal-mime-jpg").checked = extList.includes("jpg");
            document.getElementById("modal-mime-pdf").checked = extList.includes("pdf");
            document.getElementById("modal-mime-zip").checked = extList.includes("zip");
            
            document.getElementById("constraints-modal").classList.add("active");
        }

        function closeConstraintsModal() {
            document.getElementById("constraints-modal").classList.remove("active");
            activeConstraintsColumn = null;
        }

        function saveConstraintsFromModal() {
            if (!activeConstraintsColumn) return;
            
            const tr = document.querySelector('#columns-tbody tr[data-column-name="' + activeConstraintsColumn + '"]');
            if (!tr) return;
            
            const sizeInput = document.getElementById("modal-max-size");
            const maxSize = parseInt(sizeInput.value) || 5;
            tr.dataset.maxSizeMb = maxSize;
            
            const mimes = [];
            if (document.getElementById("modal-mime-png").checked) mimes.push("png");
            if (document.getElementById("modal-mime-jpg").checked) mimes.push("jpg");
            if (document.getElementById("modal-mime-pdf").checked) mimes.push("pdf");
            if (document.getElementById("modal-mime-zip").checked) mimes.push("zip");
            
            tr.dataset.allowedExtensions = mimes.join(",");
            
            closeConstraintsModal();
        }

        function resetConfigGrid() {
            document.getElementById("table-select").value = "";
            document.getElementById("config-card").style.display = "none";
        }

        async function saveConfiguration() {
            const db = document.getElementById("db-select").value;
            const table = document.getElementById("table-select").value;
            const rows = document.querySelectorAll("#columns-tbody tr");
            const statusMsg = document.getElementById("save-status-msg");

            const columns = [];
            rows.forEach(tr => {
                const name = tr.dataset.columnName;
                const searchKey = tr.querySelector(".col-search").checked;
                const editable = tr.querySelector(".col-editable").checked;
                const visible = tr.querySelector(".col-visible").checked;
                const uiType = tr.querySelector(".col-uitype").value;
                const apiSource = tr.querySelector(".col-apisource").value;
                const required = tr.querySelector(".col-required").checked;
                const validation = tr.querySelector(".col-validation").value;
                const regex = tr.querySelector(".col-regex").value;
                const minVal = tr.querySelector(".col-min").value;
                const maxVal = tr.querySelector(".col-max").value;

                const min = (validation === "Range" && minVal !== "") ? parseFloat(minVal) : null;
                const max = (validation === "Range" && maxVal !== "") ? parseFloat(maxVal) : null;

                const maxSizeMb = parseInt(tr.dataset.maxSizeMb) || 5;
                const allowedExtensions = tr.dataset.allowedExtensions || "png,jpg,pdf,zip";

                columns.push({
                    name: name,
                    searchKey: searchKey,
                    editable: editable,
                    visible: visible,
                    uiType: uiType,
                    apiSource: apiSource,
                    required: required,
                    validation: validation,
                    regex: validation === "Regex" ? regex : "",
                    min: min,
                    max: max,
                    maxSizeMb: maxSizeMb,
                    allowedExtensions: allowedExtensions
                });
            });

            const clientSidePaging = document.getElementById("client-side-paging-checkbox").checked;
            const clientSidePageSize = parseInt(document.getElementById("client-page-size-input").value) || 200;
            const serverSidePaging = document.getElementById("server-side-paging-checkbox").checked;
            const serverSidePageSize = parseInt(document.getElementById("server-page-size-input").value) || 1000;

            const configPayload = {
                database: db,
                table: table,
                columns: columns,
                rowField: "",
                columnField: "",
                clientSidePaging: clientSidePaging,
                clientSidePageSize: clientSidePageSize,
                serverSidePaging: serverSidePaging,
                serverSidePageSize: serverSidePageSize
            };

            statusMsg.textContent = "Saving configuration...";
            statusMsg.style.color = "var(--text-secondary)";

            try {
                let saveUrl = contextPath + "/apps/dccmf/admin/api/saveConfig";
                if (editConfigId) {
                    saveUrl += "?configId=" + editConfigId;
                }
                const response = await fetch(saveUrl, {
                    method: "POST",
                    headers: { "Content-Type": "application/json" },
                    body: JSON.stringify(configPayload)
                });
                const data = await response.json();

                if (data.success) {
                    currentConfigId = data.configId;
                    statusMsg.textContent = "Saved Successfully!";
                    statusMsg.style.color = "var(--success-color)";
                    
                    // Only show Link Modal if we are NOT in edit mode
                    if (!editConfigId) {
                        document.getElementById("share-link-input").value = "";
                        document.getElementById("link-modal").classList.add("active");
                        generateLink(); // Pre-trigger link generation
                    }
                } else {
                    statusMsg.textContent = "Save Failed: " + data.message;
                    statusMsg.style.color = "var(--error-color)";
                }
            } catch (err) {
                console.error(err);
                statusMsg.textContent = "Network Error.";
                statusMsg.style.color = "var(--error-color)";
            }
        }

        async function generateLink() {
            if (!currentConfigId) {
                alert("Save configuration first!");
                return;
            }

            const linkInput = document.getElementById("share-link-input");

            try {
                let url = contextPath + "/apps/dccmf/admin/api/generateLink?configId=" + currentConfigId;
                const response = await fetch(url, { method: "POST" });
                const data = await response.json();

                if (data.success) {
                    linkInput.value = data.url;
                } else {
                    alert("Failed to generate link: " + data.message);
                }
            } catch (err) {
                console.error(err);
                alert("Network error while generating link.");
            }
        }

        function copyLink() {
            const copyText = document.getElementById("share-link-input");
            copyText.select();
            copyText.setSelectionRange(0, 99999);
            navigator.clipboard.writeText(copyText.value);
            
            const copyBtn = copyText.nextElementSibling;
            const originalText = copyBtn.textContent;
            copyBtn.textContent = "Copied!";
            copyBtn.style.background = "var(--success-color)";
            copyBtn.style.color = "var(--text-primary)";
            
            setTimeout(() => {
                copyBtn.textContent = originalText;
                copyBtn.style.background = "";
                copyBtn.style.color = "";
            }, 2000);
        }

        function toggleValidationParams(select) {
            const tr = select.closest("tr");
            const regexInput = tr.querySelector(".col-regex");
            const rangeContainer = tr.querySelector(".range-container");
            const val = select.value;
            
            if (val === "Regex") {
                regexInput.style.display = "block";
                rangeContainer.style.display = "none";
            } else if (val === "Range") {
                regexInput.style.display = "none";
                rangeContainer.style.display = "flex";
            } else {
                regexInput.style.display = "none";
                rangeContainer.style.display = "none";
            }
        }

        function closeModal() {
            document.getElementById("link-modal").classList.remove("active");
        }

        // Auto-load tables on page load if browser pre-selects/restores a database selection or if params are provided
        window.addEventListener("DOMContentLoaded", async () => {
            const dbSelect = document.getElementById("db-select");
            
            // Check for URL parameters to pre-load configuration
            const urlParams = new URLSearchParams(window.location.search);
            const dbParam = urlParams.get('db');
            const tableParam = urlParams.get('table');
            
            if (dbParam && dbSelect) {
                dbSelect.value = dbParam;
                await loadTables();
                
                const tableSelect = document.getElementById("table-select");
                if (tableParam && tableSelect) {
                    tableSelect.value = tableParam;
                    loadColumns();
                }
            } else if (dbSelect && dbSelect.value) {
                loadTables();
            }
        });
    </script>
</body>
</html>
