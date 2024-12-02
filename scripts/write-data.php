<?php
$dsn = 'mysql:host=mysql_master;dbname=test_db';
$user = 'root';
$password = 'root';

try {
    $pdo = new PDO($dsn, $user, $password);
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

    // Генеруємо тестові дані
    $name = "Test User " . rand(1, 1000);
    $email = strtolower(str_replace(' ', '_', $name)) . "@example.com";

    // Вставка даних
    $stmt = $pdo->prepare("INSERT INTO users (name, email) VALUES (:name, :email)");
    $stmt->execute([':name' => $name, ':email' => $email]);

    echo "Inserted data: Name = $name, Email = $email\n";
} catch (PDOException $e) {
    echo "Error: " . $e->getMessage();
}