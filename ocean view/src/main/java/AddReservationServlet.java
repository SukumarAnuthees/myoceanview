import java.io.IOException;
import java.sql.*;
import java.time.LocalDate;
import java.time.temporal.ChronoUnit;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;

@WebServlet("/AddReservationServlet")
public class AddReservationServlet extends HttpServlet {

    private static final String URL =
            "jdbc:mysql://localhost:3306/ocean_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Colombo";
    private static final String USER = "root";
    private static final String PASSWORD = "";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        // ✅ Must be logged in
        HttpSession session = request.getSession(false);
        if (session == null || session.getAttribute("username") == null) {
            response.sendRedirect("login.jsp");
            return;
        }

        // Read form fields
        String guestName = safe(request.getParameter("guestName"));
        String contact = safe(request.getParameter("contact")).replaceAll("\\s+", "");
        String address = safe(request.getParameter("address"));
        String roomType = safe(request.getParameter("roomType"));
        String checkInStr = safe(request.getParameter("checkIn"));
        String checkOutStr = safe(request.getParameter("checkOut"));

        // ✅ Server-side validation
        String error = validate(guestName, contact, address, roomType, checkInStr, checkOutStr);
        if (error != null) {
            request.setAttribute("error", error);
            request.getRequestDispatcher("new_reservation.jsp").forward(request, response);
            return;
        }

        LocalDate checkIn = LocalDate.parse(checkInStr);
        LocalDate checkOut = LocalDate.parse(checkOutStr);

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");

            try (Connection con = DriverManager.getConnection(URL, USER, PASSWORD)) {

                // ✅ Generate reservation code RES-001, RES-002...
                String reservationCode = generateReservationCode(con);

                // ✅ Insert into DB
                String sql = "INSERT INTO reservations " +
                        "(reservation_code, guest_name, contact, address, room_type, check_in, check_out) " +
                        "VALUES (?,?,?,?,?,?,?)";

                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, reservationCode);
                    ps.setString(2, guestName);
                    ps.setString(3, contact);
                    ps.setString(4, address);
                    ps.setString(5, roomType);
                    ps.setDate(6, Date.valueOf(checkIn));
                    ps.setDate(7, Date.valueOf(checkOut));

                    int rows = ps.executeUpdate();

                    if (rows > 0) {
                        request.setAttribute("success", "Reservation created successfully! Code: " + reservationCode);
                    } else {
                        request.setAttribute("error", "Failed to create reservation. Try again.");
                    }
                }
            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "DB Error: " + e.getMessage());
        }

        request.getRequestDispatcher("new_reservation.jsp").forward(request, response);
    }

    // ---------- Helpers ----------

    private static String safe(String s) {
        return (s == null) ? "" : s.trim();
    }

    private static String validate(String guestName, String contact, String address, String roomType,
                                   String checkInStr, String checkOutStr) {

        // Guest name: letters/spaces/dot, min 3
        if (guestName.length() < 3 || !guestName.matches("^[A-Za-z.\\s]+$")) {
            return "Guest Name must be at least 3 characters and contain only letters/spaces.";
        }

        // Contact (Sri Lanka): +94xxxxxxxxx OR 0xxxxxxxxx
        if (!contact.matches("^(\\+94\\d{9}|0\\d{9})$")) {
            return "Invalid Contact Number. Use +94XXXXXXXXX or 0XXXXXXXXX.";
        }

        // Address
        if (address.length() < 8) {
            return "Address must be at least 8 characters.";
        }

        // Room type
        if (roomType.isEmpty()) {
            return "Please select a room type.";
        }

        // Dates
        if (checkInStr.isEmpty() || checkOutStr.isEmpty()) {
            return "Please select check-in and check-out dates.";
        }

        LocalDate checkIn;
        LocalDate checkOut;
        try {
            checkIn = LocalDate.parse(checkInStr);
            checkOut = LocalDate.parse(checkOutStr);
        } catch (Exception e) {
            return "Invalid date format.";
        }

        LocalDate today = LocalDate.now();
        if (checkIn.isBefore(today)) {
            return "Check-in date cannot be in the past.";
        }
        if (!checkOut.isAfter(checkIn)) {
            return "Check-out date must be after check-in date.";
        }

        long days = ChronoUnit.DAYS.between(checkIn, checkOut);
        if (days > 30) {
            return "Maximum stay allowed is 30 days.";
        }

        return null; // ✅ all OK
    }

    private static String generateReservationCode(Connection con) throws SQLException {
        String lastCode = null;

        String q = "SELECT reservation_code FROM reservations ORDER BY id DESC LIMIT 1";
        try (PreparedStatement ps = con.prepareStatement(q);
             ResultSet rs = ps.executeQuery()) {
            if (rs.next()) {
                lastCode = rs.getString("reservation_code");
            }
        }

        int nextNum = 1;
        if (lastCode != null && lastCode.startsWith("RES-")) {
            String numPart = lastCode.substring(4).trim();
            try {
                nextNum = Integer.parseInt(numPart) + 1;
            } catch (NumberFormatException ignored) { }
        }

        return String.format("RES-%03d", nextNum);
    }
}
