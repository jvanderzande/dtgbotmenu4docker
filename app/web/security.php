<?php
// Security pin check when defined
session_start();

function requirePIN() {
    $currentPIN = getenv('SECURITY_PIN');

    // If PIN is default (00000), skip security check
    if (empty($currentPIN)) {
				$_SESSION['pin_required'] = false;
        return true;
    }
		$_SESSION['pin_required'] = true;

    // Check if PIN is already verified in this session
    if (isset($_SESSION['pin_verified']) && $_SESSION['pin_verified'] === true) {
        return true;
    }

    // If PIN verification form was submitted
    if ($_SERVER['REQUEST_METHOD'] === 'POST' && isset($_POST['pin_input'])) {
        if ($_POST['pin_input'] === $currentPIN) {
            $_SESSION['pin_verified'] = true;
            return true;
        } else {
            $_SESSION['pin_error'] = 'Invalid PIN code';
            return false;
        }
    }

    // PIN not verified and not submitted - show PIN prompt
    return false;
}

function showPINPrompt() {
?>
    <!DOCTYPE html>
    <html>
    <head>
        <meta charset="utf-8">
        <title>Security PIN Required</title>
        <style>
            body {
                background-color: #eaeaea;
                display: flex;
                justify-content: center;
                align-items: center;
                height: 100vh;
                margin: 0;
                font-family: Arial, sans-serif;
            }
            .pin-container {
                background-color: white;
                padding: 40px;
                border-radius: 8px;
                box-shadow: 0 2px 10px rgba(0,0,0,0.1);
                text-align: center;
            }
            .pin-container h2 {
                color: #333;
                margin-top: 0;
            }
            .pin-container input[type="password"] {
                padding: 10px;
                font-size: 16px;
                width: 200px;
                border: 1px solid #ccc;
                border-radius: 4px;
                margin: 10px 0;
            }
            .pin-container button {
                padding: 10px 20px;
                font-size: 16px;
                background-color: #4CAF50;
                color: white;
                border: none;
                border-radius: 4px;
                cursor: pointer;
            }
            .pin-container button:hover {
                background-color: #45a049;
            }
            .error-message {
                color: red;
                margin-top: 10px;
            }
        </style>
    </head>
    <body>
        <div class="pin-container">
            <h2>Security PIN Required</h2>
            <form method="POST">
                <input type="password" name="pin_input" placeholder="Enter PIN" autofocus required>
                <br>
                <button type="submit">Verify</button>
            </form>
            <?php
            if (isset($_SESSION['pin_error'])) {
                echo '<p class="error-message">' . $_SESSION['pin_error'] . '</p>';
                unset($_SESSION['pin_error']);
            }
            ?>
        </div>
    </body>
    </html>
<?php
    exit;
}

// Add this function to security.php
function logoutPIN() {
    session_destroy();
    header('Location: ' . $_SERVER['PHP_SELF']);
    exit;
}
?>