<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // Session values set after login
    String username = (String) session.getAttribute("username");
    String role     = (String) session.getAttribute("role"); // optional if you have role

    // ✅ If not logged in → go login
    if (username == null) {
        response.sendRedirect("login.jsp?msg=Please+login+as+Admin+to+access+Reservations");
        return;
    }

    // ✅ If role exists, enforce admin
    if (role != null && !role.equalsIgnoreCase("admin")) {
        response.sendRedirect("login.jsp?msg=Admin+permission+required+for+Reservations");
        return;
    }

    // ✅ OK → open reservation page
    response.sendRedirect("new_reservation.jsp");
%>