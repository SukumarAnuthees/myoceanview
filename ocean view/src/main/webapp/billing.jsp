<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%@ page import="java.sql.*" %>
<%@ page import="java.time.*" %>
<%@ page import="java.time.temporal.ChronoUnit" %>
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

    String q = request.getParameter("q");
    if (q == null) q = "";
    q = q.trim().replaceAll("\\s+"," ");

    // Result fields
    boolean found = false;
    String reservationCode = "";
    String guestName = "";
    String contact = "";
    String address = "";
    String roomType = "";
    LocalDate checkIn = null;
    LocalDate checkOut = null;

    int nights = 0;
    double ratePerNight = 0;
    double subtotal = 0;
    double serviceCharge = 0;
    double total = 0;

    String error = null;

    // ✅ Room rates (you can edit)
    java.util.Map<String, Double> rates = new java.util.HashMap<>();
    rates.put("Ocean Suite", 20000.0);
    rates.put("Beach Villa", 30000.0);
    rates.put("Deluxe Room", 15000.0);
    rates.put("Standard Room", 10000.0);

    if (!q.isEmpty()) {
        try {
            Class.forName("com.mysql.cj.jdbc.Driver");
            try (Connection con = DriverManager.getConnection(URL, USER, PASS)) {

                String sql =
                        "SELECT id, reservation_code, guest_name, contact, address, room_type, check_in, check_out " +
                        "FROM reservations " +
                        "WHERE reservation_code = ? OR id = ? " +
                        "LIMIT 1";

                int maybeId = -1;
                try { maybeId = Integer.parseInt(q.replaceAll("[^0-9]", "")); } catch(Exception ignore){}

                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, q);
                    ps.setInt(2, maybeId);

                    try (ResultSet rs = ps.executeQuery()) {
                        if (rs.next()) {
                            found = true;

                            reservationCode = rs.getString("reservation_code");
                            if (reservationCode == null || reservationCode.trim().isEmpty()) {
                                // Fallback: RES-001 style from id if reservation_code is empty
                                reservationCode = "RES-" + String.format("%03d", rs.getInt("id"));
                            }

                            guestName = rs.getString("guest_name");
                            contact = rs.getString("contact");
                            address = rs.getString("address");
                            roomType = rs.getString("room_type");

                            Date inD = rs.getDate("check_in");
                            Date outD = rs.getDate("check_out");
                            if (inD != null) checkIn = inD.toLocalDate();
                            if (outD != null) checkOut = outD.toLocalDate();

                            // Billing math
                            if (checkIn != null && checkOut != null) {
                                nights = (int) ChronoUnit.DAYS.between(checkIn, checkOut);
                                if (nights < 1) nights = 1;
                            } else {
                                nights = 1;
                            }

                            ratePerNight = rates.getOrDefault(roomType, 12000.0);
                            subtotal = ratePerNight * nights;

                            // Service charge 10%
                            serviceCharge = subtotal * 0.10;

                            total = subtotal + serviceCharge;

                        } else {
                            error = "No reservation found for: " + q;
                        }
                    }
                }
            }
        } catch (Exception e) {
            error = "DB Error: " + e.getMessage();
        }
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>Billing - Ocean View Resort</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap" rel="stylesheet">

    <style>
        *{margin:0;padding:0;box-sizing:border-box;font-family:'Poppins',sans-serif;}
        body{background:#f4f7fb;color:#0f172a;}
        .app{display:flex;min-height:100vh;}

        /* ===== Sidebar (MATCH dashboard.jsp) ===== */
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
        .brand-icon svg{width:24px;height:24px;}
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

        .sidebar-footer{position:absolute;left:18px;right:18px;bottom:18px;}
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
        .headline h1{font-size:40px;letter-spacing:-.6px;}
        .headline p{margin-top:6px;color:#64748b;font-size:16px;}

        /* ===== Search Card ===== */
        .search-card{
            margin-top:22px;
            background:#fff;
            border:1px solid rgba(15,23,42,.06);
            border-radius:18px;
            box-shadow:0 12px 28px rgba(15,23,42,.08);
            padding:18px;
            max-width:860px;
        }
        .search-grid{
            display:grid;
            grid-template-columns: 1fr 140px;
            gap:14px;
            align-items:end;
        }
        label{font-weight:700;font-size:14px;color:#0f172a;}
        .hint{font-size:12px;color:#64748b;margin-top:6px;}
        input{
            width:100%;
            padding:13px 14px;
            margin-top:8px;
            border-radius:12px;
            border:1px solid #cbd5e1;
            outline:none;
            transition:.2s;
            background:#fff;
        }
        input:focus{border-color:#2e9bb7;box-shadow:0 0 0 3px rgba(46,155,183,.18);}
        .btn{
            border:none;
            border-radius:12px;
            padding:13px 14px;
            cursor:pointer;
            font-weight:800;
            color:#fff;
            background:linear-gradient(135deg,#0b3a5d,#2e9bb7);
            display:flex;align-items:center;justify-content:center;gap:10px;
            box-shadow:0 12px 26px rgba(11,58,93,.18);
            transition:.2s;
        }
        .btn:hover{transform:translateY(-1px);opacity:.98;}
        .btn svg{width:18px;height:18px;}

        .msg{
            max-width:860px;
            margin-top:14px;
            padding:12px 14px;
            border-radius:12px;
            font-size:14px;
            font-weight:600;
        }
        .msg.err{background:#fef2f2;border:1px solid #fecaca;color:#991b1b;}
        .msg.ok{background:#ecfdf5;border:1px solid #bbf7d0;color:#166534;}

        /* ===== Invoice / Bill ===== */
        .bill-wrap{
            max-width:860px;
            margin-top:18px;
            display:grid;
            grid-template-columns: 1fr;
            gap:16px;
        }
        .bill{
            background:#fff;
            border:1px solid rgba(15,23,42,.06);
            border-radius:18px;
            box-shadow:0 12px 28px rgba(15,23,42,.08);
            overflow:hidden;
        }
        .bill-top{
            padding:18px 20px;
            display:flex;
            justify-content:space-between;
            align-items:flex-start;
            gap:12px;
            background:linear-gradient(135deg, rgba(11,58,93,.08), rgba(46,155,183,.10));
            border-bottom:1px solid rgba(15,23,42,.06);
        }
        .bill-title h2{font-size:22px;font-weight:900;}
        .bill-title p{margin-top:6px;color:#64748b;font-weight:600;font-size:13px;}
        .tag{
            padding:8px 12px;
            border-radius:999px;
            background:#0b3a5d;
            color:#fff;
            font-weight:900;
            letter-spacing:.5px;
            font-size:12px;
            white-space:nowrap;
        }
        .bill-body{padding:18px 20px;}
        .grid{
            display:grid;
            grid-template-columns: 1fr 1fr;
            gap:14px;
        }
        .box{
            border:1px solid rgba(15,23,42,.06);
            border-radius:14px;
            padding:14px;
            background:#fbfdff;
        }
        .box .k{font-size:12px;color:#64748b;font-weight:700;}
        .box .v{margin-top:6px;font-size:15px;font-weight:800;color:#0f172a;}
        .box .v.small{font-size:14px;font-weight:700;color:#0f172a;}

        .charges{
            margin-top:16px;
            border-top:1px dashed rgba(15,23,42,.16);
            padding-top:16px;
            display:grid;
            grid-template-columns: 1fr;
            gap:10px;
        }
        .row{
            display:flex;justify-content:space-between;align-items:center;
            font-weight:700;color:#0f172a;
        }
        .row span{color:#64748b;font-weight:800;}
        .row.total{
            margin-top:6px;
            padding-top:10px;
            border-top:1px solid rgba(15,23,42,.08);
            font-size:18px;
            font-weight:900;
        }
        .row.total span{color:#0f172a;}

        .bill-actions{
            padding:16px 20px;
            display:flex;
            gap:12px;
            justify-content:flex-end;
            border-top:1px solid rgba(15,23,42,.06);
            background:#fff;
        }
        .btn-ghost{
            padding:12px 14px;
            border-radius:12px;
            border:1px solid rgba(15,23,42,.12);
            background:#fff;
            font-weight:900;
            color:#0b3a5d;
            cursor:pointer;
            transition:.2s;
        }
        .btn-ghost:hover{transform:translateY(-1px);box-shadow:0 10px 22px rgba(15,23,42,.06);}
        .btn-ghost svg{width:18px;height:18px;vertical-align:-3px;margin-right:8px;}

        /* ===== Print ===== */
        @media print {
            body{background:#fff;}
            .sidebar, .search-card, .bill-actions, .headline p{display:none !important;}
            .main{padding:0 !important;}
            .bill{box-shadow:none !important;border:1px solid #ddd !important;}
            .bill-top{background:#fff !important;}
        }

        /* ===== Responsive ===== */
        @media (max-width: 920px){
            .main{padding:22px;}
            .sidebar{display:none;}
            .search-card, .bill-wrap{max-width:100%;}
            .grid{grid-template-columns:1fr;}
            .search-grid{grid-template-columns:1fr;}
        }
    </style>
</head>
<body>

<div class="app">

    <!-- ===== Sidebar (MATCH dashboard.jsp) ===== -->
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
            <a href="reservations.jsp">Reservations</a>
            <a class="active" href="billing.jsp">Billing</a>
            <a href="help.jsp">Help</a>
        </nav>

        <div class="sidebar-footer">
            <a class="logout" href="LogoutServlet">Sign Out</a>
        </div>
    </aside>

    <!-- ===== Main ===== -->
    <main class="main">
        <div class="headline">
            <h1>Billing</h1>
            <p>Calculate and print guest bills by reservation ID.</p>
        </div>

        <!-- ===== Search ===== -->
        <div class="search-card">
            <form method="get" action="billing.jsp" autocomplete="off">
                <div class="search-grid">
                    <div>
                        <label>Reservation ID</label>
                        <input name="q" value="<%= q %>" placeholder="e.g. RES-001" />
                        <div class="hint">Tip: Enter Reservation Code like <b>RES-001</b> (or numeric ID).</div>
                    </div>
                    <button class="btn" type="submit">
                        <svg viewBox="0 0 24 24" fill="none">
                            <path d="M10.5 18a7.5 7.5 0 1 1 0-15 7.5 7.5 0 0 1 0 15Z" stroke="white" stroke-width="2"/>
                            <path d="M16.5 16.5 21 21" stroke="white" stroke-width="2" stroke-linecap="round"/>
                        </svg>
                        Search
                    </button>
                </div>
            </form>
        </div>

        <% if (error != null) { %>
            <div class="msg err"><%= error %></div>
        <% } %>

        <!-- ===== Bill ===== -->
        <div class="bill-wrap">
            <% if (found) { %>
            <div class="bill" id="billArea">
                <div class="bill-top">
                    <div class="bill-title">
                        <h2>Guest Bill</h2>
                        <p>Generated by <b><%= username %></b> • <%= java.time.LocalDateTime.now().toString().replace('T',' ') %></p>
                    </div>
                    <div class="tag"><%= reservationCode %></div>
                </div>

                <div class="bill-body">
                    <div class="grid">
                        <div class="box">
                            <div class="k">Guest Name</div>
                            <div class="v"><%= guestName %></div>
                        </div>
                        <div class="box">
                            <div class="k">Contact</div>
                            <div class="v"><%= (contact == null ? "-" : contact) %></div>
                        </div>

                        <div class="box" style="grid-column:1/-1;">
                            <div class="k">Address</div>
                            <div class="v small"><%= (address == null ? "-" : address) %></div>
                        </div>

                        <div class="box">
                            <div class="k">Room Type</div>
                            <div class="v"><%= roomType %></div>
                        </div>
                        <div class="box">
                            <div class="k">Stay</div>
                            <div class="v small">
                                <%= (checkIn == null ? "-" : checkIn.toString()) %> → <%= (checkOut == null ? "-" : checkOut.toString()) %>
                                &nbsp; • &nbsp; <b><%= nights %></b> night(s)
                            </div>
                        </div>
                    </div>

                    <div class="charges">
                        <div class="row"><span>Rate / Night (LKR)</span> <div><%= String.format("%,.0f", ratePerNight) %></div></div>
                        <div class="row"><span>Nights</span> <div><%= nights %></div></div>
                        <div class="row"><span>Subtotal (LKR)</span> <div><%= String.format("%,.0f", subtotal) %></div></div>
                        <div class="row"><span>Service Charge 10% (LKR)</span> <div><%= String.format("%,.0f", serviceCharge) %></div></div>
                        <div class="row total"><span>Total (LKR)</span> <div><%= String.format("%,.0f", total) %></div></div>
                    </div>
                </div>

                <div class="bill-actions">
                    <button class="btn-ghost" type="button" onclick="window.print();">
                        <svg viewBox="0 0 24 24" fill="none">
                            <path d="M7 8V4h10v4" stroke="#0b3a5d" stroke-width="2" stroke-linejoin="round"/>
                            <path d="M7 18h10v2H7v-2Z" stroke="#0b3a5d" stroke-width="2" stroke-linejoin="round"/>
                            <path d="M6 10h12a2 2 0 0 1 2 2v4H4v-4a2 2 0 0 1 2-2Z" stroke="#0b3a5d" stroke-width="2"/>
                        </svg>
                        Print Bill
                    </button>
                    <button class="btn" type="button" onclick="location.href='reservations.jsp';">
                        Back to Reservations
                    </button>
                </div>
            </div>
            <% } else { %>
                <div class="msg ok">Enter a Reservation ID and click <b>Search</b> to generate the bill.</div>
            <% } %>
        </div>

    </main>
</div>

</body>
</html>