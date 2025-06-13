# Setting Up Bitbucket Server with Docker

This guide explains how to set up Bitbucket Server using Docker on a Linux machine.

## Prerequisites

- Linux server with Docker and Docker Compose installed
- Minimum 4GB RAM allocated to Docker
- Sufficient disk space (at least 50GB recommended)
- Open ports for HTTP/HTTPS (80/443) or custom port

## Installation Steps

1. Create a working directory for Bitbucket Server:

```bash
mkdir bitbucket-server
cd bitbucket-server/
```

2. Create a `docker-compose.yml` file:

```bash
nano docker-compose.yml
```

3. Add the following configuration:

```yaml
services:
  bitbucket:
    image: atlassian/bitbucket:latest
    container_name: bitbucket-server
    ports:
      - "8080:7990"   # HTTP port
      - "7999:7999"   # SSH port for Git
    volumes:
      - bitbucket-data:/var/atlassian/application-data/bitbucket
    environment:
      - JAVA_OPTS=-Xms1g -Xmx2g
      - ELASTICSEARCH_ENABLED=true
      - SERVER_PROXY_NAME=your-domain.com  # Optional: Set if using reverse proxy
      - SERVER_PROXY_PORT=443              # Optional: Set if using reverse proxy
      - SERVER_SCHEME=https                # Optional: Set if using HTTPS
    restart: unless-stopped

  postgresql:
    image: postgres:13
    container_name: bitbucket-postgres
    ports:
      - "5432:5432"
    volumes:
      - postgresql-data:/var/lib/postgresql/data
    environment:
      - POSTGRES_USER=bitbucket
      - POSTGRES_PASSWORD=bitbucket_password  # Change this!
      - POSTGRES_DB=bitbucket
    restart: unless-stopped

volumes:
  bitbucket-data:
    external: false
  postgresql-data:
    external: false
```

4. Start PostgreSQL database first:

```bash
docker-compose up -d postgresql
```

5. Wait a minute for PostgreSQL to initialize, then start Bitbucket Server:

```bash
docker-compose up -d bitbucket
```

6. Check the logs to monitor the startup process:

```bash
docker-compose logs -f bitbucket
```

7. Access the Bitbucket Server setup wizard at `http://your-server-ip:7990` and follow these steps:

   - Choose "External database" when prompted
   - Enter the database connection details:
     - Database type: PostgreSQL
     - Hostname: postgresql
     - Port: 5432
     - Database name: bitbucket
     - Username: bitbucket
     - Password: bitbucket_password (or the password you set in docker-compose.yml)
   - Complete the setup wizard by creating the admin account
   - Configure your license key (trial or purchased) at https://www.atlassian.com/purchase/my/license-evaluation

8. Create your first project:
   - Log in with your admin account
   - Click "Create project"
   - Enter a project name and key
   - Choose project type (normal or personal)
   - Click "Create project"

9. Create a repository:
   - Navigate to your project
   - Click "Create repository"
   - Enter repository name and other details
   - Choose repository type (Git)
   - Click "Create repository"

10. Configure backup strategy:

```bash
mkdir -p /path/to/backup/location

# Create a backup script
cat > bitbucket-backup.sh << 'EOF'
#!/bin/bash
BACKUP_DIR="/path/to/backup/location"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")

# Create backup directories
mkdir -p $BACKUP_DIR/database
mkdir -p $BACKUP_DIR/bitbucket

# Backup PostgreSQL database
docker exec bitbucket-postgres pg_dump -U bitbucket bitbucket > $BACKUP_DIR/database/bitbucket_db_$TIMESTAMP.sql

# Backup Bitbucket data
docker run --rm -v bitbucket-data:/source:ro -v $BACKUP_DIR/bitbucket:/destination:rw ubuntu tar -czf /destination/bitbucket_data_$TIMESTAMP.tar.gz -C /source .

# Remove backups older than 14 days
find $BACKUP_DIR -name "*.sql" -type f -mtime +14 -delete
find $BACKUP_DIR -name "*.tar.gz" -type f -mtime +14 -delete
EOF

chmod +x bitbucket-backup.sh

# Add to crontab to run daily at 2 AM
(crontab -l 2>/dev/null; echo "0 2 * * * /path/to/bitbucket-backup.sh > /path/to/backup/location/backup.log 2>&1") | crontab -
```

11. Set up HTTPS with a reverse proxy (optional but recommended):

Create a file named `nginx.conf`:

```bash
nano nginx.conf
```

Add the following configuration:

```nginx
server {
    listen 80;
    server_name your-domain.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name your-domain.com;

    ssl_certificate /etc/nginx/ssl/your-domain.com.crt;
    ssl_certificate_key /etc/nginx/ssl/your-domain.com.key;

    location / {
        proxy_pass http://bitbucket-server:7990;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /bitbucket/scm {
        proxy_pass http://bitbucket-server:7999;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

Add Nginx service to your docker-compose.yml:

```yaml
  nginx:
    image: nginx:latest
    container_name: bitbucket-nginx
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/conf.d/default.conf
      - ./ssl:/etc/nginx/ssl
    depends_on:
      - bitbucket
    restart: unless-stopped
```

12. Monitoring and maintenance:

```bash
# View running containers
docker ps

# Check Bitbucket logs
docker-compose logs -f bitbucket

# Check database logs
docker-compose logs -f postgresql

# Restart services
docker-compose restart bitbucket
docker-compose restart postgresql

# Update Bitbucket Server (always back up first!)
docker-compose pull bitbucket
docker-compose up -d bitbucket
```

13. Set up a routine maintenance schedule:
   - Regular backups (configured in step 10)
   - Monthly updates of Bitbucket Server and PostgreSQL
   - Regular monitoring of logs and container health

## Troubleshooting

1. **Container won't start:**
   - Check logs: `docker-compose logs -f bitbucket`
   - Verify memory allocation: `docker stats`

2. **Database connection issues:**
   - Verify PostgreSQL is running: `docker ps | grep postgres`
   - Check database logs: `docker-compose logs postgresql`
   - Confirm connection details in Bitbucket configuration

3. **Performance issues:**
   - Increase Java heap size in docker-compose.yml
   - Monitor container resources: `docker stats`
   - Consider adding more RAM or CPU to host

4. **Repository access issues:**
   - Verify SSH port (7999) is open on the host
   - Check user permissions in Bitbucket
   - Verify authentication credentials

## Security Recommendations

1. **Change default credentials:**
   - Use strong passwords for all accounts
   - Change the PostgreSQL password in docker-compose.yml

2. **Network security:**
   - Use HTTPS with a valid SSL certificate
   - Restrict access to SSH and management ports
   - Consider using a private network for database connections

3. **Regular updates:**
   - Stay current with Bitbucket Server updates
   - Update the base Docker images regularly

4. **Access control:**
   - Implement project and repository permission schemes
   - Use LDAP/AD integration for user management
   - Enable two-factor authentication if available