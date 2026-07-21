<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // =========================================================================
    // DCCMF ADMINISTRATOR AUTHENTICATION GATEWAY
    // File: /apps/dccmf/admin/login.jsp
    // Description: Serves as both GET portal and POST authenticator.
    //              Invalidates session on logout actions and redirects.
    // =========================================================================

    String action = request.getParameter("action");
    if ("logout".equalsIgnoreCase(action)) {
        // Invalidate administrator HTTP session on sign out
        HttpSession sess = request.getSession(false);
        if (sess != null) {
            sess.invalidate();
        }
        response.sendRedirect("/apps/apps/dccmf/admin/login.jsp");
        return;
    }

    // Auto-redirect to dashboard if administrator session is already active
    HttpSession sessionCheck = request.getSession(false);
    if (sessionCheck != null && sessionCheck.getAttribute("adminUser") != null && !"logout".equalsIgnoreCase(action)) {
        response.sendRedirect("/apps/apps/dccmf/admin/dashboard.jsp");
        return;
    }

    // Process credentials on POST forms submissions
    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String username = request.getParameter("username");
        String password = request.getParameter("password");
        apps.dccmf.util.AdminService adminService = new apps.dccmf.util.AdminService();
        
        // Authenticate against database records in dccmf_admin
        if (adminService.authenticate(username, password)) {
            HttpSession sess = request.getSession(true);
            sess.setAttribute("adminUser", username);
            response.sendRedirect("/apps/apps/dccmf/admin/dashboard.jsp");
            return;
        } else {
            request.setAttribute("errorMessage", "Invalid Username or Password.");
        }
    }
%>
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Login - DCCMF</title>
    <link rel="stylesheet" href="/apps/apps/dccmf/css/style.css">
    <style>
        body {
            display: flex;
            flex-direction: column;
            justify-content: space-between;
            min-height: 100vh;
            background: var(--bg);
        }
        .toggle-password-btn {
            position: absolute;
            right: 12px;
            top: 50%;
            transform: translateY(-50%);
            background: none;
            border: none;
            cursor: pointer;
            color: var(--muted);
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 0;
            transition: color 0.2s;
        }
        .toggle-password-btn:hover {
            color: var(--primary);
        }
    </style>
</head>
<body>

    <!-- ── App Banner Header ── -->
    <div class="App-banner">
        <img src="/apps/apps/dccmf/images/App_banner.png" class="App-logo-img" alt="App Portal Logo">
    </div>

    <div class="login-container">
        <div class="login-card">
            <div class="login-logo-container" style="text-align: center; margin-bottom: 2rem;">
                <img src="/apps/apps/dccmf/images/App_logo.png" alt="App Logo" class="login-logo" style="max-height: 70px; margin-bottom: 1rem;">
                <h2>System Login</h2>
                <p style="font-size: 0.88rem; color: var(--muted); margin-top: 0.25rem;">
                    Dynamic Data Collection, Communication & Management Framework
                </p>
            </div>

            <% if (request.getAttribute("errorMessage") != null) { %>
                <div class="alert alert-danger" style="margin-bottom: 1.5rem;">
                    <%= request.getAttribute("errorMessage") %>
                </div>
            <% } %>

            <form action="/apps/apps/dccmf/admin/login.jsp" method="post">
                <div class="form-group" style="text-align: left;">
                    <label for="username">USER ID / USERNAME</label>
                    <input type="text" id="username" name="username" class="form-control" placeholder="Enter your User ID" required autofocus autocomplete="username">
                </div>
                
                <div class="form-group" style="text-align: left; margin-top: 1.25rem; position: relative;">
                    <label for="password">PASSWORD</label>
                    <div style="position: relative;">
                        <input type="password" id="password" name="password" class="form-control" placeholder="Enter password" required style="padding-right: 40px;" autocomplete="current-password">
                        <button type="button" id="togglePassword" class="toggle-password-btn" aria-label="Toggle Password Visibility">
                            <svg xmlns="http://www.w3.org/2000/svg" width="20" height="20" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" class="feather feather-eye" viewBox="0 0 24 24" id="eyeIcon">
                                <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                                <circle cx="12" cy="12" r="3"/>
                            </svg>
                        </button>
                    </div>
                </div>

                <button type="submit" class="btn btn-primary" style="width: 100%; margin-top: 1.5rem; padding: 0.75rem 1.5rem;">
                    Sign In
                </button>
            </form>

        </div>
    </div>

    <div class="login-footer">
        © 2026 Application Portal (App), Main Campus. All Rights Reserved.
    </div>

    <script>
        // Toggle Password Visibility Logic
        const passwordInput = document.getElementById('password');
        const toggleBtn = document.getElementById('togglePassword');
        const eyeIcon = document.getElementById('eyeIcon');

        toggleBtn.addEventListener('click', function () {
            const isPassword = passwordInput.getAttribute('type') === 'password';
            passwordInput.setAttribute('type', isPassword ? 'text' : 'password');
            if (isPassword) {
                eyeIcon.innerHTML = `
                    <path d="M17.94 17.94A10.07 10.07 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94M9.9 4.24A9.12 9.12 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19m-6.72-1.07a3 3 0 1 1-4.24-4.24"/>
                    <line x1="1" y1="1" x2="23" y2="23"/>
                `;
            } else {
                eyeIcon.innerHTML = `
                    <path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8z"/>
                    <circle cx="12" cy="12" r="3"/>
                `;
            }
        });
    </script>
</body>
</html>
