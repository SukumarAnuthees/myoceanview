<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // ✅ Prevent caching
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
    <title>Help Center - Ocean View</title>
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
            display:flex;align-items:center;gap:10px;
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
            display:flex;align-items:center;gap:10px;
            padding:14px 14px;border-radius:14px;
            background:rgba(255,255,255,.12);
            color:#fff;text-decoration:none;
            transition:.2s;
            font-weight:700;
        }
        .logout:hover{background:rgba(255,255,255,.18);}

        /* ===== Main ===== */
        .main{flex:1;padding:34px 34px 60px;}

        .header{text-align:center;margin-top:10px;margin-bottom:22px;}
        .header h1{font-size:42px;font-weight:800;letter-spacing:-.5px;margin-bottom:6px;}
        .header p{color:#64748b;font-size:15px;font-weight:500;}
        .mini{color:#64748b;font-size:12px;margin-top:8px;}

        .center-wrap{display:flex;justify-content:center;align-items:flex-start;margin-top:22px;}
        .card{
            width:min(860px, 100%);
            background:#fff;
            border-radius:16px;
            box-shadow:0 10px 25px rgba(0,0,0,0.06);
            border:1px solid rgba(0,0,0,0.06);
            padding:26px;
        }

        .card-head{display:flex;align-items:center;gap:14px;margin-bottom:18px;padding:6px 6px 12px;}
        .q-icon{
            width:44px;height:44px;border-radius:14px;
            background:linear-gradient(135deg,#0b3a5d,#2e9bb7);
            display:grid;place-items:center;
            box-shadow:0 10px 20px rgba(2,132,199,0.18);
            flex:0 0 auto;
        }
        .q-icon svg{width:22px;height:22px;}
        .card-head h2{font-size:22px;font-weight:800;}
        .card-head small{display:block;color:#64748b;font-weight:600;margin-top:2px;}

        /* ===== Accordion ===== */
        .faq{display:flex;flex-direction:column;gap:14px;margin-top:10px;}
        .faq-item{
            border:1px solid rgba(15,23,42,.10);
            border-radius:14px;
            overflow:hidden;
            background:#fff;
        }
        .faq-btn{
            width:100%;
            text-align:left;
            border:none;
            background:#fff;
            padding:16px 16px;
            display:flex;
            align-items:center;
            justify-content:space-between;
            gap:12px;
            cursor:pointer;
        }
        .faq-btn span{font-weight:700;color:#0f172a;}
        .chev{width:18px;height:18px;transition:.2s transform;opacity:.75;flex:0 0 auto;}
        .faq-body{
            max-height:0;
            overflow:hidden;
            transition:max-height .25s ease;
            background:#fbfdff;
            border-top:1px solid rgba(15,23,42,.06);
        }
        .faq-content{
            padding:16px 16px 18px;
            color:#0f172a;
            font-size:14px;
            line-height:1.65;
        }
        .faq-item.open .faq-body{max-height:2000px;}
        .faq-item.open .chev{transform:rotate(180deg);}

        /* content boxes */
        .note{
            background:rgba(2,132,199,0.08);
            border:1px dashed rgba(2,132,199,0.35);
            padding:12px;
            border-radius:12px;
            margin:10px 0;
            color:#0f172a;
        }
        .warn{
            background:rgba(239,68,68,0.07);
            border:1px dashed rgba(239,68,68,0.35);
            padding:12px;
            border-radius:12px;
            margin:10px 0;
            color:#7f1d1d;
        }
        .ok{
            background:rgba(34,197,94,0.08);
            border:1px dashed rgba(34,197,94,0.35);
            padding:12px;
            border-radius:12px;
            margin:10px 0;
            color:#14532d;
        }
        ul,ol{margin:8px 0 8px 20px;}
        li{margin:6px 0;}

        /* ===== Screenshot + Labels ===== */
        .shot{
            margin-top:12px;
            border-radius:14px;
            overflow:hidden;
            border:1px solid rgba(15,23,42,.10);
            background:#fff;
        }
        .shot .cap{
            padding:10px 12px;
            font-size:12px;
            color:#64748b;
            border-bottom:1px solid rgba(15,23,42,.06);
            background:#fff;
            font-weight:600;
        }
        .shot-wrap{
            position:relative;
            width:100%;
            background:#fff;
        }
        .shot-wrap img{
            width:100%;
            height:auto;
            display:block;
            cursor:zoom-in;
        }
        .step{
            position:absolute;
            width:34px;height:34px;
            border-radius:999px;
            display:grid;place-items:center;
            font-weight:800;
            color:#0f172a;
            background:#fbbf24;
            border:2px solid #fff;
            box-shadow:0 10px 18px rgba(0,0,0,.18);
            user-select:none;
        }
        .step-label{
            position:absolute;
            padding:6px 10px;
            border-radius:10px;
            background:rgba(15,23,42,.86);
            color:#fff;
            font-size:12px;
            font-weight:700;
            max-width:260px;
            line-height:1.3;
        }

        /* ===== Lightbox ===== */
        .lightbox{
            position:fixed; inset:0;
            background:rgba(2,6,23,0.72);
            display:none;
            align-items:center;
            justify-content:center;
            padding:20px;
            z-index:9999;
        }
        .lightbox.open{display:flex;}
        .lightbox img{
            max-width:min(1200px, 96vw);
            max-height:90vh;
            border-radius:14px;
            box-shadow:0 18px 50px rgba(0,0,0,.35);
            cursor:zoom-out;
        }

        @media (max-width: 820px){
            .sidebar{display:none;}
            .main{padding:22px;}
            .header h1{font-size:34px;}
        }
    </style>

    <script>
        function toggleItem(btn){
            const item = btn.closest(".faq-item");
            const all = document.querySelectorAll(".faq-item");
            all.forEach(i => { if(i !== item) i.classList.remove("open"); });
            item.classList.toggle("open");
        }

        function openShot(img){
            const lb = document.getElementById("lightbox");
            const big = document.getElementById("lightboxImg");
            big.src = img.src;
            lb.classList.add("open");
        }
        function closeLightbox(){
            document.getElementById("lightbox").classList.remove("open");
        }

        window.onload = () => {
            document.querySelectorAll(".faq-btn").forEach(btn=>{
                btn.addEventListener("click", ()=> toggleItem(btn));
            });

            document.querySelectorAll(".shot-wrap img").forEach(img=>{
                img.addEventListener("click", ()=> openShot(img));
            });

            const lb = document.getElementById("lightbox");
            if(lb) lb.addEventListener("click", closeLightbox);
        };
    </script>
</head>

<body>
<div class="app">

    <!-- Sidebar -->
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
            <a href="billing.jsp">Billing</a>
            <a class="active" href="help.jsp">Help</a>
        </nav>

        <div class="sidebar-footer">
            <a class="logout" href="LogoutServlet">Sign Out</a>
        </div>
    </aside>

    <!-- Main -->
    <main class="main">

        <div class="header">
            <h1>Help Center</h1>
            <p>Quick guides for new staff members on how to use the reservation system.</p>
            <div class="mini">Logged in as: <b><%= username %></b></div>
        </div>

        <div class="center-wrap">
            <section class="card">

                <div class="card-head">
                    <div class="q-icon">
                        <svg viewBox="0 0 24 24" fill="none">
                            <path d="M12 18h.01" stroke="white" stroke-width="2" stroke-linecap="round"/>
                            <path d="M9.5 9.2a2.7 2.7 0 1 1 4.2 2.3c-.8.5-1.4 1.1-1.4 2.5v.6"
                                  stroke="white" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                            <path d="M12 22c5.5 0 10-4.5 10-10S17.5 2 12 2 2 6.5 2 12s4.5 10 10 10Z"
                                  stroke="white" stroke-width="2"/>
                        </svg>
                    </div>
                    <div>
                        <h2>Frequently Asked Questions</h2>
                        <small>Step-by-step instructions </small>
                    </div>
                </div>

                <div class="faq">

                    <!-- 1: LOGIN (Your image + labels) -->
                    <div class="faq-item">
                        <button type="button" class="faq-btn">
                            <span>How do I log in?</span>
                            <svg class="chev" viewBox="0 0 24 24" fill="none">
                                <path d="M6 9l6 6 6-6" stroke="#0f172a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>
                        </button>
                        <div class="faq-body">
                            <div class="faq-content">
                                <ol>
                                    <li>Type your User ID.</li>
                                    <li>Type your password.</li>
                                    <li>Click Access Dashboard to continue.</li>
                                </ol>

                                <div class="note">
                                    <b>Tips:</b>
                                    <ul>
                                        <li>Check spelling and CAPS LOCK.</li>
                                        <li>If you cannot access your account, contact the system admin to reset your password.</li>
                                    </ul>
                                </div>

                                <div class="shot">
                                    <div class="cap">Screenshot: Login Screen (Click to Zoom)</div>
                                    <div class="shot-wrap">
                                        <!-- ✅ Your image path -->
                                        <img src="help/login.png" alt="Login screenshot">

                                        <!-- ✅ Labels for your login design -->
                                        <div class="step" style="top:45%; left:72%;">1</div>
                                        <div class="step-label" style="top:45%; left:76%;">Enter User ID</div>

                                        <div class="step" style="top:60%; left:72%;">2</div>
                                        <div class="step-label" style="top:60%; left:76%;">Enter Password</div>

                                        <div class="step" style="top:77%; left:72%;">3</div>
                                        <div class="step-label" style="top:77%; left:76%;">Click Access Dashboard</div>
                                    </div>
                                </div>

                                <div class="mini">
                                    If the circles are slightly off in your screen, tell me your image size and I’ll adjust the exact positions.
                                </div>
                            </div>
                        </div>
                    </div>

                    <!-- 2 -->
                    <div class="faq-item">
                        <button type="button" class="faq-btn">
                            <span>How do I create a new reservation?</span>
                            <svg class="chev" viewBox="0 0 24 24" fill="none">
                                <path d="M6 9l6 6 6-6" stroke="#0f172a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>
                        </button>
                        <div class="faq-body">
                            <div class="faq-content">
                                <ol>
                                    <li>Open the New Reservation option from the menu.</li>
                                    <li>Enter guest name, contact number, and address.</li>
                                    <li>Select the room type requested by the guest.</li>
                                    <li>Choose check-in and check-out dates.</li>
                                    <li>Review all details and confirm the reservation.</li>
                                </ol>

                                <div class="ok">
                                    <b>Before confirming:</b>
                                    <ul>
                                        <li>Verify the contact number carefully.</li>
                                        <li>Confirm dates with the guest.</li>
                                        <li>Make sure the room type matches the guest request.</li>
                                    </ul>
                                </div>

                                <div class="shot">
<div class="shot">
  <div class="cap">Screenshot: New Reservation (Click to Zoom)</div>

  <div class="shot-wrap">
    <img src="help/res.png" alt="New Reservation screenshot">

    <!-- 1: Guest Name -->
    <div class="step" style="top:16%; left:30%;">1</div>
    <div class="step-label" style="top:16%; left:34%;">Enter Guest Name</div>

    <!-- 2: Contact Number -->
    <div class="step" style="top:16%; right:28%;">2</div>
    <div class="step-label" style="top:16%; right:8%;">Enter Contact Number</div>

    <!-- 3: Address -->
    <div class="step" style="top:30%; left:30%;">3</div>
    <div class="step-label" style="top:30%; left:34%;">Enter Address</div>

    <!-- 4: Room Type -->
    <div class="step" style="top:46%; left:30%;">4</div>
    <div class="step-label" style="top:46%; left:34%;">Select Room Type</div>

    <!-- 5: Check-in -->
    <div class="step" style="top:63%; left:30%;">5</div>
    <div class="step-label" style="top:63%; left:34%;">Choose Check-in Date</div>

    <!-- 6: Check-out -->
    <div class="step" style="top:63%; right:28%;">6</div>
    <div class="step-label" style="top:63%; right:8%;">Choose Check-out Date</div>

    <!-- 7: Create Reservation Button -->
    <div class="step" style="top:84%; left:46%;">7</div>
    <div class="step-label" style="top:84%; left:50%;">Click Create Reservation</div>

  </div>
</div>
</div>
                            </div>
                        </div>
                    </div>

                    <!-- 3 -->
                    <div class="faq-item">
                        <button type="button" class="faq-btn">
                            <span>How do I search for a reservation?</span>
                            <svg class="chev" viewBox="0 0 24 24" fill="none">
                                <path d="M6 9l6 6 6-6" stroke="#0f172a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>
                        </button>
                        <div class="faq-body">
                            <div class="faq-content">
                                <ol>
                                    <li>Open the Reservations list from the menu.</li>
                                    <li>Use guest name or contact number in the search box.</li>
                                    <li>Check the filtered results and select the correct booking.</li>
                                </ol>

                                <div class="note">
                                    <b>Best practice:</b> Use contact number to avoid selecting the wrong guest.
                                </div>

                               <div class="shot">
  <div class="cap">Screenshot: Reservations Page (Click to Zoom)</div>

  <div class="shot-wrap">
    <img src="help/search.png" alt="Reservations page screenshot">

    <!-- 1: Search box -->
    <div class="step" style="top:23%; left:26%;">1</div>
    <div class="step-label" style="top:23%; left:30%;">Type guest name / contact / reservation ID</div>

    <!-- 2: Search button -->
    <div class="step" style="top:23%; right:26%;">2</div>
    <div class="step-label" style="top:23%; right:10%;">Click Search</div>

    <!-- 3: New Reservation button -->
    <div class="step" style="top:10%; right:10%;">3</div>
    <div class="step-label" style="top:10%; right:16%;">Create a new reservation</div>

    <!-- 4: Reservation cards -->
    <div class="step" style="top:52%; left:30%;">4</div>
    <div class="step-label" style="top:52%; left:34%;">Review reservation cards</div>

    <!-- 5: Stay dates / nights -->
    <div class="step" style="top:70%; left:30%;">5</div>
    <div class="step-label" style="top:70%; left:34%;">Check stay dates & nights</div>
  </div>
</div>
                            </div>
                        </div>
                    </div>

                    <!-- 4 -->
                    <div class="faq-item">
                        <button type="button" class="faq-btn">
                            <span>How do I generate a bill?</span>
                            <svg class="chev" viewBox="0 0 24 24" fill="none">
                                <path d="M6 9l6 6 6-6" stroke="#0f172a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>
                        </button>
                        <div class="faq-body">
                            <div class="faq-content">
                                <ol>
                                    <li>Open Billing from the menu.</li>
                                    <li>Select the correct guest booking.</li>
                                    <li>Confirm room type and stay dates.</li>
                                    <li>Review the final amount.</li>
                                    <li>Print or save the bill always required.</li>
                                </ol>

                                <div class="warn">
                                    <b>Important checks:</b>
                                    <ul>
                                        <li>Wrong dates can cause wrong totals.</li>
                                        <li>Confirm room type before printing.</li>
                                        <li>Check totals before finalizing.</li>
                                    </ul>
                                </div>

                               <div class="shot">
  <div class="cap">Screenshot: Billing / Guest Bill (Click to Zoom)</div>

  <div class="shot-wrap">
    <img src="help/billing.png" alt="Billing page screenshot">

    <!-- 1: Reservation ID badge -->
    <div class="step" style="top:8%; right:14%;">1</div>
    <div class="step-label" style="top:8%; right:20%;">Reservation ID</div>

    <!-- 2: Guest details -->
    <div class="step" style="top:24%; left:26%;">2</div>
    <div class="step-label" style="top:24%; left:30%;">Confirm guest details</div>

    <!-- 3: Room type + stay -->
    <div class="step" style="top:40%; left:26%;">3</div>
    <div class="step-label" style="top:40%; left:30%;">Check room type & stay dates</div>

    <!-- 4: Rate / nights / charges -->
    <div class="step" style="top:60%; left:26%;">4</div>
    <div class="step-label" style="top:60%; left:30%;">Review rate, nights & service charge</div>

    <!-- 5: Total amount -->
    <div class="step" style="top:74%; right:16%;">5</div>
    <div class="step-label" style="top:74%; right:22%;">Confirm total amount</div>

    <!-- 6: Print bill -->
    <div class="step" style="top:91%; left:55%;">6</div>
    <div class="step-label" style="top:91%; left:59%;">Print bill</div>

    <!-- 7: Back button -->
    <div class="step" style="top:91%; right:12%;">7</div>
    <div class="step-label" style="top:91%; right:18%;">Back to reservations</div>
  </div>
</div>
                            </div>
                        </div>
                    </div>

                    <!-- 5 -->
                    <div class="faq-item">
                        <button type="button" class="faq-btn">
                            <span>What are the room types and how do I choose?</span>
                            <svg class="chev" viewBox="0 0 24 24" fill="none">
                                <path d="M6 9l6 6 6-6" stroke="#0f172a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>
                        </button>
                        <!-- 5 (Room types & rates - MATCHES SYSTEM RATES) -->
<div class="faq-item">
 

    <div class="faq-body">
        <div class="faq-content" style="color:#64748b;">
            <b>Standard Room:</b> LKR 10,000 per night — Comfortable room with essential amenities.<br>
            <b>Deluxe Room:</b> LKR 15,000 per night — Spacious room with ocean view.<br>
            <b>Ocean Suite:</b> LKR 20,000 per night — Premium suite with private balcony.<br>
            <b>Beach Villa:</b> LKR 30,000 per night — Luxury villa with private beach access.
        </div>
    </div>
</div>
                    </div>

                    <!-- 6 -->
                    <div class="faq-item">
                        <button type="button" class="faq-btn">
                            <span>How do I sign out safely?</span>
                            <svg class="chev" viewBox="0 0 24 24" fill="none">
                                <path d="M6 9l6 6 6-6" stroke="#0f172a" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
                            </svg>
                        </button>
                        <div class="faq-body">
                            <div class="faq-content">
                                <ol>
                                    <li>Click Sign Out from the bottom of the menu.</li>
                                    <li>Wait until the login screen appears.</li>
                                    <li>If using a shared computer, close the browser.</li>
                                </ol>

                                <div class="ok">
                                    <b>Why sign out is important:</b>
                                    <ul>
                                        <li>Protects guest information</li>
                                        <li>Prevents unauthorized access</li>
                                        <li>Important for shared reception computers</li>
                                    </ul>
                                </div>

                                
                            </div>
                        </div>
                    </div>

                </div>

               

            </section>
        </div>
    </main>
</div>

<!-- Lightbox -->
<div class="lightbox" id="lightbox" aria-hidden="true">
    <img id="lightboxImg" src="" alt="Zoomed screenshot">
</div>

</body>
</html>