<%@ page contentType="text/html;charset=UTF-8" %>
<%
    if (session.getAttribute("username") == null) {
        response.sendRedirect("login.jsp");
        return;
    }
%>

<!DOCTYPE html>
<html>
<head>
    <title>New Reservation</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0"/>

    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap" rel="stylesheet">

    <style>
        body { font-family: 'Poppins', sans-serif; background:#f4f7fb; margin:0; }

        .container { margin-left:280px; padding:40px; }

        .card {
            background:#fff;
            padding:30px;
            border-radius:16px;
            box-shadow:0 10px 25px rgba(0,0,0,0.05);
            max-width:820px;
            border:1px solid rgba(0,0,0,0.06);
        }

        .row{
            display:grid;
            grid-template-columns: 1fr 1fr;
            gap:16px;
        }

        @media(max-width: 900px){
            .container{ margin-left:0; padding:20px; }
            .row{ grid-template-columns:1fr; }
        }

        label { font-weight:600; font-size:14px; color:#0f172a; }

        .hint { font-size:12px; color:#64748b; margin-top:-14px; margin-bottom:14px; }

        input, select, textarea {
            width:100%;
            padding:12px;
            margin:10px 0 18px;
            border-radius:10px;
            border:1px solid #cbd5e1;
            outline:none;
            transition:.2s;
            background:#fff;
        }

        textarea{ resize:vertical; min-height:90px; }

        input:focus, select:focus, textarea:focus {
            border-color:#2e9bb7;
            box-shadow:0 0 0 3px rgba(46,155,183,0.18);
        }

        button {
            width:100%;
            padding:14px;
            border:none;
            border-radius:10px;
            background:linear-gradient(135deg,#0b3a5d,#2e9bb7);
            color:white;
            font-weight:700;
            cursor:pointer;
            transition:.2s;
        }

        button:hover{ opacity:.95; transform: translateY(-1px); }

        button:disabled{ opacity:.6; cursor:not-allowed; transform:none; }

        h1 { margin-bottom:8px; }

        .sub { color:#64748b; margin-bottom:20px; }

        .msg {
            padding:12px 14px;
            border-radius:10px;
            margin-bottom:16px;
            font-size:14px;
        }

        .msg.ok { background:#ecfdf5; border:1px solid #bbf7d0; color:#166534; }

        .msg.err{ background:#fef2f2; border:1px solid #fecaca; color:#991b1b; }

        .small-note { font-size:12px; color:#64748b; margin-top:10px; text-align:center; }

        /* Back Button */
        .back-btn{
            display:inline-flex;
            align-items:center;
            gap:8px;
            padding:10px 18px;
            background:#ffffff;
            border:1px solid #cbd5e1;
            border-radius:10px;
            text-decoration:none;
            font-weight:600;
            color:#0f172a;
            transition:.2s;
            margin-bottom:20px;
        }

        .back-btn:hover{
            background:#f1f5f9;
            transform:translateY(-1px);
        }
    </style>

    <script>
        function isValidSLPhone(phone){
            const p = phone.replace(/\s+/g,'');
            return /^(\+94\d{9}|0\d{9})$/.test(p);
        }

        function daysBetween(d1, d2){
            const a = new Date(d1);
            const b = new Date(d2);
            return Math.round((b - a) / (1000*60*60*24));
        }

        function setMinDates(){
            const today = new Date();
            const yyyy = today.getFullYear();
            const mm = String(today.getMonth()+1).padStart(2,'0');
            const dd = String(today.getDate()).padStart(2,'0');
            const min = `${yyyy}-${mm}-${dd}`;
            document.getElementById("checkIn").min = min;
            document.getElementById("checkOut").min = min;
        }

        function validateForm(){
            const guestName = document.getElementById("guestName").value.trim();
            const contact   = document.getElementById("contact").value.trim();
            const address   = document.getElementById("address").value.trim();
            const roomType  = document.getElementById("roomType").value;
            const checkIn   = document.getElementById("checkIn").value;
            const checkOut  = document.getElementById("checkOut").value;

            if(guestName.length < 3 || !/^[A-Za-z.\s]+$/.test(guestName)){
                alert("Guest Name must be at least 3 characters and contain only letters/spaces.");
                return false;
            }

            if(!isValidSLPhone(contact)){
                alert("Enter a valid contact number: +94XXXXXXXXX or 0XXXXXXXXX.");
                return false;
            }

            if(address.length < 8){
                alert("Address must be at least 8 characters.");
                return false;
            }

            if(roomType === ""){
                alert("Please select a room type.");
                return false;
            }

            if(!checkIn || !checkOut){
                alert("Please select check-in and check-out dates.");
                return false;
            }

            const today = new Date(); today.setHours(0,0,0,0);
            const inD = new Date(checkIn); inD.setHours(0,0,0,0);
            const outD = new Date(checkOut); outD.setHours(0,0,0,0);

            if(inD < today){
                alert("Check-in date cannot be in the past.");
                return false;
            }

            if(outD <= inD){
                alert("Check-out date must be after check-in date.");
                return false;
            }

            const stay = daysBetween(checkIn, checkOut);
            if(stay > 30){
                alert("Maximum stay allowed is 30 days.");
                return false;
            }

            document.getElementById("submitBtn").disabled = true;
            document.getElementById("submitBtn").innerText = "Creating...";
            return true;
        }

        window.onload = setMinDates;
    </script>
</head>

<body>

<div class="container">

    <h1>New Reservation</h1>
    <div class="sub">Register a new guest and create their booking.</div>

    <!-- Back Button -->
    <a href="dashboard.jsp" class="back-btn">
        ← Back to Dashboard
    </a>

    <!-- Messages -->
    <%
        String success = (String) request.getAttribute("success");
        String error = (String) request.getAttribute("error");
        if (success != null) {
    %>
        <div class="msg ok"><%= success %></div>
    <%
        }
        if (error != null) {
    %>
        <div class="msg err"><%= error %></div>
    <%
        }
    %>

    <div class="card">
        <form action="AddReservationServlet" method="post" onsubmit="return validateForm();" autocomplete="off">

            <div class="row">
                <div>
                    <label>Guest Name</label>
                    <input type="text" id="guestName" name="guestName"
                           placeholder="Full name"
                           minlength="3"
                           pattern="[A-Za-z.\s]+"
                           required>
                </div>

                <div>
                    <label>Contact Number</label>
                    <input type="text" id="contact" name="contact"
                           placeholder="+94XXXXXXXXX or 0XXXXXXXXX"
                           required>
                </div>
            </div>

            <label>Address</label>
            <textarea id="address" name="address" placeholder="Full address" minlength="8" required></textarea>

            <label>Room Type</label>
            <select id="roomType" name="roomType" required>
                <option value="">Select room type</option>
                <option value="Ocean Suite">Ocean Suite</option>
                <option value="Beach Villa">Beach Villa</option>
                <option value="Deluxe Room">Deluxe Room</option>
                <option value="Standard Room">Standard Room</option>
            </select>

            <div class="row">
                <div>
                    <label>Check-in Date</label>
                    <input type="date" id="checkIn" name="checkIn" required>
                </div>
                <div>
                    <label>Check-out Date</label>
                    <input type="date" id="checkOut" name="checkOut" required>
                </div>
            </div>

            <button id="submitBtn" type="submit">Create Reservation</button>

            <div class="small-note">
                Check-out must be after check-in. Maximum stay: 30 days.
            </div>

        </form>
    </div>

</div>

</body>
</html>
