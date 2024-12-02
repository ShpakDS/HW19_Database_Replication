CREATE DATABASE IF NOT EXISTS test_db;

USE test_db;

CREATE TABLE users
(
    id         INT AUTO_INCREMENT PRIMARY KEY,
    name       VARCHAR(255),
    email      VARCHAR(255),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Enable binary logging for replication
SET GLOBAL log_bin = 'mysql-bin';
SET GLOBAL server_id = 1;