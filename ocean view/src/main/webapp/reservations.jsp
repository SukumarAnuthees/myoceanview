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

        /* ===== Sidebar (SAME STYLE AS DASHBOARD) ===== */
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
        .main{
            flex:1;
            padding:34px 38px 60px;
        }

        /* Mobile: hide sidebar */
        @media(max-width:820px){
            .sidebar{display:none;}
            .main{padding:18px;}
        }

        /* ===== Your Existing Reservations UI ===== */
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
            display:flex;
            align-items:flex-start;
            justify-content:space-between;
            gap:14px;
            position:relative;
            z-index:1;
        }
        .title{
            font-size:38px;
            letter-spacing:-.6px;
            font-weight:800;
            color:#f8fafc;
        }
        .subtitle{margin-top:6px; color:rgba(226,232,240,.85);}

        .hero-actions{
            display:flex;
            gap:10px;
            flex-wrap:wrap;
            justify-content:flex-end;
        }
        .btn{
            display:inline-flex;
            align-items:center;
            gap:10px;
            padding:10px 14px;
            border-radius:14px;
            font-weight:700;
            text-decoration:none;
            border:1px solid rgba(255,255,255,.16);
            color:#e2e8f0;
            background:rgba(255,255,255,.06);
            backdrop-filter: blur(6px);
            transition:.18s ease;
            white-space:nowrap;
        }
        .btn:hover{transform:translateY(-1px); background:rgba(255,255,255,.10);}
        .btn.primary{
            border:none;
            background:var(--grad);
            color:#032033;
            box-shadow:0 16px 35px rgba(46,163,186,.25);
        }
        .btn.primary:hover{filter:saturate(1.05);}

        .toolbar{
            margin-top:18px;
            max-width:1100px;
            display:grid;
            grid-template-columns: 1fr auto;
            gap:12px;
            align-items:center;
        }
        @media(max-width:760px){
            .toolbar{grid-template-columns:1fr;}
        }

        .search{
            display:flex;
            align-items:center;
            gap:10px;
            background:var(--card);
            border:1px solid var(--line);
            border-radius:18px;
            padding:12px 14px;
            box-shadow:var(--soft);
        }
        .search input{
            width:100%;
            border:none;
            outline:none;
            font-size:14px;
            color:var(--ink);
        }
        .search .go{
            border:none;
            cursor:pointer;
            padding:10px 14px;
            border-radius:14px;
            font-weight:800;
            color:#ffffff;
            background:var(--grad);
            transition:.18s ease;
        }
        .search .go:hover{transform:translateY(-1px);}

        .chips{
            display:flex;
            gap:10px;
            flex-wrap:wrap;
            justify-content:flex-end;
        }
        @media(max-width:760px){ .chips{justify-content:flex-start;} }

        .chip{
            display:inline-flex;
            align-items:center;
            gap:8px;
            padding:9px 12px;
            border-radius:999px;
            font-size:12px;
            font-weight:800;
            border:1px solid var(--line);
            background:var(--card);
            box-shadow:0 10px 25px rgba(2,6,23,.04);
            color:var(--ink);
            white-space:nowrap;
        }
        .dot{width:9px;height:9px;border-radius:50%;}
        .d1{background:#38bdf8;}
        .d2{background:#22c55e;}
        .d3{background:#fb923c;}

        .grid{
            margin-top:16px;
            max-width:1100px;
            display:grid;
            grid-template-columns:repeat(3, minmax(0, 1fr));
            gap:14px;
        }
        @media(max-width:1100px){ .grid{grid-template-columns:repeat(2, minmax(0, 1fr));} }
        @media(max-width:760px){ .grid{grid-template-columns:1fr;} }

        .card{
            background:var(--card);
            border:1px solid var(--line);
            border-radius:20px;
            padding:16px 16px 14px;
            box-shadow:var(--shadow);
            position:relative;
            overflow:hidden;
            transition:.18s ease;
        }
        .card:hover{transform:translateY(-2px); box-shadow:0 26px 70px rgba(2,6,23,.12);}
        .accent{
            position:absolute;
            inset:0 auto 0 0;
            width:6px;
            background:var(--grad);
        }

        .meta{
            display:flex;
            justify-content:space-between;
            align-items:flex-start;
            gap:10px;
            padding-left:10px;
        }
        .rcode{
            font-weight:900;
            letter-spacing:.6px;
            font-size:12px;
            color:#0ea5e9;
        }
        .room{
            padding:7px 10px;
            border-radius:999px;
            font-size:12px;
            font-weight:900;
            background:var(--chip);
            border:1px solid rgba(56,189,248,.25);
            color:#0b3a5d;
            white-space:nowrap;
        }

        .gname{
            padding-left:10px;
            margin-top:10px;
            font-size:18px;
            font-weight:900;
            color:var(--ink);
            line-height:1.2;
        }

        .rows{
            padding-left:10px;
            margin-top:12px;
            display:flex;
            flex-direction:column;
            gap:10px;
            color:#334155;
            font-size:13px;
        }
        .row{
            display:flex;
            gap:10px;
            align-items:flex-start;
        }
        .ic{
            width:34px;height:34px;
            border-radius:12px;
            display:flex;
            align-items:center;
            justify-content:center;
            border:1px solid var(--line);
            background:#f8fafc;
            flex:0 0 auto;
        }
        .ic svg{width:18px;height:18px; opacity:.75;}
        .txt{line-height:1.35;}
        .small{color:var(--muted); font-weight:700; font-size:12px; margin-top:2px;}

        .datebar{
            margin-top:14px;
            padding-left:10px;
            display:flex;
            align-items:center;
            justify-content:space-between;
            gap:10px;
            flex-wrap:wrap;
        }
        .dates{
            display:inline-flex;
            align-items:center;
            gap:8px;
            padding:8px 10px;
            border-radius:14px;
            background:var(--chip2);
            border:1px solid rgba(34,197,94,.20);
            color:#065f46;
            font-weight:900;
            font-size:12px;
        }
        .dates svg{width:16px;height:16px; opacity:.8;}

        .tag{
            display:inline-flex;
            align-items:center;
            gap:8px;
            padding:8px 10px;
            border-radius:14px;
            background:var(--chip3);
            border:1px solid rgba(251,146,60,.25);
            color:#7c2d12;
            font-weight:900;
            font-size:12px;
        }

        .empty{
            margin-top:16px;
            max-width:1100px;
            background:#fff;
            border:1px dashed rgba(15,23,42,.22);
            border-radius:18px;
            padding:18px;
            color:#475569;
            box-shadow:0 12px 26px rgba(2,6,23,.05);
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

    <!-- ===== Main ===== -->
    <main class="main">

        <!-- Header / Hero -->
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

        <%
            int total = 0;
            int matched = 0;

            try {
                Class.forName("com.mysql.cj.jdbc.Driver");
                try (Connection con = DriverManager.getConnection(URL, USER, PASS)) {

                    // total count
                    try (PreparedStatement psT = con.prepareStatement("SELECT COUNT(*) FROM reservations");
                         ResultSet rsT = psT.executeQuery()) {
                        if (rsT.next()) total = rsT.getInt(1);
                    }

                    // matched count (same filter used below)
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
            } catch (Exception ignore) {
                // keep counts as 0
            }
        %>

        <!-- Toolbar -->
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
<!-- Version 2 Update -->
    </main>
</div>

</body>
</html>