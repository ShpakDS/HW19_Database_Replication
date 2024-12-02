#!/bin/bash

# MySQL credentials
MASTER_HOST="mysql_master"
SLAVE1_HOST="mysql_slave1"
SLAVE2_HOST="mysql_slave2"
USER="root"
PASSWORD="root"
DATABASE="test_db"
TABLE="users"

# Function to check replication status
check_replication_status() {
  local HOST=$1
  echo "Checking replication status on $HOST..."
  docker exec -i $HOST mysql -u$USER -p$PASSWORD -e "SHOW SLAVE STATUS\G" | grep -E "Slave_IO_Running|Slave_SQL_Running|Last_SQL_Error"
}

# Function to fix replication
fix_replication() {
  local SLAVE_HOST=$1
  echo "Fixing replication on $SLAVE_HOST..."
  MASTER_STATUS=$(docker exec -i $MASTER_HOST mysql -u$USER -p$PASSWORD -e "SHOW MASTER STATUS\G")
  FILE=$(echo "$MASTER_STATUS" | grep "File:" | awk '{print $2}')
  POSITION=$(echo "$MASTER_STATUS" | grep "Position:" | awk '{print $2}')

  if [ -z "$FILE" ] || [ -z "$POSITION" ]; then
    echo "Error: Unable to fetch Master Status. Exiting..."
    exit 1
  fi

  echo "Master Log File: $FILE"
  echo "Master Log Position: $POSITION"

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

# Function to create table on Slave
create_table_on_slave() {
  local HOST=$1
  echo "Creating table '$TABLE' on $HOST..."
  docker exec -i $HOST mysql -u$USER -p$PASSWORD -e "
  CREATE DATABASE IF NOT EXISTS $DATABASE;
  USE $DATABASE;
  CREATE TABLE IF NOT EXISTS $TABLE (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
  );
  "
}

# Main execution
echo "Starting replication check and fix process..."

# Step 1: Check replication status on Slaves
check_replication_status $SLAVE1_HOST
check_replication_status $SLAVE2_HOST

# Step 2: Fix replication on Slaves if needed
fix_replication $SLAVE1_HOST
fix_replication $SLAVE2_HOST

# Step 3: Check if table exists on Slaves, create if necessary
echo "Checking if table '$TABLE' exists on $SLAVE1_HOST..."
docker exec -i $SLAVE1_HOST mysql -u$USER -p$PASSWORD -e "
USE $DATABASE;
SHOW TABLES LIKE '$TABLE';
" | grep "$TABLE" > /dev/null || create_table_on_slave $SLAVE1_HOST

echo "Checking if table '$TABLE' exists on $SLAVE2_HOST..."
docker exec -i $SLAVE2_HOST mysql -u$USER -p$PASSWORD -e "
USE $DATABASE;
SHOW TABLES LIKE '$TABLE';
" | grep "$TABLE" > /dev/null || create_table_on_slave $SLAVE2_HOST

echo "Replication check and fix process completed."