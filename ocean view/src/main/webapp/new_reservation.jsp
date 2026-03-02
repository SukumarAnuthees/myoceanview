<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<%
    // ✅ Prevent caching (optional but recommended)
    response.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
    response.setHeader("Pragma", "no-cache");
    response.setDateHeader("Expires", 0);

    // ✅ Session protection
    if (session.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }

    String username = (String) session.getAttribute("username");

    // Messages from servlet
    String success = (String) request.getAttribute("success");
    String error   = (String) request.getAttribute("error");
%>

<!DOCTYPE html>
<html>
<head>
    <title>New Reservation</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap" rel="stylesheet">

    <style>
        *{margin:0;padding:0;box-sizing:border-box;font-family:'Poppins',sans-serif;}
        body{background:#f4f7fb;color:#0f172a;}
        .app{display:flex;min-height:100vh;}

        /* ===== Sidebar (SAME AS DASHBOARD) ===== */
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

        /* ===== Main Area ===== */
        .main{
            flex:1;
            padding:34px 34px 60px;
        }

        /* ===== New Reservation Card UI ===== */
        .card{
            background:#fff;
            padding:30px;
            border-radius:16px;
            box-shadow:0 10px 25px rgba(0,0,0,0.05);
            max-width:860px;
            border:1px solid rgba(0,0,0,0.06);
        }

        .page-title{margin:0 0 8px;}
        .sub{color:#64748b;margin-bottom:18px;}

        .row{display:grid;grid-template-columns:1fr 1fr;gap:16px;}

        @media(max-width:900px){
            .row{grid-template-columns:1fr;}
        }
        @media (max-width: 820px){
            .sidebar{display:none;}
            .main{padding:22px;}
        }

        label{font-weight:700;font-size:14px;color:#0f172a;display:block;margin-top:6px;}

        input, select, textarea{
            width:100%;
            padding:12px;
            margin:8px 0 6px;
            border-radius:10px;
            border:1px solid #cbd5e1;
            outline:none;
            transition:.2s;
            background:#fff;
        }
        textarea{resize:vertical;min-height:90px;}

        input:focus, select:focus, textarea:focus{
            border-color:#2e9bb7;
            box-shadow:0 0 0 3px rgba(46,155,183,0.18);
        }

        /* ✅ Validation highlight */
        .invalid{
            border-color:#ef4444 !important;
            box-shadow:0 0 0 3px rgba(239,68,68,0.15) !important;
        }
        .valid{
            border-color:#22c55e !important;
            box-shadow:0 0 0 3px rgba(34,197,94,0.12) !important;
        }

        .field-error{
            font-size:12px;
            color:#b91c1c;
            margin:0 0 10px;
            min-height:16px;
        }

        .hint{
            font-size:12px; color:#64748b; margin-top:4px; margin-bottom:10px;
        }

        .msg{
            padding:12px 14px; border-radius:10px; margin:0 0 14px; font-size:14px;
            max-width:860px;
        }
        .msg.ok{ background:#ecfdf5; border:1px solid #bbf7d0; color:#166534; }
        .msg.err{ background:#fef2f2; border:1px solid #fecaca; color:#991b1b; }

        button{
            width:100%;
            padding:14px;
            border:none;
            border-radius:10px;
            background:linear-gradient(135deg,#0b3a5d,#2e9bb7);
            color:white;
            font-weight:800;
            cursor:pointer;
            transition:.2s;
            margin-top:10px;
        }
        button:hover{opacity:.95; transform:translateY(-1px);}
        button:disabled{opacity:.6; cursor:not-allowed; transform:none;}

        .small-note{font-size:12px; color:#64748b; margin-top:12px; text-align:center;}

        /* ✅ Date validation panel */
        .date-panel{
            margin-top:8px;
            padding:12px 14px;
            border-radius:12px;
            border:1px dashed rgba(2,132,199,0.35);
            background:rgba(2,132,199,0.06);
            color:#0f172a;
            font-size:13px;
            line-height:1.4;
        }
        .date-panel b{font-weight:800;}
        .date-panel .warn{color:#b91c1c;font-weight:800;}
        .date-panel .ok{color:#166534;font-weight:800;}

        /* Optional small header line */
        .welcome{
            color:#64748b;
            font-weight:600;
            margin-bottom:12px;
        }
    </style>

    <script>
        // =========================
        // ✅ Helpers
        // =========================
        function trimVal(id){ return document.getElementById(id).value.trim(); }

        function setError(id, msg){
            const el = document.getElementById(id);
            const err = document.getElementById(id + "_err");
            if(msg){
                el.classList.add("invalid");
                el.classList.remove("valid");
                err.textContent = msg;
                return false;
            }else{
                el.classList.remove("invalid");
                el.classList.add("valid");
                err.textContent = "";
                return true;
            }
        }

        function isValidName(name){
            return /^[A-Za-z.\s'-]+$/.test(name);
        }

        function isValidSLPhone(phone){
            const p = phone.replace(/\s+/g,'');
            return /^(\+94\d{9}|0\d{9})$/.test(p);
        }

        function parseDateISO(iso){
            const d = new Date(iso + "T00:00:00");
            d.setHours(0,0,0,0);
            return d;
        }

        function daysBetween(d1ISO, d2ISO){
            const a = parseDateISO(d1ISO);
            const b = parseDateISO(d2ISO);
            return Math.round((b - a) / (1000*60*60*24));
        }

        function todayLocal(){
            const t = new Date();
            t.setHours(0,0,0,0);
            return t;
        }

        // =========================
        // ✅ Date min rules + live constraints
        // =========================
        function setMinDates(){
            const t = todayLocal();
            const yyyy = t.getFullYear();
            const mm = String(t.getMonth()+1).padStart(2,'0');
            const dd = String(t.getDate()).padStart(2,'0');
            const min = `${yyyy}-${mm}-${dd}`;

            const checkIn  = document.getElementById("checkIn");
            const checkOut = document.getElementById("checkOut");
            checkIn.min = min;
            checkOut.min = min;
        }

        function enforceCheckoutMin(){
            const inVal = document.getElementById("checkIn").value;
            const outEl = document.getElementById("checkOut");

            if(inVal){
                const inD = parseDateISO(inVal);
                inD.setDate(inD.getDate() + 1);
                const yyyy = inD.getFullYear();
                const mm = String(inD.getMonth()+1).padStart(2,'0');
                const dd = String(inD.getDate()).padStart(2,'0');
                const minOut = `${yyyy}-${mm}-${dd}`;
                outEl.min = minOut;

                if(outEl.value && parseDateISO(outEl.value) < parseDateISO(minOut)){
                    outEl.value = "";
                }
            }
        }

        // =========================
        // ✅ Field validations
        // =========================
        function validateGuestName(){
            const v = trimVal("guestName");
            if(v.length < 3) return setError("guestName","Guest Name must be at least 3 characters.");
            if(v.length > 60) return setError("guestName","Guest Name must be 60 characters or less.");
            if(!isValidName(v)) return setError("guestName","Only letters, spaces, dot (.), apostrophe ('), hyphen (-) allowed.");
            return setError("guestName","");
        }

        function validateContact(){
            const v = trimVal("contact");
            if(!isValidSLPhone(v)) return setError("contact","Use +94XXXXXXXXX or 0XXXXXXXXX (Sri Lanka format).");
            return setError("contact","");
        }

        function validateAddress(){
            const v = trimVal("address");
            if(v.length < 8) return setError("address","Address must be at least 8 characters.");
            if(v.length > 200) return setError("address","Address must be 200 characters or less.");
            if(/^[\W_]+$/.test(v)) return setError("address","Address cannot be only symbols.");
            return setError("address","");
        }

        function validateRoomType(){
            const v = document.getElementById("roomType").value;
            if(v === "") return setError("roomType","Please select a room type.");
            return setError("roomType","");
        }

        function validateDates(){
            const inVal  = document.getElementById("checkIn").value;
            const outVal = document.getElementById("checkOut").value;

            let ok = true;
            const panel = document.getElementById("datePanel");
            let lines = [];

            if(!inVal){
                ok = false;
                setError("checkIn","Please select a check-in date.");
            }else{
                setError("checkIn","");
            }

            if(!outVal){
                ok = false;
                setError("checkOut","Please select a check-out date.");
            }else{
                setError("checkOut","");
            }

            if(inVal && outVal){
                const t   = todayLocal();
                const inD = parseDateISO(inVal);
                const outD= parseDateISO(outVal);

                if(inD < t){
                    ok = false;
                    setError("checkIn","Check-in cannot be in the past.");
                }

                if(outD <= inD){
                    ok = false;
                    setError("checkOut","Check-out must be AFTER check-in (at least 1 night).");
                }

                const stay = daysBetween(inVal, outVal);
                if(stay > 0){
                    lines.push(`Nights: <b>${stay}</b>`);
                }

                if(stay > 30){
                    ok = false;
                    setError("checkOut","Maximum stay allowed is 30 nights.");
                    lines.push(`<span class="warn">Too long: max 30 nights</span>`);
                }

                const futureLimit = new Date(t);
                futureLimit.setDate(futureLimit.getDate() + 365);
                if(inD > futureLimit){
                    ok = false;
                    setError("checkIn","Booking too far in advance (max 365 days).");
                }
            }

            if(ok){
                lines.push(`<span class="ok">Dates look valid ✅</span>`);
            }else{
                lines.push(`<span class="warn">Fix date errors above ❌</span>`);
            }

            panel.innerHTML = lines.join("<br>");
            return ok;
        }

        function validateAll(){
            const a = validateGuestName();
            const b = validateContact();
            const c = validateAddress();
            const d = validateRoomType();
            const e = validateDates();
            return (a && b && c && d && e);
        }

        function onSubmitForm(){
            const ok = validateAll();
            if(!ok) return false;

            const btn = document.getElementById("submitBtn");
            btn.disabled = true;
            btn.innerText = "Creating...";
            return true;
        }

        window.onload = function(){
            setMinDates();
            enforceCheckoutMin();
            validateDates();

            document.getElementById("guestName").addEventListener("input", validateGuestName);
            document.getElementById("contact").addEventListener("input", validateContact);
            document.getElementById("address").addEventListener("input", validateAddress);
            document.getElementById("roomType").addEventListener("change", validateRoomType);

            document.getElementById("checkIn").addEventListener("change", function(){
                enforceCheckoutMin();
                validateDates();
            });

            document.getElementById("checkOut").addEventListener("change", validateDates);
        };
    </script>
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
            <a class="active" href="new_reservation.jsp">New Reservation</a>
            <a href="reservations.jsp">Reservations</a>
            <a href="billing.jsp">Billing</a>
            <a href="help.jsp">Help</a>
        </nav>

        <div class="sidebar-footer">
            <a class="logout" href="LogoutServlet">Sign Out</a>
        </div>
    </aside>

    <!-- ===== Main Content ===== -->
    <main class="main">

        <h1 class="page-title">New Reservation</h1>
        <div class="sub">Register a new guest and create their booking.</div>
        <div class="welcome">Logged in as: <b><%= username %></b></div>

        <% if (success != null) { %>
            <div class="msg ok"><%= success %></div>
        <% } %>

        <% if (error != null) { %>
            <div class="msg err"><%= error %></div>
        <% } %>

        <div class="card">
            <form action="AddReservationServlet" method="post" onsubmit="return onSubmitForm();" autocomplete="off">

                <div class="row">
                    <div>
                        <label>Guest Name</label>
                        <input type="text" id="guestName" name="guestName"
                               placeholder="Full name"
                               minlength="3" maxlength="60"
                               required>
                        <div class="field-error" id="guestName_err"></div>
                        <div class="hint">Allowed: letters, spaces, . ' -</div>
                    </div>

                    <div>
                        <label>Contact Number</label>
                        <input type="text" id="contact" name="contact"
                               placeholder="+94XXXXXXXXX or 0XXXXXXXXX"
                               maxlength="12"
                               required>
                        <div class="field-error" id="contact_err"></div>
                        <div class="hint">Example: 0771234567 or +94771234567</div>
                    </div>
                </div>

                <label>Address</label>
                <textarea id="address" name="address" placeholder="Full address"
                          minlength="8" maxlength="200" required></textarea>
                <div class="field-error" id="address_err"></div>

                <label>Room Type</label>
                <select id="roomType" name="roomType" required>
                    <option value="">Select room type</option>
                    <option value="Ocean Suite">Ocean Suite</option>
                    <option value="Beach Villa">Beach Villa</option>
                    <option value="Deluxe Room">Deluxe Room</option>
                    <option value="Standard Room">Standard Room</option>
                </select>
                <div class="field-error" id="roomType_err"></div>

                <div class="row">
                    <div>
                        <label>Check-in Date</label>
                        <input type="date" id="checkIn" name="checkIn" required>
                        <div class="field-error" id="checkIn_err"></div>
                    </div>
                    <div>
                        <label>Check-out Date</label>
                        <input type="date" id="checkOut" name="checkOut" required>
                        <div class="field-error" id="checkOut_err"></div>
                    </div>
                </div>

                <div class="date-panel" id="datePanel"></div>

                <button id="submitBtn" type="submit">Create Reservation</button>

                <div class="small-note">
                    Check-out must be after check-in. Max stay: 30 nights. Booking max 365 days ahead.
                </div>

            </form>
        </div>

    </main>
</div>

</body>
</html>