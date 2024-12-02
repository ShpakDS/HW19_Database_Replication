<?php
$options = getopt("", ["slave:"]);
$slaveHost = $options["slave"] ?? 'mysql_slave1';

$dsn = "mysql:host=$slaveHost;dbname=test_db";
$user = 'root';
$password = 'root';

try {
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Отримуємо дані з таблиці
    $stmt = $pdo->query("SELECT * FROM users");
    $users = $stmt->fetchAll(PDO::FETCH_ASSOC);

    echo "Data from $slaveHost:\n";
    foreach ($users as $user) {
        echo "{$user['id']}: {$user['name']} ({$user['email']})\n";
    }
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}