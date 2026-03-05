import java.io.IOException;
import java.sql.*;
import java.time.LocalDate;

import jakarta.servlet.ServletException;
import jakarta.servlet.annotation.WebServlet;
import jakarta.servlet.http.HttpServlet;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;

@WebServlet("/AddReservationServlet")
public class AddReservationServlet extends HttpServlet {

    private static final String URL  = "jdbc:mysql://localhost:3306/ocean_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Colombo";
    private static final String USER = "root";
    private static final String PASS = "";

    @Override
    protected void doPost(HttpServletRequest request, HttpServletResponse response)
            throws ServletException, IOException {

        String guestName = safeTrim(request.getParameter("guestName"));
        String contact   = safeTrim(request.getParameter("contact"));
        String address   = safeTrim(request.getParameter("address"));
        String roomType  = safeTrim(request.getParameter("roomType"));
        String checkInS  = safeTrim(request.getParameter("checkIn"));
        String checkOutS = safeTrim(request.getParameter("checkOut"));

        String validationError = validateInputs(guestName, contact, address, roomType, checkInS, checkOutS);
        if (validationError != null) {
            request.setAttribute("error", validationError);
            request.getRequestDispatcher("new_reservation.jsp").forward(request, response);
            return;
        }

        LocalDate checkIn  = LocalDate.parse(checkInS);
        LocalDate checkOut = LocalDate.parse(checkOutS);

        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(URL, USER, PASS)) {

                // ✅ 1) Block overlap booking for same roomType
                String overlapSql =
                        "SELECT COUNT(*) FROM reservations " +
                        "WHERE room_type=? AND (check_in < ? AND check_out > ?)";

                try (PreparedStatement ps = con.prepareStatement(overlapSql)) {
                    ps.setString(1, roomType);
                    ps.setDate(2, Date.valueOf(checkOut));
                    ps.setDate(3, Date.valueOf(checkIn));
                    try (ResultSet rs = ps.executeQuery()) {
                        rs.next();
                        if (rs.getInt(1) > 0) {
                            request.setAttribute("error",
                                    "This room type is already booked for the selected dates. Please choose different dates.");
                            request.getRequestDispatcher("new_reservation.jsp").forward(request, response);
                            return;
                        }
                    }
                }

                // ✅ 2) Insert reservation FIRST (to get auto id)
                String insertSql =
                        "INSERT INTO reservations (guest_name, contact, address, room_type, check_in, check_out) " +
                        "VALUES (?,?,?,?,?,?)";

                long newId;

                try (PreparedStatement ps = con.prepareStatement(insertSql, Statement.RETURN_GENERATED_KEYS)) {
                    ps.setString(1, guestName);
                    ps.setString(2, contact.replaceAll("\\s+",""));
                    ps.setString(3, address);
                    ps.setString(4, roomType);
                    ps.setDate(5, Date.valueOf(checkIn));
                    ps.setDate(6, Date.valueOf(checkOut));

                    int rows = ps.executeUpdate();
                    if (rows == 0) {
                        request.setAttribute("error", "Failed to create reservation. Please try again.");
                        request.getRequestDispatcher("new_reservation.jsp").forward(request, response);
                        return;
                    }

                    try (ResultSet keys = ps.getGeneratedKeys()) {
                        if (!keys.next()) {
                            request.setAttribute("error", "Reservation created but ID not returned.");
                            request.getRequestDispatcher("new_reservation.jsp").forward(request, response);
                            return;
                        }
                        newId = keys.getLong(1);
                    }
                }

                // ✅ 3) Generate reservation code: RES-001, RES-002...
                String reservationCode = String.format("RES-%03d", newId);

                // ✅ 4) Update the row with reservation_code
                String updateCodeSql = "UPDATE reservations SET reservation_code=? WHERE id=?";
                try (PreparedStatement ps = con.prepareStatement(updateCodeSql)) {
                    ps.setString(1, reservationCode);
                    ps.setLong(2, newId);
                    ps.executeUpdate();
                }

                // ✅ 5) "Normal SMS" simulation (console) + Popup message
                String smsText =
                        "Ocean View Resort: Reservation Confirmed ✅\n" +
                        "Ref: " + reservationCode + "\n" +
                        "Guest: " + guestName + "\n" +
                        "Room: " + roomType + "\n" +
                        "Check-in: " + checkInS + "\n" +
                        "Check-out: " + checkOutS + "\n" +
                        "Thank you!";

                // ✅ Simulate SMS sending (no gateway)
                System.out.println("========== SMS SENT ==========");
                System.out.println("To: " + contact.replaceAll("\\s+",""));
                System.out.println(smsText);
                System.out.println("==============================");

                // ✅ Popup message for JSP
                request.setAttribute("smsSuccess", "SMS Sent Successfully to " + contact.replaceAll("\\s+",""));

                // ✅ Existing success message
                request.setAttribute("success", "Reservation created successfully! Reservation No: " + reservationCode);
                request.getRequestDispatcher("new_reservation.jsp").forward(request, response);

            }

        } catch (Exception e) {
            e.printStackTrace();
            request.setAttribute("error", "Server error: " + e.getMessage());
            request.getRequestDispatcher("new_reservation.jsp").forward(request, response);
        }
    }

    private String safeTrim(String s){
        return (s == null) ? "" : s.trim();
    }

    private String validateInputs(String guestName, String contact, String address,
                                  String roomType, String checkIn, String checkOut){

        if (guestName.length() < 3 || guestName.length() > 60) return "Guest Name must be 3–60 characters.";
        if (!guestName.matches("^[A-Za-z.\\s'\\-]+$")) return "Guest Name has invalid characters.";

        String phone = contact.replaceAll("\\s+","");
        if (!phone.matches("^(\\+94\\d{9}|0\\d{9})$")) return "Invalid Sri Lanka contact number format.";

        if (address.length() < 8 || address.length() > 200) return "Address must be 8–200 characters.";
        if (address.matches("^[\\W_]+$")) return "Address cannot be only symbols.";

        if (roomType.isEmpty()) return "Please select a room type.";

        if (checkIn.isEmpty() || checkOut.isEmpty()) return "Please select check-in and check-out dates.";

        LocalDate in, out;
        try{
            in = LocalDate.parse(checkIn);
            out = LocalDate.parse(checkOut);
        }catch(Exception ex){
            return "Invalid date format.";
        }

        LocalDate today = LocalDate.now();
        if (in.isBefore(today)) return "Check-in date cannot be in the past.";
        if (!out.isAfter(in)) return "Check-out must be after check-in (minimum 1 night).";

        long stay = java.time.temporal.ChronoUnit.DAYS.between(in, out);
        if (stay > 30) return "Maximum stay allowed is 30 nights.";

        return null;
    }
}