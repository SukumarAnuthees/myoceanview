import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.WebServlet;

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {

    private static final String URL = "jdbc:mysql://localhost:3306/ocean_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Colombo";
    private static final String USER = "root";
    private static final String PASSWORD = "";

    // Username rule: 3-30 chars, letters/numbers/._-
    private static final String USERNAME_REGEX = "^[A-Za-z0-9._-]{3,30}$";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // 1) Read inputs
        String username = request.getParameter("username");
        String password = request.getParameter("password");

        // 2) Basic server-side validation (required fields)
        if (username == null || password == null) {
            request.setAttribute("error", "User ID and Password are required.");
            request.getRequestDispatcher("login.jsp").forward(request, response);
            return;
        }

        username = username.trim();
        password = password.trim();

        if (username.isEmpty() || password.isEmpty()) {
            request.setAttribute("error", "User ID and Password are required.");
            request.getRequestDispatcher("login.jsp").forward(request, response);
            return;
        }

        // 3) Format validation (restrict invalid usernames)
        if (!username.matches(USERNAME_REGEX)) {
            request.setAttribute("error", "Invalid User ID format.");
            request.getRequestDispatcher("login.jsp").forward(request, response);
            return;
        }

        // 4) Authenticate safely with PreparedStatement
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection con = DriverManager.getConnection(URL, USER, PASSWORD);
                 PreparedStatement ps = con.prepareStatement(
                         "SELECT username FROM users WHERE username=? AND password=?")) {

                ps.setString(1, username);
                ps.setString(2, password);

                try (ResultSet rs = ps.executeQuery()) {
                    if (rs.next()) {

                        // 5) Create session only when login succeeds
                        HttpSession session = request.getSession(true);
                        session.setAttribute("username", rs.getString("username"));
                        session.setMaxInactiveInterval(30 * 60); // 30 minutes

                        response.sendRedirect("dashboard.jsp");
                        return;
                    }
                }
            }

            // Invalid credentials
            request.setAttribute("error", "Invalid Username or Password!");
            request.getRequestDispatcher("login.jsp").forward(request, response);

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "System error. Please try again later.");
            request.getRequestDispatcher("login.jsp").forward(request, response);
        }
    }
}