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
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap" rel="stylesheet">
    <style>
        body { font-family: 'Poppins', sans-serif; background:#f4f7fb; margin:0; }
        .container { margin-left:280px; padding:40px; }
        .card {
            background:#fff;
            padding:30px;
            border-radius:16px;
            box-shadow:0 10px 25px rgba(0,0,0,0.05);
            max-width:800px;
        }
        input, select {
            width:100%;
            padding:12px;
            margin:10px 0 20px;
            border-radius:8px;
            border:1px solid #ccc;
        }
        button {
            width:100%;
            padding:14px;
            border:none;
            border-radius:8px;
            background:linear-gradient(135deg,#0b3a5d,#2e9bb7);
            color:white;
            font-weight:600;
            cursor:pointer;
        }
        h1 { margin-bottom:20px; }
    </style>
</head>
<body>

<div class="container">
    <h1>New Reservation</h1>

    <div class="card">
        <form action="AddReservationServlet" method="post">

            <label>Guest Name</label>
            <input type="text" name="guestName" required>

            <label>Contact Number</label>
            <input type="text" name="contact" required>

            <label>Address</label>
            <input type="text" name="address" required>

            <label>Room Type</label>
            <select name="roomType" required>
                <option value="">Select Room</option>
                <option>Ocean Suite</option>
                <option>Beach Villa</option>
                <option>Deluxe Room</option>
            </select>

            <label>Check-in Date</label>
            <input type="date" name="checkIn" required>

            <label>Check-out Date</label>
            <input type="date" name="checkOut" required>

            <button type="submit">Create Reservation</button>

        </form>
    </div>
</div>

</body>
</html>
