# Setup SonarQube with Docker Compose on a linux machine

1. Update System and Install Docker:

```bash
# Update package index and install Docker
sudo apt update -y
sudo apt install docker.io -y

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Set permissions and start Docker
sudo chmod 666 /var/run/docker.sock
sudo systemctl start docker
sudo systemctl enable docker

```

2. Set vm.max_map_count 

```bash
sudo nano /etc/sysctl.conf
```
Paste:
```
vm.max_map_count=262144
```

```bash
sudo sysctl -p
```


3. Create a Working Directory for SonarQube and create the docker-compose file:

```bash
mkdir Sonar
cd Sonar
nano docker-compose.yml
```
Paste this

```docker-compose
services:
  sonarqube:
    image: sonarqube:9.8.0-community
    container_name: sonarqube
    ports:
      - "9000:9000"
    networks:
      - sonarnet
    environment:
      - SONAR_JDBC_USERNAME=sonar
      - SONAR_JDBC_PASSWORD=sonarPass
      - sonar.jdbc.url=jdbc:postgresql://db:5432/sonar
    volumes:
      - sonarqube_data:/opt/sonarqube/data
      - sonarqube_extensions:/opt/sonarqube/extensions
      - sonarqube_logs:/opt/sonarqube/logs

  db:
    image: postgres:13
    container_name: sonarqube_postgres
    networks:
      - sonarnet
    environment:
      - POSTGRES_USER=sonar
      - POSTGRES_PASSWORD=sonarPass
    volumes:
      - postgresql:/var/lib/postgresql
      - postgresql_data:/var/lib/postgresql/data

networks:
  sonarnet:
    driver: bridge

volumes:
  sonarqube_data:
  sonarqube_extensions:
  sonarqube_logs:
  postgresql:
  postgresql_data:
```

4. Run the docker-compose:

```bash
docker-compose up -d
```

## Open the dashboad at http://ip-address:9000 and login as username: admin, password: admin, create a project and a token

5. Install sonarscanner: 

```bash
sudo apt install unzip -y
wget https://binaries.sonarsource.com/Distribution/sonar-scanner-cli/sonar-scanner-cli-6.0.0.4432-linux.zip
unzip sonar-scanner-cli-6.0.0.4432-linux.zip
sudo mv sonar-scanner-6.0.0.4432-linux /opt/sonar-scanner
```

6. Run scan:

```bash
sonar-scanner \
-Dsonar.projectKey=mytest\
-Dsonar.sources=. \
-Dsonar.host.url=http://localhost:9000 \
-Dsonar.login=sqa_68256ab72a9ed9b43c80965a985b6b61e672146e
```