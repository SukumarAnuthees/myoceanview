<%@ page contentType="text/html;charset=UTF-8" language="java" %>
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
            display:flex;align-items:center;gap:12px;
            padding:12px 12px;border-radius:12px;
            color:#e9f4ff;text-decoration:none;
            transition:.2s;
        }
        .nav a:hover{background:rgba(255,255,255,.12);}
        .nav a.active{background:rgba(255,255,255,.16);font-weight:600;}
        .nav .ico{width:22px;height:22px;opacity:.95}

        .sidebar-footer{
            position:absolute;left:18px;right:18px;bottom:18px;
        }
        .logout{
            display:flex;align-items:center;gap:10px;
            padding:12px 12px;border-radius:12px;
            background:rgba(255,255,255,.12);
            color:#fff;text-decoration:none;
            transition:.2s;
        }
        .logout:hover{background:rgba(255,255,255,.18);}

        /* ===== Main ===== */
        .main{flex:1;padding:34px 34px 60px;}
        .headline h1{font-size:42px;letter-spacing:-.5px;}
        .headline p{margin-top:6px;color:#64748b;font-size:16px;}

        /* ===== Stat cards ===== */
        .stats{
            margin-top:28px;
            display:grid;
            grid-template-columns: repeat(4, minmax(0,1fr));
            gap:18px;
        }
        .card{
            background:#fff;border-radius:16px;
            box-shadow:0 10px 25px rgba(15,23,42,.06);
            padding:18px 18px;
            border:1px solid rgba(15,23,42,.06);
            display:flex;justify-content:space-between;gap:12px;
        }
        .card .label{color:#64748b;font-size:14px;}
        .card .value{font-size:34px;font-weight:700;margin-top:6px;}
        .pill{
            width:44px;height:44px;border-radius:14px;
            display:grid;place-items:center;
            background:#f1f5f9;
        }

        /* ===== Section title ===== */
        .section-title{
            margin-top:34px;
            font-size:26px;
            font-weight:700;
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
            padding:22px;
            border:1px solid rgba(15,23,42,.06);
            box-shadow:0 10px 25px rgba(15,23,42,.06);
            text-decoration:none;color:inherit;
            transition:.2s;
            display:flex;gap:16px;align-items:flex-start;
        }
        .action:hover{transform:translateY(-2px);}
        .action .badge{
            width:56px;height:56px;border-radius:16px;
            background:linear-gradient(135deg,#0b3a5d,#2e9bb7);
            display:grid;place-items:center;
            box-shadow:0 12px 26px rgba(11,58,93,.25);
        }
        .action h3{font-size:18px;margin-top:2px;}
        .action p{color:#64748b;margin-top:6px;font-size:14px;}

        /* ===== Table ===== */
        .table-wrap{
            margin-top:14px;
            background:#fff;border-radius:18px;
            border:1px solid rgba(15,23,42,.06);
            box-shadow:0 10px 25px rgba(15,23,42,.06);
            overflow:hidden;
        }
        table{width:100%;border-collapse:collapse;}
        thead th{
            text-align:left;
            padding:16px 18px;
            color:#64748b;
            font-weight:600;
            font-size:13px;
            background:#fbfdff;
            border-bottom:1px solid rgba(15,23,42,.06);
        }
        tbody td{
            padding:16px 18px;
            border-bottom:1px solid rgba(15,23,42,.06);
            font-size:14px;
        }
        tbody tr:last-child td{border-bottom:none;}
        .idtag{color:#0ea5e9;font-weight:700;letter-spacing:.4px;}
        .muted{color:#64748b}

        /* ===== Responsive ===== */
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
                <!-- waves icon -->
                <svg class="ico" viewBox="0 0 24 24" fill="none">
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
            <a class="active" href="dashboard.jsp">
                <svg class="ico" viewBox="0 0 24 24" fill="none">
                    <path d="M4 13h7V4H4v9ZM13 20h7v-7h-7v7ZM13 11h7V4h-7v7ZM4 20h7v-5H4v5Z"
                          stroke="white" stroke-width="2" stroke-linejoin="round"/>
                </svg>
                Dashboard
            </a>

            <a href="new_reservation.jsp">
                <svg class="ico" viewBox="0 0 24 24" fill="none">
                    <path d="M12 5v14M5 12h14" stroke="white" stroke-width="2" stroke-linecap="round"/>
                </svg>
                New Reservation
            </a>

            <a href="reservations.jsp">
                <svg class="ico" viewBox="0 0 24 24" fill="none">
                    <path d="M10 6h10M10 12h10M10 18h10M4 6h2M4 12h2M4 18h2"
                          stroke="white" stroke-width="2" stroke-linecap="round"/>
                </svg>
                Reservations
            </a>

            <a href="billing.jsp">
                <svg class="ico" viewBox="0 0 24 24" fill="none">
                    <path d="M7 7h10v14l-2-1-3 1-3-1-2 1V7Z" stroke="white" stroke-width="2" stroke-linejoin="round"/>
                    <path d="M9 3h6v4H9V3Z" stroke="white" stroke-width="2" stroke-linejoin="round"/>
                </svg>
                Billing
            </a>

            <a href="help.jsp">
                <svg class="ico" viewBox="0 0 24 24" fill="none">
                    <path d="M12 18h.01M9.5 9a2.5 2.5 0 1 1 4.3 1.7c-.9.9-1.3 1.2-1.3 2.3v.5"
                          stroke="white" stroke-width="2" stroke-linecap="round"/>
                    <path d="M12 22C6.5 22 2 17.5 2 12S6.5 2 12 2s10 4.5 10 10-4.5 10-10 10Z"
                          stroke="white" stroke-width="2"/>
                </svg>
                Help
            </a>
        </nav>

        <div class="sidebar-footer">
            <a class="logout" href="LogoutServlet">
                <svg class="ico" viewBox="0 0 24 24" fill="none">
                    <path d="M10 7V5a2 2 0 0 1 2-2h7a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-7a2 2 0 0 1-2-2v-2"
                          stroke="white" stroke-width="2" stroke-linejoin="round"/>
                    <path d="M15 12H3m0 0 3-3m-3 3 3 3"
                          stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                </svg>
                Sign Out
            </a>
        </div>
    </aside>

    <!-- ===== Main ===== -->
    <main class="main">
        <div class="headline">
            <h1>Good day, <%= username %></h1>
            <p>Welcome to the Ocean View Resort management system.</p>
        </div>

        <!-- Stats (you can replace values with DB counts later) -->
        <section class="stats">
            <div class="card">
                <div>
                    <div class="label">Total Reservations</div>
                    <div class="value">2</div>
                </div>
                <div class="pill">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
                        <path d="M7 3v3M17 3v3M4 8h16M6 12h4M6 16h4M14 12h4M14 16h4"
                              stroke="#0ea5e9" stroke-width="2" stroke-linecap="round"/>
                        <path d="M6 5h12a2 2 0 0 1 2 2v13a2 2 0 0 1-2 2H6a2 2 0 0 1-2-2V7a2 2 0 0 1 2-2Z"
                              stroke="#0ea5e9" stroke-width="2"/>
                    </svg>
                </div>
            </div>

            <div class="card">
                <div>
                    <div class="label">Active Guests</div>
                    <div class="value">0</div>
                </div>
                <div class="pill">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
                        <path d="M16 11a4 4 0 1 0-8 0 4 4 0 0 0 8 0Z" stroke="#22c55e" stroke-width="2"/>
                        <path d="M4 21a8 8 0 0 1 16 0" stroke="#22c55e" stroke-width="2" stroke-linecap="round"/>
                    </svg>
                </div>
            </div>

            <div class="card">
                <div>
                    <div class="label">Room Types</div>
                    <div class="value">4</div>
                </div>
                <div class="pill">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
                        <path d="M4 10h16v7H4v-7Z" stroke="#fb923c" stroke-width="2" />
                        <path d="M4 17v3M20 17v3" stroke="#fb923c" stroke-width="2" stroke-linecap="round"/>
                        <path d="M7 10V7a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v3" stroke="#fb923c" stroke-width="2"/>
                    </svg>
                </div>
            </div>

            <div class="card">
                <div>
                    <div class="label">Upcoming</div>
                    <div class="value">2</div>
                </div>
                <div class="pill">
                    <svg width="22" height="22" viewBox="0 0 24 24" fill="none">
                        <path d="M4 17l6-6 4 4 6-8" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                        <path d="M20 7v6h-6" stroke="#f59e0b" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                    </svg>
                </div>
            </div>
        </section>

        <h2 class="section-title">Quick Actions</h2>
        <section class="actions">
            <a class="action" href="new_reservation.jsp">
                <div class="badge">
                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none">
                        <path d="M12 5v14M5 12h14" stroke="white" stroke-width="2" stroke-linecap="round"/>
                    </svg>
                </div>
                <div>
                    <h3>New Reservation</h3>
                    <p>Register a new guest</p>
                </div>
            </a>

            <a class="action" href="reservations.jsp">
                <div class="badge">
                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none">
                        <path d="M10 6h10M10 12h10M10 18h10M4 6h2M4 12h2M4 18h2"
                              stroke="white" stroke-width="2" stroke-linecap="round"/>
                    </svg>
                </div>
                <div>
                    <h3>View Reservations</h3>
                    <p>Search & manage bookings</p>
                </div>
            </a>

            <a class="action" href="billing.jsp">
                <div class="badge">
                    <svg width="26" height="26" viewBox="0 0 24 24" fill="none">
                        <path d="M7 7h10v14l-2-1-3 1-3-1-2 1V7Z" stroke="white" stroke-width="2" stroke-linejoin="round"/>
                        <path d="M9 3h6v4H9V3Z" stroke="white" stroke-width="2" stroke-linejoin="round"/>
                    </svg>
                </div>
                <div>
                    <h3>Generate Bill</h3>
                    <p>Calculate guest charges</p>
                </div>
            </a>
        </section>

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
                </tr>
                </thead>
                <tbody>
                <!-- Sample rows (replace with DB later) -->
                <tr>
                    <td class="idtag">RES-002</td>
                    <td>Sarah Mitchell</td>
                    <td class="muted">Beach Villa</td>
                    <td class="muted">2026-02-15</td>
                    <td class="muted">2026-02-20</td>
                </tr>
                <tr>
                    <td class="idtag">RES-001</td>
                    <td>James Anderson</td>
                    <td class="muted">Ocean Suite</td>
                    <td class="muted">2026-02-14</td>
                    <td class="muted">2026-02-18</td>
                </tr>
                </tbody>
            </table>
        </div>

    </main>
</div>

</body>
</html>
