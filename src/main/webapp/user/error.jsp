<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Link Error - DCCMF</title>
    <link rel="stylesheet" href="/apps/apps/dccmf/css/style.css">
</head>
<body>
    <!-- Navbar -->
    <nav class="navbar">
        <a href="#" class="navbar-brand">
             <span>ACCESS SYSTEM</span>
        </a>
    </nav>

    <!-- Main Container -->
    <div class="container" style="justify-content: center; align-items: center;">
        <div class="glass-card" style="max-width: 550px; width: 100%; text-align: center; border-color: var(--error-color);">
            <div style="color: var(--error-color); font-size: 3.5rem; margin-bottom: 1.5rem;">
                ⚠️
            </div>
            
            <h2 style="margin-bottom: 1rem; color: var(--text-primary);">
                <%= request.getAttribute("errorTitle") != null ? request.getAttribute("errorTitle") : "Link Access Denied" %>
            </h2>
            
            <p style="color: var(--text-secondary); line-height: 1.6; margin-bottom: 2rem;">
                <%= request.getAttribute("errorMessage") != null ? request.getAttribute("errorMessage") : "The link you clicked might be broken, expired, or revoked by the system administrator." %>
            </p>

            <div style="border-top: 1px solid var(--border-color); padding-top: 1.5rem;">
                <p style="font-size: 0.85rem; color: var(--text-muted);">
                    If you believe this is a mistake, please contact the administrator who generated this link to issue a new token.
                </p>
            </div>
        </div>
    </div>

    <footer>
        <p>&copy; 2026 Dynamic Data Collection Framework (DCCMF). All rights reserved.</p>
    </footer>
</body>
</html>
