package com.oceanview.tests;

import java.sql.*;

public class Db {

    // ✅ Same DB as your web app
    private static final String DB_URL =
            "jdbc:mysql://localhost:3306/ocean_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Colombo";
    private static final String DB_USER = "root";
    private static final String DB_PASS = "";

    // ----------------------------------------------------
    // 🔌 Get Connection
    // ----------------------------------------------------
    public static Connection getConnection() throws SQLException {
        return DriverManager.getConnection(DB_URL, DB_USER, DB_PASS);
    }

    // ----------------------------------------------------
    // 🔎 Check if reservation exists by guest_name + contact
    // ----------------------------------------------------
    public static boolean reservationExists(String guestName, String contact)
            throws SQLException {

        String sql = "SELECT COUNT(*) FROM reservations WHERE guest_name=? AND contact=?";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, guestName);
            ps.setString(2, contact);

            try (ResultSet rs = ps.executeQuery()) {
                rs.next();
                return rs.getInt(1) > 0;
            }
        }
    }

    // ----------------------------------------------------
    // ✅ BEST: Check if reservation exists by CONTACT only
    // (Perfect for automation because contact is unique each run)
    // ----------------------------------------------------
    public static boolean reservationExistsByContact(String contact)
            throws SQLException {

        String sql = "SELECT 1 FROM reservations WHERE contact=? LIMIT 1";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, contact);

            try (ResultSet rs = ps.executeQuery()) {
                return rs.next();
            }
        }
    }

    // ----------------------------------------------------
    // 🗑 Delete reservation by guest_name + contact
    // ----------------------------------------------------
    public static void deleteReservation(String guestName, String contact)
            throws SQLException {

        String sql = "DELETE FROM reservations WHERE guest_name=? AND contact=?";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, guestName);
            ps.setString(2, contact);
            ps.executeUpdate();
        }
    }

    // ----------------------------------------------------
    // 🗑 Delete reservation by CONTACT only
    // ----------------------------------------------------
    public static void deleteReservationByContact(String contact)
            throws SQLException {

        String sql = "DELETE FROM reservations WHERE contact=?";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql)) {

            ps.setString(1, contact);
            ps.executeUpdate();
        }
    }

    // ----------------------------------------------------
    // 📊 Count total reservations
    // ----------------------------------------------------
    public static int countReservations() throws SQLException {

        String sql = "SELECT COUNT(*) FROM reservations";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            rs.next();
            return rs.getInt(1);
        }
    }

    // ----------------------------------------------------
    // 🧾 Get last inserted reservation row (debug)
    // NOTE: requires reservations table has "id"
    // ----------------------------------------------------
    public static String getLastReservationRow() throws SQLException {

        String sql =
                "SELECT id, reservation_code, guest_name, contact, room_type, " +
                        "check_in, check_out " +
                        "FROM reservations ORDER BY id DESC LIMIT 1";

        try (Connection con = getConnection();
             PreparedStatement ps = con.prepareStatement(sql);
             ResultSet rs = ps.executeQuery()) {

            if (!rs.next()) {
                return "reservations table is empty";
            }

            return "LAST ROW => id=" + rs.getInt("id") +
                    ", code=" + rs.getString("reservation_code") +
                    ", guest_name=" + rs.getString("guest_name") +
                    ", contact=" + rs.getString("contact") +
                    ", room=" + rs.getString("room_type") +
                    ", check_in=" + rs.getDate("check_in") +
                    ", check_out=" + rs.getDate("check_out");
        }
    }
}