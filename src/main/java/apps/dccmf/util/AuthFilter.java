package apps.dccmf.util;

import javax.servlet.*;
import javax.servlet.annotation.WebFilter;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;
import java.io.IOException;

/**
 * Filter that protects admin panel endpoints.
 * Redirects unauthenticated requests to the admin login page.
 */
@WebFilter(urlPatterns = {"/apps/dccmf/admin/*"})
public class AuthFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
        // Initialization if needed
    }

    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest httpRequest = (HttpServletRequest) request;
        HttpServletResponse httpResponse = (HttpServletResponse) response;
        HttpSession session = httpRequest.getSession(false);

        String contextPath = "/apps";
        String requestURI = httpRequest.getRequestURI();

        boolean isLoggedIn = (session != null && session.getAttribute("adminUser") != null);
        
        // Exclude the login endpoint and login.jsp itself to prevent redirect loops
        boolean isLoginPage = requestURI.equals("/apps/apps/dccmf/admin/login.jsp") || 
                              requestURI.endsWith("/admin/login.jsp");

        // Disable browser caching for admin pages to guarantee the latest HTML/JSP is loaded
        httpResponse.setHeader("Cache-Control", "no-cache, no-store, must-revalidate"); // HTTP 1.1.
        httpResponse.setHeader("Pragma", "no-cache"); // HTTP 1.0.
        httpResponse.setDateHeader("Expires", 0); // Proxies.

        if (isLoggedIn || isLoginPage) {
            chain.doFilter(request, response);
        } else {
            httpResponse.sendRedirect("/apps/apps/dccmf/admin/login.jsp");
        }
    }

    @Override
    public void destroy() {
        // Destruction logic
    }
}
