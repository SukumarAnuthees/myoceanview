<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>

<title>Ocean View Resort</title>

<meta name="viewport" content="width=device-width, initial-scale=1.0">

<link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap" rel="stylesheet">

<style>

*{
margin:0;
padding:0;
box-sizing:border-box;
font-family:'Poppins',sans-serif;
}

/* ===== BACKGROUND ===== */

body{

background:
linear-gradient(rgba(10,30,50,0.6),rgba(10,30,50,0.7)),
url("images/resort-bg.jpg");

background-size:cover;
background-position:center;
background-attachment:fixed;
color:white;

}

/* ===== NAVBAR ===== */

.navbar{

display:flex;
justify-content:space-between;
align-items:center;
padding:20px 60px;

}

.logo{

font-size:28px;
font-weight:700;
letter-spacing:1px;

}

.nav-links a{

margin-left:25px;
text-decoration:none;
color:white;
font-weight:500;
transition:0.3s;

}

.nav-links a:hover{

color:#5ee6ff;

}

/* ===== HERO ===== */

.hero{

height:85vh;
display:flex;
flex-direction:column;
justify-content:center;
align-items:center;
text-align:center;
padding:20px;

}

.hero h1{

font-size:65px;
margin-bottom:20px;

}

.hero p{

max-width:700px;
font-size:20px;
line-height:1.6;
margin-bottom:35px;

}

/* ===== BUTTONS ===== */

.btn{

padding:14px 30px;
border-radius:30px;
border:none;
font-size:16px;
cursor:pointer;
margin:10px;
transition:0.3s;
font-weight:600;

}

.btn-primary{

background:#22c1ff;
color:white;

}

.btn-primary:hover{

background:#00a2e0;

}

.btn-outline{

background:transparent;
border:2px solid white;
color:white;

}

.btn-outline:hover{

background:white;
color:#333;

}

/* ===== GLASS CARDS ===== */

.features{

display:flex;
justify-content:center;
gap:30px;
flex-wrap:wrap;
padding:60px 10%;

}

.card{

background:rgba(255,255,255,0.15);
backdrop-filter:blur(10px);
padding:25px;
border-radius:12px;
width:260px;
text-align:center;
box-shadow:0 5px 20px rgba(0,0,0,0.3);
transition:0.3s;

}

.card:hover{

transform:translateY(-10px);

}

.card h3{

margin-bottom:10px;

}

/* ===== ROOMS ===== */

.rooms{

background:white;
color:#333;
padding:80px 10%;
text-align:center;

}

.rooms h2{

font-size:36px;
margin-bottom:40px;

}

.room-container{

display:flex;
flex-wrap:wrap;
justify-content:center;
gap:25px;

}

.room{

background:#f8f9fc;
padding:25px;
border-radius:10px;
width:230px;
box-shadow:0 5px 15px rgba(0,0,0,0.1);

}

.room h3{

margin-bottom:10px;

}

/* ===== FOOTER ===== */

.footer{

text-align:center;
padding:25px;
background:#0a2540;
margin-top:40px;

}

</style>

</head>

<body>

<!-- NAVBAR -->

<div class="navbar">

<div class="logo">

🌊 Ocean View Resort

</div>

<div class="nav-links">

<a href="#">Home</a>
<a href="new_reservation.jsp">Reservation</a>
<a href="login.jsp">Staff Login</a>
<a href="help.jsp">Help</a>

</div>

</div>

<!-- HERO -->

<section class="hero">

<h1>Relax by the Ocean</h1>

<p>

Experience comfort, luxury, and unforgettable views at Ocean View Resort.
Enjoy peaceful rooms, fresh sea breeze, and warm hospitality.

</p>

<div>

<a href="new_reservation.jsp">
<button class="btn btn-primary">Book Your Stay</button>
</a>

<a href="login.jsp">
<button class="btn btn-outline">Staff Login</button>
</a>

</div>

</section>

<!-- FEATURES -->

<section class="features">

<div class="card">

<h3>🌊 Ocean Views</h3>

<p>
Enjoy beautiful sunrise and sunset views directly from your room.
</p>

</div>

<div class="card">

<h3>🛎 Quality Service</h3>

<p>
Our friendly staff ensures a comfortable and relaxing stay.
</p>

</div>

<div class="card">

<h3>🏖 Luxury Experience</h3>

<p>
Modern rooms and peaceful surroundings for a perfect vacation.
</p>

</div>

</section>

<!-- ROOMS -->

<section class="rooms">

<h2>Room Types</h2>

<div class="room-container">

<div class="room">
<h3>Standard Room</h3>
<p>LKR 10,000 / Night</p>
</div>

<div class="room">
<h3>Deluxe Room</h3>
<p>LKR 15,000 / Night</p>
</div>

<div class="room">
<h3>Ocean Suite</h3>
<p>LKR 20,000 / Night</p>
</div>

<div class="room">
<h3>Beach Villa</h3>
<p>LKR 30,000 / Night</p>
</div>

</div>

</section>

<!-- FOOTER -->

<div class="footer">

© 2026 Ocean View Resort | Designed for Guest Comfort

</div>

</body>
</html>