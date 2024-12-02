#!/bin/bash

# MySQL credentials
MASTER_HOST="mysql_master"
SLAVE1_HOST="mysql_slave1"
SLAVE2_HOST="mysql_slave2"
USER="root"
PASSWORD="root"
DATABASE="test_db"

# Function to create the database and table on Master
create_table_on_master() {
  echo "Creating database and table on Master ($MASTER_HOST)..."
  docker exec -i $MASTER_HOST mysql -u$USER -p$PASSWORD -e "
  CREATE DATABASE IF NOT EXISTS $DATABASE;
  USE $DATABASE;
  CREATE TABLE IF NOT EXISTS users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
  "
}

# Function to check the table existence on a host
check_table_existence() {
  local HOST=$1
  echo "Checking if 'users' table exists on $HOST..."
  docker exec -i $HOST mysql -u$USER -p$PASSWORD -e "
  USE $DATABASE;
  SHOW TABLES LIKE 'users';
  " | grep "users" >/dev/null

  if [ $? -eq 0 ]; then
    echo "Table 'users' exists on $HOST."
  else
    echo "Table 'users' does NOT exist on $HOST! Creating it manually..."
    docker exec -i $HOST mysql -u$USER -p$PASSWORD -e "
    CREATE DATABASE IF NOT EXISTS $DATABASE;
    USE $DATABASE;
    CREATE TABLE IF NOT EXISTS users (
      id INT AUTO_INCREMENT PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      email VARCHAR(255) NOT NULL,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );
    "
  fi
}

# Function to check and fix replication
fix_replication() {
  local SLAVE_HOST=$1
  echo "Checking and fixing replication on $SLAVE_HOST..."
  MASTER_STATUS=$(docker exec -i $MASTER_HOST mysql -u$USER -p$PASSWORD -e "SHOW MASTER STATUS\G")
  FILE=$(echo "$MASTER_STATUS" | grep "File:" | awk '{print $2}')
  POSITION=$(echo "$MASTER_STATUS" | grep "Position:" | awk '{print $2}')

  if [ -z "$FILE" ] || [ -z "$POSITION" ]; then
    echo "Error: Unable to fetch Master Status. Exiting..."
    exit 1
  fi

  docker exec -i $SLAVE_HOST mysql -u$USER -p$PASSWORD -e "
  STOP SLAVE;
  CHANGE MASTER TO
    MASTER_HOST='$MASTER_HOST',
    MASTER_USER='$USER',
    MASTER_PASSWORD='$PASSWORD',
    MASTER_LOG_FILE='$FILE',
    MASTER_LOG_POS=$POSITION;
  START SLAVE;
  "
}

# Function to insert data using PHP script
insert_data() {
  echo "Inserting data into Master using PHP script..."
  docker exec -it php_container php /var/www/html/scripts/write-data.php
}

# Function to read data using PHP script
read_data() {
  local SLAVE_HOST=$1
  echo "Reading data from $SLAVE_HOST using PHP script..."
  docker exec -it php_container php /var/www/html/scripts/read-data.php --slave=$SLAVE_HOST
}

# Main execution
echo "Starting setup and test process..."

# Step 1: Create database and table on Master
create_table_on_master

# Step 2: Verify table existence on Master and Slaves
check_table_existence $MASTER_HOST
check_table_existence $SLAVE1_HOST
check_table_existence $SLAVE2_HOST

# Step 3: Check and fix replication on Slaves
fix_replication $SLAVE1_HOST
fix_replication $SLAVE2_HOST

# Step 4: Insert data into Master
insert_data

# Step 5: Verify replication on Slaves
read_data $SLAVE1_HOST
read_data $SLAVE2_HOST

echo "Setup and test process completed."