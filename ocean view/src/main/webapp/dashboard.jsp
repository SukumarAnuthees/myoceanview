<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.time.*" %>
<%@ page import="java.time.format.DateTimeFormatter" %>
<%
    // ✅ Prevent caching (important after logout)
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // ✅ Session protection
    if (session.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String username = (String) session.getAttribute("username");

    // ✅ DB Config
    String URL = "jdbc:mysql://localhost:3306/ocean_db?useSSL=false&allowPublicKeyRetrieval=true&serverTimezone=Asia/Colombo";
    String USER = "root";
    String PASS = "";

    int totalReservations = 0;
    int upcomingReservations = 0;
    int activeGuests = 0;
    int completedReservations = 0;

    // ✅ Today label (Asia/Colombo)
    ZoneId zone = ZoneId.of("Asia/Colombo");
    LocalDate today = LocalDate.now(zone);
    String todayLabel = today.format(DateTimeFormatter.ofPattern("dd MMM yyyy"));

    try {
        Class.forName("com.mysql.cj.jdbc.Driver");
        try (Connection con = DriverManager.getConnection(URL, USER, PASS)) {

            // ✅ Total reservations
            try (PreparedStatement ps = con.prepareStatement("SELECT COUNT(*) FROM reservations");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) totalReservations = rs.getInt(1);
            }

            // ✅ Upcoming (check_in today or future)
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COUNT(*) FROM reservations WHERE check_in >= CURDATE()");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) upcomingReservations = rs.getInt(1);
            }

            // ✅ Active guests (today between check-in and check-out)
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COUNT(*) FROM reservations WHERE check_in <= CURDATE() AND check_out > CURDATE()");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) activeGuests = rs.getInt(1);
            }

            // ✅ Completed (check_out <= today)
            try (PreparedStatement ps = con.prepareStatement(
                    "SELECT COUNT(*) FROM reservations WHERE check_out <= CURDATE()");
                 ResultSet rs = ps.executeQuery()) {
                if (rs.next()) completedReservations = rs.getInt(1);
            }
        }
    } catch (Exception e) {
        // keep defaults
    }
%>
<!DOCTYPE html>
<html>
<head>
    <title>Dashboard - Ocean View Resort</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap" rel="stylesheet">

    <style>
        *{margin:0;padding:0;box-sizing:border-box;font-family:'Poppins',sans-serif;}
        body{background:#f4f7fb;color:#0f172a;}
        .app{display:flex;min-height:100vh;}

        /* ===== Sidebar ===== */
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

        /* ===== Main ===== */
        .main{flex:1;padding:34px 34px 60px;}
        .headline h1{font-size:46px;letter-spacing:-.7px;}
        .headline p{margin-top:6px;color:#64748b;font-size:16px;}

        .today-pill{
            margin-top:14px;
            display:inline-flex;
            align-items:center;
            gap:8px;
            padding:10px 14px;
            border-radius:999px;
            background:rgba(14,165,233,.10);
            border:1px solid rgba(14,165,233,.18);
            color:#0f172a;
            font-weight:700;
            font-size:13px;
        }
        .dot{
            width:10px;height:10px;border-radius:50%;
            background:#22c55e;
            box-shadow:0 0 0 4px rgba(34,197,94,.15);
        }

        /* ===== Stat cards ===== */
        .stats{
            margin-top:22px;
            display:grid;
            grid-template-columns: repeat(4, minmax(0,1fr));
            gap:18px;
        }
        .card{
            background:#fff;border-radius:16px;
            box-shadow:0 10px 25px rgba(15,23,42,.08);
            padding:20px 20px;
            border:1px solid rgba(15,23,42,.06);
            display:flex;justify-content:space-between;gap:12px;
        }
        .card .label{color:#64748b;font-size:14px;}
        .card .value{font-size:34px;font-weight:800;margin-top:10px;}
        .pill{
            width:46px;height:46px;border-radius:14px;
            display:grid;place-items:center;
            background:#f1f5f9;
        }
        .pill svg{width:22px;height:22px;}

        /* ===== Section title ===== */
        .section-title{
            margin-top:34px;
            font-size:28px;
            font-weight:800;
            color:#0f172a;
        }

        /* ===== Quick actions ===== */
        .actions{
            margin-top:14px;
            display:grid;
            grid-template-columns: repeat(3, minmax(0,1fr));
            gap:18px;
        }
        .action{
            background:#fff;border-radius:18px;
            padding:26px 26px;
            border:1px solid rgba(15,23,42,.06);
            box-shadow:0 10px 25px rgba(15,23,42,.08);
            text-decoration:none;color:inherit;
            transition:.2s;
            display:flex;gap:18px;align-items:flex-start;
        }
        .action:hover{transform:translateY(-2px);}
        .action .badge{
            width:62px;height:62px;border-radius:16px;
            background:linear-gradient(135deg,#0b3a5d,#2e9bb7);
            display:grid;place-items:center;
            box-shadow:0 12px 26px rgba(11,58,93,.22);
            flex:0 0 auto;
        }
        .badge svg{width:26px;height:26px;}
        .action h3{font-size:20px;margin-top:2px;font-weight:800;}
        .action p{color:#64748b;margin-top:8px;font-size:14px;font-weight:500;}

        /* ===== Table ===== */
        .table-wrap{
            margin-top:14px;
            background:#fff;border-radius:18px;
            border:1px solid rgba(15,23,42,.06);
            box-shadow:0 10px 25px rgba(15,23,42,.08);
            overflow:hidden;
        }
        table{width:100%;border-collapse:collapse;}
        thead th{
            text-align:left;
            padding:18px 18px;
            color:#64748b;
            font-weight:700;
            font-size:13px;
            background:#fbfdff;
            border-bottom:1px solid rgba(15,23,42,.06);
        }
        tbody td{
            padding:18px 18px;
            border-bottom:1px solid rgba(15,23,42,.06);
            font-size:14px;
            font-weight:600;
            vertical-align:middle;
        }
        tbody tr:last-child td{border-bottom:none;}
        .idtag{color:#0ea5e9;font-weight:800;letter-spacing:.4px;}
        .muted{color:#64748b;font-weight:600}

        .status{
            display:inline-flex;
            align-items:center;
            padding:6px 10px;
            border-radius:999px;
            font-size:12px;
            font-weight:800;
            border:1px solid rgba(15,23,42,.08);
            background:#f8fafc;
        }
        .status.active{background:rgba(34,197,94,.10); border-color:rgba(34,197,94,.25); color:#166534;}
        .status.upcoming{background:rgba(245,158,11,.12); border-color:rgba(245,158,11,.25); color:#92400e;}
        .status.done{background:rgba(148,163,184,.18); border-color:rgba(148,163,184,.30); color:#334155;}

        @media (max-width: 1100px){
            .stats{grid-template-columns: repeat(2, minmax(0,1fr));}
            .actions{grid-template-columns: repeat(2, minmax(0,1fr));}
        }
        @media (max-width: 820px){
            .sidebar{display:none;}
            .main{padding:22px;}
            .headline h1{font-size:34px;}
            .actions{grid-template-columns: 1fr;}
            .stats{grid-template-columns: 1fr;}
        }
    </style>
</head>
<body>

<div class="app">

    <!-- ===== Sidebar ===== -->
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
            <a class="active" href="dashboard.jsp">Dashboard</a>
            <a href="new_reservation.jsp">New Reservation</a>
            <a href="reservations.jsp">Reservations</a>
            <a href="billing.jsp">Billing</a>
            <a href="help.jsp">Help</a>
        </nav>

        <div class="sidebar-footer">
            <a class="logout" href="LogoutServlet">Sign Out</a>
        </div>
    </aside>

    <!-- ===== Main ===== -->
    <main class="main">
        <div class="headline">
            <h1>Good day, <%= username %></h1>
            <p>Welcome to the Ocean View Resort management system.</p>

            <div class="today-pill">
                <span class="dot"></span>
                Today: <%= todayLabel %> (Asia/Colombo)
            </div>
        </div>

        <!-- ===== Stats ===== -->
        <section class="stats">

            <!-- Total Reservations -->
            <div class="card">
                <div>
                    <div class="label">Total Reservations</div>
                    <div class="value"><%= totalReservations %></div>
                </div>
                <div class="pill">
                    <svg viewBox="0 0 24 24" fill="none">
                        <path d="M7 3v3M17 3v3M4 8h16" stroke="#0ea5e9" stroke-width="2" stroke-linecap="round"/>
                        <path d="M6 5h12a2 2 0 0 1 2 2v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2Z"
                              stroke="#0ea5e9" stroke-width="2"/>
                    </svg>
                </div>
            </div>

            <!-- Active Guests -->
            <div class="card">
                <div>
                    <div class="label">Active Guests</div>
                    <div class="value"><%= activeGuests %></div>
                </div>
                <div class="pill">
                    <svg viewBox="0 0 24 24" fill="none">
                        <path d="M16 11a4 4 0 1 0-8 0 4 4 0 0 0 8 0Z" stroke="#22c55e" stroke-width="2"/>
                        <path d="M4 21a8 8 0 0 1 16 0" stroke="#22c55e" stroke-width="2" stroke-linecap="round"/>
                    </svg>
                </div>
            </div>

            <!-- Completed -->
            <div class="card">
                <div>
                    <div class="label">Completed</div>
                    <div class="value"><%= completedReservations %></div>
                </div>
                <div class="pill">
                    <svg viewBox="0 0 24 24" fill="none">
                        <path d="M20 7 10 17l-5-5" stroke="#22c55e" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                </div>
            </div>

            <!-- Upcoming -->
            <div class="card">
                <div>
                    <div class="label">Upcoming</div>
                    <div class="value"><%= upcomingReservations %></div>
                </div>
                <div class="pill">
                    <svg viewBox="0 0 24 24" fill="none">
                        <path d="M4 17l6-6 4 4 6-8" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                        <path d="M20 7v6h-6" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                </div>
            </div>

        </section>

        <!-- ===== Quick Actions ===== -->
        <h2 class="section-title">Quick Actions</h2>
        <section class="actions">

            <a class="action" href="new_reservation.jsp">
                <div class="badge">
                    <svg viewBox="0 0 24 24" fill="none">
                        <path d="M12 5v14M5 12h14" stroke="white" stroke-width="2" stroke-linecap="round"/>
                    </svg>
                </div>
                <div>
                    <h3>New Reservation</h3>
                    <p>Create booking with strict validation + overlap protection</p>
                </div>
            </a>

            <a class="action" href="reservations.jsp">
                <div class="badge">
                    <svg viewBox="0 0 24 24" fill="none">
                        <path d="M10.5 18a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15Z" stroke="white" stroke-width="2"/>
                        <path d="M16.5 16.5 21 21" stroke="white" stroke-width="2" stroke-linecap="round"/>
                    </svg>
                </div>
                <div>
                    <h3>View Reservations</h3>
                    <p>Search, filter, and manage bookings</p>
                </div>
            </a>

            <a class="action" href="billing.jsp">
                <div class="badge">
                    <svg viewBox="0 0 24 24" fill="none">
                        <path d="M7 3h7l3 3v15a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2Z"
                              stroke="white" stroke-width="2" stroke-linejoin="round"/>
                        <path d="M14 3v4h4" stroke="white" stroke-width="2" stroke-linejoin="round"/>
                        <path d="M8 12h8M8 16h8" stroke="white" stroke-width="2" stroke-linecap="round"/>
                    </svg>
                </div>
                <div>
                    <h3>Generate Bill</h3>
                    <p>Calculate guest charges</p>
                </div>
            </a>

        </section>

        <!-- ===== Recent Reservations ===== -->
        <h2 class="section-title">Recent Reservations</h2>
        <div class="table-wrap">
            <table>
                <thead>
                <tr>
                    <th>ID</th>
                    <th>Guest</th>
                    <th>Room</th>
                    <th>Check-in</th>
                    <th>Check-out</th>
                    <th>Status</th>
                </tr>
                </thead>
                <tbody>
                <%
                    boolean hasRows = false;

                    try {
                        Class.forName("com.mysql.cj.jdbc.Driver");
                        try (Connection con = DriverManager.getConnection(URL, USER, PASS);
                             PreparedStatement ps = con.prepareStatement(
                                     "SELECT id, " +
                                     "  COALESCE(reservation_code, CONCAT('RES-', LPAD(id,3,'0'))) AS code, " +
                                     "  guest_name, room_type, check_in, check_out " +
                                     "FROM reservations ORDER BY id DESC LIMIT 5");
                             ResultSet rs = ps.executeQuery()) {

                            while (rs.next()) {
                                hasRows = true;

                                Date inD  = rs.getDate("check_in");
                                Date outD = rs.getDate("check_out");

                                String statusClass = "upcoming";
                                String statusText  = "Upcoming";

                                // Active: check_in <= today AND check_out > today
                                // Completed: check_out <= today
                                java.sql.Date t = java.sql.Date.valueOf(today);
                                if (outD != null && !outD.after(t)) {
                                    statusClass = "done";
                                    statusText  = "Completed";
                                } else if (inD != null && !inD.after(t) && outD != null && outD.after(t)) {
                                    statusClass = "active";
                                    statusText  = "Active";
                                }
                %>
                    <tr>
                        <td class="idtag"><%= rs.getString("code") %></td>
                        <td><%= rs.getString("guest_name") %></td>
                        <td class="muted"><%= rs.getString("room_type") %></td>
                        <td class="muted"><%= rs.getDate("check_in") %></td>
                        <td class="muted"><%= rs.getDate("check_out") %></td>
                        <td><span class="status <%= statusClass %>"><%= statusText %></span></td>
                    </tr>
                <%
                            }
                        }
                    } catch (Exception e) {
                %>
                    <tr><td colspan="6" class="muted">DB Error: <%= e.getMessage() %></td></tr>
                <%
                    }

                    if (!hasRows) {
                %>
                    <tr><td colspan="6" class="muted">No reservations yet. Create one to see it here.</td></tr>
                <%
                    }
                %>
                </tbody>
            </table>
        </div>

    </main>
</div>

</body>
</html>