<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%
    // ✅ Prevent caching (recommended)
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // ✅ Protect page
    if (session.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    // ✅ DB config
    String URL  = "jdbc:mysql://localhost:3306/ocean_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Colombo";
    String USER = "root";
    String PASS = "";

    String q = request.getParameter("q");
    if (q == null) q = "";
    q = q.trim().replaceAll("\\s+"," ");

    // (optional) username display
    String username = (String) session.getAttribute("username");

    // ✅ Handle UPDATE / DELETE inside same JSP (POST)
    String msgOk = null;
    String msgErr = null;

    if ("POST".equalsIgnoreCase(request.getMethod())) {
        String action = request.getParameter("action");
        String idStr  = request.getParameter("id");

        if (action != null && idStr != null && !idStr.trim().isEmpty()) {
            try {
                int rid = Integer.parseInt(idStr.trim());

                Class.forName("com.mysql.cj.jdbc.Driver");
                try (Connection con = DriverManager.getConnection(URL, USER, PASS)) {

                    // ======================================================
                    // ✅ EDIT (UPDATE) WITH FULL VALIDATIONS (ONLY THIS PART)
                    // ======================================================
                    if ("update".equals(action)) {

                        String guestName = request.getParameter("guest_name");
                        String address   = request.getParameter("address");
                        String contact   = request.getParameter("contact");
                        String roomType  = request.getParameter("room_type");
                        String checkIn   = request.getParameter("check_in");  // yyyy-mm-dd
                        String checkOut  = request.getParameter("check_out"); // yyyy-mm-dd

                        // ✅ trim safe
                        guestName = (guestName == null ? "" : guestName.trim());
                        address   = (address   == null ? "" : address.trim());
                        contact   = (contact   == null ? "" : contact.trim());
                        roomType  = (roomType  == null ? "" : roomType.trim());
                        checkIn   = (checkIn   == null ? "" : checkIn.trim());
                        checkOut  = (checkOut  == null ? "" : checkOut.trim());

                        java.util.List<String> errs = new java.util.ArrayList<>();

                        // ✅ 1) Guest name validation
                        if (guestName.isEmpty()) errs.add("Guest Name is required.");
                        else if (guestName.length() < 3 || guestName.length() > 60) errs.add("Guest Name must be 3–60 characters.");
                        else if (!guestName.matches("^[A-Za-z][A-Za-z .'-]{1,58}[A-Za-z]$"))
                            errs.add("Guest Name can contain only letters, spaces, . ' -");

                        // ✅ 2) Contact validation (Sri Lanka)
                        String contactNorm = contact.replaceAll("[\\s-]", "");
                        if (contactNorm.isEmpty()) errs.add("Contact is required.");
                        else {
                            boolean okLocal = contactNorm.matches("^07\\d{8}$");
                            boolean ok94    = contactNorm.matches("^\\+94\\d{9}$");
                            if (!(okLocal || ok94)) errs.add("Contact must be 07XXXXXXXX or +94XXXXXXXXX.");
                        }

                        // ✅ 3) Address length (optional)
                        if (address.length() > 120) errs.add("Address max length is 120 characters.");

                        // ✅ 4) Room type allowed
                        java.util.Set<String> allowedRooms = new java.util.HashSet<>();
                        allowedRooms.add("Ocean Suite");
                        allowedRooms.add("Beach Villa");
                        allowedRooms.add("Deluxe Room");
                        allowedRooms.add("Standard Room");

                        if (roomType.isEmpty()) errs.add("Room Type is required.");
                        else if (!allowedRooms.contains(roomType)) errs.add("Invalid Room Type selected.");

                        // ✅ 5) Date validation
                        java.sql.Date inD = null;
                        java.sql.Date outD = null;

                        try {
                            if (checkIn.isEmpty()) errs.add("Check In date is required.");
                            else inD = java.sql.Date.valueOf(checkIn);

                            if (checkOut.isEmpty()) errs.add("Check Out date is required.");
                            else outD = java.sql.Date.valueOf(checkOut);
                        } catch (Exception e) {
                            errs.add("Invalid date format. Please choose valid dates.");
                        }

                        if (inD != null && outD != null) {
                            java.time.LocalDate inL  = inD.toLocalDate();
                            java.time.LocalDate outL = outD.toLocalDate();

                            if (!outL.isAfter(inL)) errs.add("Check Out must be after Check In.");

                            long nights = java.time.temporal.ChronoUnit.DAYS.between(inL, outL);
                            if (nights < 1 || nights > 30) errs.add("Stay length must be between 1 and 30 nights.");
                        }

                        if (!errs.isEmpty()) {
                            msgErr = String.join(" ", errs);
                        } else {
                            String sqlU =
                                "UPDATE reservations SET guest_name=?, address=?, contact=?, room_type=?, check_in=?, check_out=? " +
                                "WHERE id=?";

                            try (PreparedStatement ps = con.prepareStatement(sqlU)) {
                                ps.setString(1, guestName);
                                ps.setString(2, address);
                                ps.setString(3, contactNorm); // ✅ normalized
                                ps.setString(4, roomType);
                                ps.setDate(5, inD);
                                ps.setDate(6, outD);
                                ps.setInt(7, rid);

                                int updated = ps.executeUpdate();
                                if (updated > 0) msgOk = "Reservation updated successfully.";
                                else msgErr = "Update failed. Reservation not found.";
                            }
                        }

                    // ===========================
                    // ✅ DELETE (unchanged)
                    // ===========================
                    } else if ("delete".equals(action)) {
                        String sqlD = "DELETE FROM reservations WHERE id=?";
                        try (PreparedStatement ps = con.prepareStatement(sqlD)) {
                            ps.setInt(1, rid);
                            int deleted = ps.executeUpdate();
                            if (deleted > 0) msgOk = "Reservation deleted successfully.";
                            else msgErr = "Delete failed. Reservation not found.";
                        }
                    }
                }

            } catch (Exception ex) {
                msgErr = "Action failed: " + ex.getMessage();
            }
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Reservations</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap" rel="stylesheet">

    <style>
        :root{
            --bg:#f5f7fb;
            --card:#ffffff;
            --ink:#0f172a;
            --muted:#64748b;
            --line:rgba(15,23,42,.10);
            --shadow:0 18px 45px rgba(2,6,23,.08);
            --soft:0 10px 25px rgba(2,6,23,.06);
            --grad:linear-gradient(135deg,#062a47,#1f7a9a 55%,#39b6c8);
            --grad2:linear-gradient(135deg,#0b1220,#0b3a5d 60%,#2ea3ba);
            --chip:#eef6ff;
            --chip2:#ecfdf5;
            --chip3:#fff7ed;
        }

        *{margin:0;padding:0;box-sizing:border-box;font-family:'Poppins',sans-serif;}
        body{background:var(--bg); color:var(--ink);}
        .app{display:flex;min-height:100vh;}

        .sidebar{
            width:280px;
            background:linear-gradient(180deg,#0b3a5d,#0d5572 55%, #2e9bb7);
            color:#fff;
            padding:22px 18px;
            position:sticky;
            top:0;
            height:100vh;
        }
        .brand{display:flex;gap:12px;align-items:center;margin-bottom:26px;padding:6px 8px;}
        .brand-icon{
            width:46px;height:46px;border-radius:14px;
            background:rgba(255,255,255,.12);
            display:grid;place-items:center;
            box-shadow:0 10px 24px rgba(0,0,0,.15);
        }
        .brand h2{font-size:20px;line-height:1.1;}
        .brand small{opacity:.85;display:block;margin-top:2px;font-weight:300}

        .nav{margin-top:10px;display:flex;flex-direction:column;gap:8px;}
        .nav a{
            display:flex;align-items:center;
            padding:14px 14px;border-radius:14px;
            color:#e9f4ff;text-decoration:none;
            transition:.2s;
            font-weight:600;
        }
        .nav a:hover{background:rgba(255,255,255,.12);}
        .nav a.active{background:rgba(255,255,255,.18);}

        .sidebar-footer{
            position:absolute;left:18px;right:18px;bottom:18px;
        }
        .logout{
            display:flex;align-items:center;
            padding:14px 14px;border-radius:14px;
            background:rgba(255,255,255,.12);
            color:#fff;text-decoration:none;
            transition:.2s;
            font-weight:700;
        }
        .logout:hover{background:rgba(255,255,255,.18);}

        .main{flex:1;padding:34px 38px 60px;}
        @media(max-width:820px){
            .sidebar{display:none;}
            .main{padding:18px;}
        }

        .hero{
            background:var(--grad2);
            border-radius:22px;
            padding:26px 24px;
            color:#e2e8f0;
            box-shadow:var(--soft);
            border:1px solid rgba(255,255,255,.10);
            overflow:hidden;
            position:relative;
            max-width:1100px;
        }
        .hero:before{
            content:"";
            position:absolute;
            inset:-80px -120px auto auto;
            width:260px;height:260px;
            background:radial-gradient(circle at 30% 30%, rgba(56,189,248,.35), rgba(56,189,248,0));
            transform:rotate(12deg);
        }
        .hero-row{
            display:flex;align-items:flex-start;justify-content:space-between;gap:14px;
            position:relative;z-index:1;
        }
        .title{font-size:38px;letter-spacing:-.6px;font-weight:800;color:#f8fafc;}
        .subtitle{margin-top:6px; color:rgba(226,232,240,.85);}

        .hero-actions{display:flex;gap:10px;flex-wrap:wrap;justify-content:flex-end;}
        .btn{
            display:inline-flex;align-items:center;gap:10px;
            padding:10px 14px;border-radius:14px;font-weight:700;text-decoration:none;
            border:1px solid rgba(255,255,255,.16);color:#e2e8f0;
            background:rgba(255,255,255,.06);backdrop-filter: blur(6px);
            transition:.18s ease;white-space:nowrap;
        }
        .btn:hover{transform:translateY(-1px); background:rgba(255,255,255,.10);}
        .btn.primary{
            border:none;background:var(--grad);color:#032033;
            box-shadow:0 16px 35px rgba(46,163,186,.25);
        }
        .btn.primary:hover{filter:saturate(1.05);}

        .toolbar{
            margin-top:18px;max-width:1100px;display:grid;
            grid-template-columns: 1fr auto;gap:12px;align-items:center;
        }
        @media(max-width:760px){ .toolbar{grid-template-columns:1fr;} }

        .search{
            display:flex;align-items:center;gap:10px;background:var(--card);
            border:1px solid var(--line);border-radius:18px;padding:12px 14px;box-shadow:var(--soft);
        }
        .search input{
            width:100%;border:none;outline:none;font-size:14px;color:var(--ink);
        }
        .search .go{
            border:none;cursor:pointer;padding:10px 14px;border-radius:14px;font-weight:800;
            color:#ffffff;background:var(--grad);transition:.18s ease;
        }
        .search .go:hover{transform:translateY(-1px);}

        .chips{display:flex;gap:10px;flex-wrap:wrap;justify-content:flex-end;}
        @media(max-width:760px){ .chips{justify-content:flex-start;} }

        .chip{
            display:inline-flex;align-items:center;gap:8px;padding:9px 12px;border-radius:999px;
            font-size:12px;font-weight:800;border:1px solid var(--line);
            background:var(--card);box-shadow:0 10px 25px rgba(2,6,23,.04);
            color:var(--ink);white-space:nowrap;
        }
        .dot{width:9px;height:9px;border-radius:50%;}
        .d1{background:#38bdf8;}
        .d2{background:#22c55e;}
        .d3{background:#fb923c;}

        .grid{
            margin-top:16px;max-width:1100px;display:grid;
            grid-template-columns:repeat(3, minmax(0, 1fr));gap:14px;
        }
        @media(max-width:1100px){ .grid{grid-template-columns:repeat(2, minmax(0, 1fr));} }
        @media(max-width:760px){ .grid{grid-template-columns:1fr;} }

        .card{
            background:var(--card);border:1px solid var(--line);border-radius:20px;
            padding:16px 16px 14px;box-shadow:var(--shadow);
            position:relative;overflow:hidden;transition:.18s ease;
        }
        .card:hover{transform:translateY(-2px); box-shadow:0 26px 70px rgba(2,6,23,.12);}
        .accent{position:absolute;inset:0 auto 0 0;width:6px;background:var(--grad);}

        .meta{display:flex;justify-content:space-between;align-items:flex-start;gap:10px;padding-left:10px;}
        .rcode{font-weight:900;letter-spacing:.6px;font-size:12px;color:#0ea5e9;}
        .room{
            padding:7px 10px;border-radius:999px;font-size:12px;font-weight:900;
            background:var(--chip);border:1px solid rgba(56,189,248,.25);
            color:#0b3a5d;white-space:nowrap;
        }

        .gname{padding-left:10px;margin-top:10px;font-size:18px;font-weight:900;color:var(--ink);line-height:1.2;}

        .rows{padding-left:10px;margin-top:12px;display:flex;flex-direction:column;gap:10px;color:#334155;font-size:13px;}
        .row{display:flex;gap:10px;align-items:flex-start;}
        .ic{
            width:34px;height:34px;border-radius:12px;display:flex;align-items:center;justify-content:center;
            border:1px solid var(--line);background:#f8fafc;flex:0 0 auto;
        }
        .ic svg{width:18px;height:18px; opacity:.75;}
        .txt{line-height:1.35;}
        .small{color:var(--muted); font-weight:700; font-size:12px; margin-top:2px;}

        .datebar{
            margin-top:14px;padding-left:10px;display:flex;align-items:center;justify-content:space-between;
            gap:10px;flex-wrap:wrap;
        }
        .dates{
            display:inline-flex;align-items:center;gap:8px;padding:8px 10px;border-radius:14px;
            background:var(--chip2);border:1px solid rgba(34,197,94,.20);
            color:#065f46;font-weight:900;font-size:12px;
        }
        .dates svg{width:16px;height:16px; opacity:.8;}

        .tag{
            display:inline-flex;align-items:center;gap:8px;padding:8px 10px;border-radius:14px;
            background:var(--chip3);border:1px solid rgba(251,146,60,.25);
            color:#7c2d12;font-weight:900;font-size:12px;
        }

        .empty{
            margin-top:16px;max-width:1100px;background:#fff;border:1px dashed rgba(15,23,42,.22);
            border-radius:18px;padding:18px;color:#475569;box-shadow:0 12px 26px rgba(2,6,23,.05);
        }

        .actions{
            margin-top:14px;
            padding-left:10px;
            display:flex;
            gap:10px;
            flex-wrap:wrap;
        }
        .act-btn{
            border:none;
            cursor:pointer;
            padding:10px 12px;
            border-radius:14px;
            font-weight:900;
            font-size:12px;
            background:#0b3a5d;
            color:#fff;
            transition:.18s ease;
        }
        .act-btn:hover{transform:translateY(-1px); opacity:.92;}
        .act-btn.danger{background:#b91c1c;}
        .act-btn.light{
            background:#f1f5f9;
            color:#0f172a;
            border:1px solid var(--line);
        }

        .alert{
            max-width:1100px;
            margin-top:14px;
            padding:12px 14px;
            border-radius:16px;
            font-weight:800;
            border:1px solid var(--line);
            box-shadow:var(--soft);
        }
        .alert.ok{background:#ecfdf5;color:#065f46;border-color:rgba(34,197,94,.25);}
        .alert.err{background:#fff1f2;color:#9f1239;border-color:rgba(244,63,94,.25);}

        .modal-backdrop{
            position:fixed;inset:0;
            background:rgba(2,6,23,.55);
            display:none;
            align-items:center;
            justify-content:center;
            padding:18px;
            z-index:9999;
        }
        .modal{
            width:min(720px, 100%);
            background:#fff;
            border-radius:20px;
            box-shadow:0 30px 80px rgba(2,6,23,.35);
            border:1px solid rgba(15,23,42,.12);
            overflow:hidden;
        }
        .modal-head{
            padding:16px 18px;
            background:var(--grad2);
            color:#e2e8f0;
            display:flex;
            align-items:center;
            justify-content:space-between;
            gap:10px;
        }
        .modal-title{font-weight:900;font-size:16px;}
        .modal-close{
            border:none;cursor:pointer;
            width:38px;height:38px;border-radius:14px;
            background:rgba(255,255,255,.12);
            color:#fff;font-weight:900;
        }
        .modal-body{padding:16px 18px;}
        .form-grid{
            display:grid;
            grid-template-columns:1fr 1fr;
            gap:12px;
        }
        @media(max-width:720px){ .form-grid{grid-template-columns:1fr;} }
        .fg{
            display:flex;
            flex-direction:column;
            gap:6px;
        }
        .fg label{font-size:12px;font-weight:900;color:#334155;}
        .fg input, .fg select{
            padding:12px 12px;
            border-radius:14px;
            border:1px solid rgba(15,23,42,.14);
            outline:none;
            font-weight:700;
        }
        .modal-foot{
            padding:14px 18px 18px;
            display:flex;
            gap:10px;
            justify-content:flex-end;
            flex-wrap:wrap;
        }
        .m-btn{
            border:none;cursor:pointer;
            padding:12px 14px;
            border-radius:14px;
            font-weight:900;
        }
        .m-btn.save{background:var(--grad); color:#032033;}
        .m-btn.cancel{background:#e2e8f0; color:#0f172a;}
    </style>
</head>

<body>

<div class="app">

    <aside class="sidebar">
        <div class="brand">
            <div class="brand-icon">
                <svg viewBox="0 0 24 24" fill="none">
                    <path d="M3 7c2.5 1.8 5.1 1.8 7.6 0S15.7 5.2 18.2 7 21 8.8 21 8.8"
                          stroke="white" stroke-width="2" stroke-linecap="round"/>
                    <path d="M3 12c2.5 1.8 5.1 1.8 7.6 0s5.1-1.8 7.6 0S21 13.8 21 13.8"
                          stroke="white" stroke-width="2" stroke-linecap="round" opacity=".9"/>
                    <path d="M3 17c2.5 1.8 5.1 1.8 7.6 0s5.1-1.8 7.6 0S21 18.8 21 18.8"
                          stroke="white" stroke-width="2" stroke-linecap="round" opacity=".75"/>
                </svg>
            </div>
            <div>
                <h2>Ocean View</h2>
                <small>Resort Management</small>
            </div>
        </div>

        <nav class="nav">
            <a href="dashboard.jsp">Dashboard</a>
            <a href="new_reservation.jsp">New Reservation</a>
            <a class="active" href="reservations.jsp">Reservations</a>
            <a href="billing.jsp">Billing</a>
            <a href="help.jsp">Help</a>
        </nav>

        <div class="sidebar-footer">
            <a class="logout" href="LogoutServlet">Sign Out</a>
        </div>
    </aside>

    <main class="main">

        <div class="hero">
            <div class="hero-row">
                <div>
                    <div class="title">Reservations</div>
                    <div class="subtitle">Search, review, and manage guest bookings with a clean overview.</div>
                </div>

                <div class="hero-actions">
                    <a class="btn primary" href="new_reservation.jsp">
                        <span>＋</span><span>New Reservation</span>
                    </a>
                </div>
            </div>
        </div>

        <% if (msgOk != null) { %>
            <div class="alert ok"><%= msgOk %></div>
        <% } %>
        <% if (msgErr != null) { %>
            <div class="alert err"><%= msgErr %></div>
        <% } %>

        <%
            int total = 0;
            int matched = 0;

            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                try (Connection con = DriverManager.getConnection(URL, USER, PASS)) {

                    try (PreparedStatement psT = con.prepareStatement("SELECT COUNT(*) FROM reservations");
                         ResultSet rsT = psT.executeQuery()) {
                        if (rsT.next()) total = rsT.getInt(1);
                    }

                    String sqlCount =
                            "SELECT COUNT(*) FROM reservations " +
                            "WHERE (? = '' " +
                            "   OR CAST(id AS CHAR) LIKE ? " +
                            "   OR reservation_code LIKE ? " +
                            "   OR guest_name LIKE ? " +
                            "   OR contact LIKE ?)";

                    try (PreparedStatement psC = con.prepareStatement(sqlCount)) {
                        String like = "%" + q + "%";
                        psC.setString(1, q);
                        psC.setString(2, like);
                        psC.setString(3, like);
                        psC.setString(4, like);
                        psC.setString(5, like);

                        try (ResultSet rsC = psC.executeQuery()) {
                            if (rsC.next()) matched = rsC.getInt(1);
                        }
                    }
                }
            } catch (Exception ignore) {}
        %>

        <div class="toolbar">
            <form class="search" method="get" action="<%= request.getContextPath() %>/reservations.jsp">
                <svg width="18" height="18" viewBox="0 0 24 24" fill="none" style="opacity:.7;">
                    <path d="M10.5 18a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15Z" stroke="#64748b" stroke-width="2"/>
                    <path d="M16.5 16.5 21 21" stroke="#64748b" stroke-width="2" stroke-linecap="round"/>
                </svg>
                <input type="text" name="q" value="<%= q %>" placeholder="Search by ID, RES-xxx, guest name, or contact..." />
                <button class="go" type="submit">Search</button>
            </form>

            <div class="chips">
                <div class="chip"><span class="dot d1"></span>Total: <%= total %></div>
                <div class="chip"><span class="dot d2"></span>Matched: <%= matched %></div>
                <div class="chip"><span class="dot d3"></span>Query: <%= (q.isEmpty() ? "All" : q) %></div>
            </div>
        </div>

        <div class="grid">
            <%
                boolean foundAny = false;

                try {
                    Class.forName("com.mysql.cj.jdbc.Driver");
                    try (Connection con = DriverManager.getConnection(URL, USER, PASS)) {

                        String sql =
                                "SELECT id, reservation_code, guest_name, address, contact, room_type, check_in, check_out " +
                                "FROM reservations " +
                                "WHERE (? = '' " +
                                "   OR CAST(id AS CHAR) LIKE ? " +
                                "   OR reservation_code LIKE ? " +
                                "   OR guest_name LIKE ? " +
                                "   OR contact LIKE ?) " +
                                "ORDER BY id DESC";

                        try (PreparedStatement ps = con.prepareStatement(sql)) {
                            String like = "%" + q + "%";

                            ps.setString(1, q);
                            ps.setString(2, like);
                            ps.setString(3, like);
                            ps.setString(4, like);
                            ps.setString(5, like);

                            try (ResultSet rs = ps.executeQuery()) {
                                while (rs.next()) {
                                    foundAny = true;

                                    String id = rs.getString("id");
                                    String resCode = rs.getString("reservation_code");

                                    String codeToShow = (resCode != null && !resCode.trim().isEmpty())
                                            ? resCode
                                            : ("ID-" + id);

                                    String guest   = rs.getString("guest_name");
                                    String address = rs.getString("address");
                                    String contact = rs.getString("contact");
                                    String room    = rs.getString("room_type");

                                    Date inDate  = rs.getDate("check_in");
                                    Date outDate = rs.getDate("check_out");

                                    String inStr  = (inDate  != null ? inDate.toString()  : "");
                                    String outStr = (outDate != null ? outDate.toString() : "");

                                    String guestJS   = (guest   == null ? "" : guest.replace("\\","\\\\").replace("'","\\'"));
                                    String addressJS = (address == null ? "" : address.replace("\\","\\\\").replace("'","\\'"));
                                    String contactJS = (contact == null ? "" : contact.replace("\\","\\\\").replace("'","\\'"));
                                    String roomJS    = (room    == null ? "" : room.replace("\\","\\\\").replace("'","\\'"));
            %>

            <div class="card">
                <div class="accent"></div>

                <div class="meta">
                    <div class="rcode"><%= codeToShow %></div>
                    <div class="room"><%= room %></div>
                </div>

                <div class="gname"><%= guest %></div>

                <div class="rows">
                    <div class="row">
                        <div class="ic">
                            <svg viewBox="0 0 24 24" fill="none">
                                <path d="M12 12a4 4 0 1 0-8 0 4 4 0 0 0 8 0Z" stroke="#64748b" stroke-width="2"/>
                                <path d="M2 21a10 10 0 0 1 20 0" stroke="#64748b" stroke-width="2" stroke-linecap="round"/>
                            </svg>
                        </div>
                        <div class="txt">
                            <div style="font-weight:900;">Guest</div>
                            <div class="small"><%= guest %></div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="ic">
                            <svg viewBox="0 0 24 24" fill="none">
                                <path d="M12 21s7-4.5 7-11a7 7 0 1 0-14 0c0 6.5 7 11 7 11Z" stroke="#64748b" stroke-width="2"/>
                                <path d="M12 10.5a2 2 0 1 0 0-4 2 2 0 0 0 0 4Z" stroke="#64748b" stroke-width="2"/>
                            </svg>
                        </div>
                        <div class="txt">
                            <div style="font-weight:900;">Address</div>
                            <div class="small"><%= address %></div>
                        </div>
                    </div>

                    <div class="row">
                        <div class="ic">
                            <svg viewBox="0 0 24 24" fill="none">
                                <path d="M6.5 3h3l1 5-2 1.5c1.5 3 3.9 5.4 6.9 6.9L17 14.5l5 1v3c0 1.1-.9 2-2 2C10.8 20.5 3.5 13.2 3.5 4c0-1.1.9-2 2-2Z"
                                      stroke="#64748b" stroke-width="2" stroke-linejoin="round"/>
                            </svg>
                        </div>
                        <div class="txt">
                            <div style="font-weight:900;">Contact</div>
                            <div class="small"><%= contact %></div>
                        </div>
                    </div>
                </div>

                <div class="datebar">
                    <div class="dates">
                        <svg viewBox="0 0 24 24" fill="none">
                            <path d="M7 3v3M17 3v3M4 8h16" stroke="#065f46" stroke-width="2" stroke-linecap="round"/>
                            <path d="M6 5h12a2 2 0 0 1 2 2v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2Z"
                                  stroke="#065f46" stroke-width="2"/>
                        </svg>
                        <span><%= inDate %> → <%= outDate %></span>
                    </div>

                    <div class="tag">
                        Stay
                        <span style="font-weight:900;">
                            <%
                                long nights = 0;
                                try {
                                    if (inDate != null && outDate != null) {
                                        long ms = outDate.getTime() - inDate.getTime();
                                        nights = ms / (1000L*60*60*24);
                                    }
                                } catch (Exception ex) { nights = 0; }
                            %>
                            <%= (nights <= 0 ? "—" : (nights + " night(s)")) %>
                        </span>
                    </div>
                </div>

                <div class="actions">
                    <button class="act-btn light" type="button"
                        onclick="openEdit(
                            '<%= id %>',
                            '<%= guestJS %>',
                            '<%= addressJS %>',
                            '<%= contactJS %>',
                            '<%= roomJS %>',
                            '<%= inStr %>',
                            '<%= outStr %>',
                            '<%= codeToShow.replace("\\","\\\\").replace("'","\\'") %>'
                        )">
                        ✏️ Edit
                    </button>

                    <form method="post" action="reservations.jsp" onsubmit="return confirm('Delete this reservation?');" style="display:inline;">
                        <input type="hidden" name="action" value="delete"/>
                        <input type="hidden" name="id" value="<%= id %>"/>
                        <button class="act-btn danger" type="submit">🗑 Delete</button>
                    </form>
                </div>
            </div>

            <%
                                }
                            }
                        }
                    }
                } catch (Exception e) {
            %>
                <div class="empty">DB Error: <%= e.getMessage() %></div>
            <%
                }

                if (!foundAny) {
            %>
                <div class="empty">No reservations found. Try a different search keyword.</div>
            <%
                }
            %>
        </div>

        <!-- ✅ Edit Modal -->
        <div class="modal-backdrop" id="editModal">
            <div class="modal">
                <div class="modal-head">
                    <div class="modal-title" id="mTitle">Edit Reservation</div>
                    <button class="modal-close" type="button" onclick="closeEdit()">✕</button>
                </div>

                <form method="post" action="reservations.jsp">
                    <div class="modal-body">
                        <input type="hidden" name="action" value="update"/>
                        <input type="hidden" name="id" id="mId"/>

                        <div class="form-grid">
                            <div class="fg">
                                <label>Guest Name *</label>
                                <input type="text" name="guest_name" id="mGuest" required/>
                            </div>

                            <div class="fg">
                                <label>Contact *</label>
                                <input type="text" name="contact" id="mContact" required/>
                            </div>

                            <div class="fg" style="grid-column:1/-1;">
                                <label>Address</label>
                                <input type="text" name="address" id="mAddress"/>
                            </div>

                            <div class="fg">
                                <label>Room Type *</label>
                                <select name="room_type" id="mRoom" required>
                                    <option value="">-- Select --</option>
                                    <option>Ocean Suite</option>
                                    <option>Beach Villa</option>
                                    <option>Deluxe Room</option>
                                    <option>Standard Room</option>
                                </select>
                            </div>

                            <div class="fg">
                                <label>Check In *</label>
                                <input type="date" name="check_in" id="mIn" required/>
                            </div>

                            <div class="fg">
                                <label>Check Out *</label>
                                <input type="date" name="check_out" id="mOut" required/>
                            </div>
                        </div>
                    </div>

                    <div class="modal-foot">
                        <button class="m-btn cancel" type="button" onclick="closeEdit()">Cancel</button>
                        <button class="m-btn save" type="submit">Update Reservation</button>
                    </div>
                </form>
            </div>
        </div>

        <script>
            function openEdit(id, guest, address, contact, room, checkIn, checkOut, code){
                document.getElementById("mId").value = id;
                document.getElementById("mGuest").value = guest || "";
                document.getElementById("mAddress").value = address || "";
                document.getElementById("mContact").value = contact || "";
                document.getElementById("mRoom").value = room || "";
                document.getElementById("mIn").value = checkIn || "";
                document.getElementById("mOut").value = checkOut || "";
                document.getElementById("mTitle").innerText = "Edit Reservation • " + (code || ("ID-" + id));
                document.getElementById("editModal").style.display = "flex";
            }

            function closeEdit(){
                document.getElementById("editModal").style.display = "none";
            }

            document.getElementById("editModal").addEventListener("click", function(e){
                if(e.target === this) closeEdit();
            });

            // ✅ CLIENT-SIDE VALIDATIONS FOR EDIT (NO UI CHANGES)
            function normalizeContact(v){
                return (v || "").replace(/[\s-]/g, "");
            }
            function validGuestName(v){
                v = (v || "").trim();
                if(v.length < 3 || v.length > 60) return false;
                return /^[A-Za-z][A-Za-z .'-]{1,58}[A-Za-z]$/.test(v);
            }
            function validContact(v){
                const x = normalizeContact(v);
                return /^07\d{8}$/.test(x) || /^\+94\d{9}$/.test(x);
            }
            function nightsBetween(inD, outD){
                const a = new Date(inD + "T00:00:00");
                const b = new Date(outD + "T00:00:00");
                return Math.floor((b - a) / (1000*60*60*24));
            }

            document.querySelector("#editModal form").addEventListener("submit", function(e){
                const guest = document.getElementById("mGuest").value;
                const contact = document.getElementById("mContact").value;
                const address = document.getElementById("mAddress").value;
                const room = document.getElementById("mRoom").value;
                const checkIn = document.getElementById("mIn").value;
                const checkOut = document.getElementById("mOut").value;

                if(!guest || guest.trim()===""){
                    alert("Guest Name is required.");
                    e.preventDefault(); return;
                }
                if(!validGuestName(guest)){
                    alert("Guest Name: letters only (spaces, . ' - allowed), 3–60 chars.");
                    e.preventDefault(); return;
                }

                if(!contact || contact.trim()===""){
                    alert("Contact is required.");
                    e.preventDefault(); return;
                }
                if(!validContact(contact)){
                    alert("Contact must be 07XXXXXXXX or +94XXXXXXXXX.");
                    e.preventDefault(); return;
                }

                if(address && address.length > 120){
                    alert("Address max length is 120 characters.");
                    e.preventDefault(); return;
                }

                const allowed = ["Ocean Suite","Beach Villa","Deluxe Room","Standard Room"];
                if(!room){
                    alert("Room Type is required.");
                    e.preventDefault(); return;
                }
                if(!allowed.includes(room)){
                    alert("Invalid Room Type selected.");
                    e.preventDefault(); return;
                }

                if(!checkIn){
                    alert("Check In date is required.");
                    e.preventDefault(); return;
                }
                if(!checkOut){
                    alert("Check Out date is required.");
                    e.preventDefault(); return;
                }
                if(checkOut <= checkIn){
                    alert("Check Out must be after Check In.");
                    e.preventDefault(); return;
                }

                const nights = nightsBetween(checkIn, checkOut);
                if(nights < 1 || nights > 30){
                    alert("Stay length must be between 1 and 30 nights.");
                    e.preventDefault(); return;
                }

                // normalize before submit
                document.getElementById("mContact").value = normalizeContact(contact);
            });
        </script>

    </main>
</div>

</body>
</html>