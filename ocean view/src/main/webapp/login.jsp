
<%@ page contentType="text/html;charset=UTF-8" language="java" %>
<!DOCTYPE html>
<html>
<head>
    <title>Sign In - Ocean View Resort</title>
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <!-- Google Font -->
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap" rel="stylesheet">

    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
            font-family: 'Poppins', sans-serif;
        }

        body {
            display: flex;
            height: 100vh;
        }

        /* LEFT SIDE IMAGE */
        .left {
            width: 55%;
            background: linear-gradient(rgba(0, 51, 102, 0.6),
                        rgba(0, 51, 102, 0.6)),
                        url("images/resort.jpg") center/cover no-repeat;
            color: white;
            display: flex;
            align-items: flex-end;
            padding: 60px;
        }

        .left-content h1 {
            font-size: 48px;
            font-weight: 700;
        }

        .left-content p {
            margin-top: 15px;
            font-size: 18px;
            opacity: 0.9;
        }

        /* ⭐ Gallery Styles */
        .gallery {
            margin-top: 25px;
            display: flex;
            gap: 15px;
        }

        .gallery img {
            width: 95px;
            height: 75px;
            object-fit: cover;
            border-radius: 12px;
            box-shadow: 0 5px 15px rgba(0,0,0,0.4);
            transition: 0.3s ease;
        }

        .gallery img:hover {
            transform: scale(1.1);
        }

        /* RIGHT SIDE FORM */
        .right {
            width: 45%;
            display: flex;
            justify-content: center;
            align-items: center;
            background: #f5f7fa;
        }

        .login-card {
            width: 380px;
        }

       .logo {
    display: flex;
    align-items: center;
    margin-bottom: 20px;
}

.logo-icon {
    font-size: 32px;
    margin-right: 10px;
}

        .login-card h2 {
            font-size: 32px;
            margin-bottom: 5px;
            color: #003366;
        }

        .login-card p {
            color: #666;
            margin-bottom: 25px;
        }

        label {
            font-weight: 500;
            font-size: 14px;
        }

        input {
            width: 100%;
            padding: 12px;
            margin: 8px 0 20px 0;
            border-radius: 8px;
            border: 1px solid #ccc;
            transition: 0.3s;
        }

        input:focus {
            border-color: #0077b6;
            outline: none;
            box-shadow: 0 0 5px rgba(0,119,182,0.4);
        }

        button {
            width: 100%;
            padding: 14px;
            border: none;
            border-radius: 8px;
            background: linear-gradient(135deg, #003366, #0077b6);
            color: white;
            font-size: 16px;
            font-weight: 600;
            cursor: pointer;
            transition: 0.3s;
        }

        button:hover {
            opacity: 0.9;
            transform: translateY(-2px);
        }

        .error {
            background: #ffdddd;
            color: red;
            padding: 10px;
            border-radius: 6px;
            margin-bottom: 15px;
            text-align: center;
        }

        @media (max-width: 900px) {
            .left {
                display: none;
            }
            .right {
                width: 100%;
            }
        }
    </style>
</head>
<body>

<!-- LEFT IMAGE SECTION -->
<div class="left">
    <div class="left-content">
        <h1>Ocean View Resort</h1>
        <p>Experience refined coastal luxury in the heart of Galle — where comfort meets the sea.</p>

        <!-- ⭐ Image Gallery Added -->
        <div class="gallery">
            <img src="images/pool.jpg" alt="Infinity Pool">
            <img src="images/room.jpg" alt="Luxury Suite">
            <img src="images/beach.jpg" alt="Private Beach">
        </div>
    </div>
</div>

<!-- RIGHT LOGIN FORM -->
<div class="right">
    <div class="login-card">

        <div class="logo">
    <span class="logo-icon">🌊</span>
    <h2>Ocean View Resort</h2>
</div>

        <h2>Member Login</h2>
        <p>Please enter your credentials to continue to the management portal</p>

        <% if(request.getAttribute("error") != null) { %>
            <div class="error">
                <%= request.getAttribute("error") %>
            </div>
        <% } %>

        <form action="LoginServlet" method="post">
            <label>User ID</label>
            <input type="text" name="username" placeholder="Enter your user ID" required>

            <label>Account Password</label>
            <input type="password" name="password" placeholder="Enter your secure password" required>

            <button type="submit">Access Dashboard</button>
        </form>

    </div>
</div>

</body>
</html>
