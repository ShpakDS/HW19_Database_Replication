# HW19_Database_Replication

## Setup

1. `docker compose up`
2. Run sh command `./scripts/check-and-fix-replication.sh`
3. Run sh command `./scripts/setup-and-run.sh`

## Result

Based on the latest test log:

1. **Master Node (`mysql_master`)**:
    - Data insertion succeeded. The test user (`Test User 499`) was inserted into the `users` table on the master node.

2. **Slave Nodes (`mysql_slave1` and `mysql_slave2`)**:
    - Replication was verified, and the inserted data was seamlessly replicated to both slave nodes in real-time.
    - Queries to slave nodes confirmed the presence of the same data (`Test User 499`) in their respective `users`
      tables.

3. **PHP Scripts**:
    - `write-data.php` correctly inserted data into the master node.
    - `read-data.php` accurately retrieved data from both slave nodes, demonstrating successful replication and no
      replication lag.

## Performance Test

- **Data Writing Script**: Successfully wrote data (`Test User 499`) to the master node.
- **Replication Verification**: Data replicated to both slaves (`mysql-s1`, `mysql-s2`) in real-time. The replicated
  data was verified using PHP scripts.

## Failure Scenarios

1. **Stopping `mysql-s1`:**
    - Replication continued seamlessly on `mysql-s2`.
    - Once `mysql-s1` was restarted, replication resumed without data loss.

2. **Altering Table Structure on Slave:**
    - Dropping a column (`email`) caused replication to fail due to table structure mismatch.
    - Removing a middle column (`name`) resulted in replication errors as well.
    - **Conclusion**: Structural changes must be synchronized across all nodes.

## Recommendations

- Avoid structural changes on slave nodes to ensure replication consistency.
- Implement monitoring for replication lag and errors using tools like `pt-heartbeat` or `mysql-replication-check`.
- Use a load balancer for read queries to distribute load across slaves for better scalability.