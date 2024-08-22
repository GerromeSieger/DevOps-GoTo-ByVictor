# PostgreSQL Backup and restore on Ubuntu 24

This guide outlines the steps to backup and restore a PostgreSQL database on an Ubuntu 24 server.

- Create a backup script `postgres_backup.sh`:

```bash
nano /home/your_username/postgres_backup.sh
```

- Add the shell script to the file:

- Move the script to a location where the postgres user can access it:

```bash
sudo mv /home/your_username/postgres_backup.sh /var/lib/postgresql/
```

- Change the ownership of the script to postgres:

```bash
sudo chown postgres:postgres /var/lib/postgresql/postgres_backup.sh
```

- Ensure the script has the correct permissions:

```bash
sudo chmod 700 /var/lib/postgresql/postgres_backup.sh
```

- Create a file for the logs:

```bash
touch /var/lib/postgresql/postgres_backup.log
```

- Change the ownership of the log file to postgres:

```bash
sudo chown postgres:postgres /var/lib/postgresql/postgres_backup.log
```

- Ensure the log file has the correct permissions:

```bash
sudo chmod 700 /var/lib/postgresql/postgres_backup.log
```

### Setup s3 authentication

- Install aws-cli

- Authenticate with the cloud:

```bash
sudo -u postgres aws configure --profile eu2
```

- Verify authentication:

```bash
sudo -u postgres aws --profile eu2 --region default --endpoint-url https://eu2.contabostorage.com s3 ls
```

- Now, try running the script:

```bash
sudo -u postgres /var/lib/postgresql/postgres_backup.sh
```

- Set up the cron job Open the crontab file for the postgres user:

```bash
sudo -u postgres crontab -e
```

- Add the following line to run the backup every 4 days:

```bash
0 0 */4 * * /var/lib/postgresql/postgres_backup.sh
```

- Check the system logs for cron entries:

```bash
sudo grep CRON /var/log/syslog
```

### With a python script

- Create a python script `postgres_backup.py`:

- Install the necessary libraries:

```bash
pip3 install boto3
```

- Change the ownership of the script to postgres:

```bash
sudo chown postgres:postgres /var/lib/postgresql/postgres_backup.py
```

- Now, try running the script:

```bash
sudo -u postgres python3 /var/lib/postgresql/postgres_backup.py
```

### Restore a backup

- Extract the compressed backup sql file:

- Create the database:

```bash
sudo -u postgres psql
```

```sql
-- Create the database
CREATE DATABASE database;

-- Create the user and set the password
CREATE USER admin WITH ENCRYPTED PASSWORD '12345';

-- Change the database owner to admin
ALTER DATABASE database OWNER TO admin;

-- Grant all privileges to the user for the database
GRANT ALL PRIVILEGES ON DATABASE database TO admin;

-- Exit PostgreSQL shell
\q

```

- Run the sql script on the database:

```bash
sudo -u postgres psql database < backup.sql
```
