
import java.io.IOException;
import java.sql.*;
import jakarta.servlet.*;
import jakarta.servlet.http.*;
import jakarta.servlet.annotation.WebServlet;

@WebServlet("/LoginServlet")
public class LoginServlet extends HttpServlet {

    private static final String URL = "jdbc:mysql://localhost:3306/ocean_db";
    private static final String USER = "root";
    private static final String PASSWORD = "";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String username = request.getParameter("username");
        String password = request.getParameter("password");

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection con = DriverManager.getConnection(URL, USER, PASSWORD);
                 PreparedStatement ps = con.prepareStatement(
                         "SELECT * FROM users WHERE username=? AND password=?")) {

                ps.setString(1, username);
                ps.setString(2, password);

                ResultSet rs = ps.executeQuery();

                if (rs.next()) {

                    HttpSession session = request.getSession();
                    session.setAttribute("username", username);
                    session.setMaxInactiveInterval(30 * 60); // 30 minutes

                    response.sendRedirect("dashboard.jsp");

                } else {
                    request.setAttribute("error", "Invalid Username or Password!");
                    request.getRequestDispatcher("login.jsp").forward(request, response);
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "System error. Please try again later.");
            request.getRequestDispatcher("login.jsp").forward(request, response);
        }
    }
}
