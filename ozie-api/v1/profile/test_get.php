<?php
// Turn on full error reporting
ini_set('display_errors', 1);
ini_set('display_startup_errors', 1);
error_reporting(E_ALL);

echo "<h3>1. File started successfully...</h3>";

// Database connection check
$dbPath = __DIR__ . '/../../db.php';
if (file_exists($dbPath)) {
    require_once $dbPath;
    echo "<h3>2. db.php included successfully!</h3>";
} else {
    die("<h3>db.php not found at: $dbPath</h3>");
}

if (!isset($conn) || $conn->connect_error) {
    die("<h3>Database connection failed: " . ($conn->connect_error ?? 'Unknown') . "</h3>");
}
echo "<h3>3. Database connected successfully!</h3>";

// Query test for User ID 331
$userId = 331;
$stmt = $conn->prepare("SELECT id, name, email, mobile, user_type, retailer_form_filled FROM users WHERE id = ? LIMIT 1");
if (!$stmt) {
    die("<h3>SQL Prepare Failed: " . $conn->error . "</h3>");
}

$stmt->bind_param("i", $userId);
$stmt->execute();
$user = $stmt->get_result()->fetch_assoc();
$stmt->close();

echo "<h3>4. User Data Fetched:</h3>";
echo "<pre>";
print_r($user);
echo "</pre>";
exit();