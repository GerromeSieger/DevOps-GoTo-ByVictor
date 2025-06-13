# Setting Up Self-Hosted Runners for GitLab CI/CD

This guide provides step-by-step instructions for setting up and configuring self-hosted runners for GitLab CI/CD on a Linux machine.

## Prerequisites

- Linux server with sudo access
- Docker (optional, for Docker executor)
- Network access to your GitLab instance (gitlab.com or self-hosted)
- GitLab account with appropriate permissions to register runners

## 1. Register a Basic GitLab Runner

### 1.1 Install GitLab Runner

```bash
# Add the official GitLab repository
curl -L "https://packages.gitlab.com/install/repositories/runner/gitlab-runner/script.deb.sh" | sudo bash

# Install the latest version of GitLab Runner
sudo apt-get install gitlab-runner -y
```

### 1.2 Retrieve Runner Registration Token

1. Go to your GitLab project or group
   - For project-specific runner: Navigate to **Settings > CI/CD > Runners**
   - For group runner: Navigate to **Settings > CI/CD > Runners**
   - For instance-wide runner: As an admin, go to **Admin Area > Overview > Runners**

2. Click **New project runner**, **New group runner**, or **New instance runner** depending on your needs

3. Configure the runner details:
   - Enter a description (e.g., "Linux server runner")
   - Add tags (e.g., "linux", "docker", "production")
   - Select any optional features (run untagged jobs, lock to current project)
   - Click **Create runner**

4. Copy the registration token displayed

### 1.3 Register the Runner

```bash
sudo gitlab-runner register
```

Follow the interactive prompts:

1. Enter your GitLab instance URL (e.g., `https://gitlab.com/`)
2. Enter the registration token you copied
3. Enter a description for the runner
4. Enter tags (comma-separated, e.g., `linux,docker,production`)
5. Choose an executor (e.g., `shell`, `docker`, `docker-ssh`, `kubernetes`)
   - For simple setup, choose `shell`
   - For Docker-based setup, choose `docker`
6. If you chose Docker executor, enter the default Docker image (e.g., `ruby:3.0`)

### 1.4 Start the Runner Service

```bash
sudo gitlab-runner start
```

Verify the runner is working:

```bash
sudo gitlab-runner status
```

## 2. Configure Docker Executor (Recommended)

Docker executor provides better isolation and reproducibility.

### 2.1 Install Docker

```bash
# Update package index
sudo apt-get update

# Install prerequisites
sudo apt-get install -y apt-transport-https ca-certificates curl software-properties-common

# Add Docker's official GPG key
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add Docker repository
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Install Docker CE
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# Add gitlab-runner user to the docker group
sudo usermod -aG docker gitlab-runner
```

### 2.2 Register a Docker Executor Runner

```bash
sudo gitlab-runner register
```

For executor-specific options:
1. Select `docker` as the executor
2. Enter a default Docker image (e.g., `alpine:latest`)
3. If you need to pull private images, set up credentials

### 2.3 Customize Docker Configuration

Edit the GitLab Runner configuration:

```bash
sudo nano /etc/gitlab-runner/config.toml
```

Add or modify Docker-specific settings:

```toml
[[runners]]
  name = "Docker Runner"
  url = "https://gitlab.com/"
  token = "YOUR_TOKEN"
  executor = "docker"
  [runners.docker]
    tls_verify = false
    image = "alpine:latest"
    privileged = false
    disable_entrypoint_overwrite = false
    oom_kill_disable = false
    disable_cache = false
    volumes = ["/cache"]
    shm_size = 0
    # Add any extra hosts if needed
    # extra_hosts = ["host.docker.internal:host-gateway"]
```

Restart the runner to apply changes:

```bash
sudo gitlab-runner restart
```

## 3. Set Up Multiple Runners with Docker Compose

For managing multiple runners, Docker Compose provides an elegant solution.

### 3.1 Create Docker Compose File

```bash
mkdir -p ~/gitlab-runners
cd ~/gitlab-runners
nano docker-compose.yml
```

Add the following configuration:

```yaml
services:
  gitlab-runner-1:
    image: gitlab/gitlab-runner:latest
    container_name: gitlab-runner-1
    restart: always
    volumes:
      - ./config/runner-1:/etc/gitlab-runner
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - DOCKER_HOST=unix:///var/run/docker.sock

  gitlab-runner-2:
    image: gitlab/gitlab-runner:latest
    container_name: gitlab-runner-2
    restart: always
    volumes:
      - ./config/runner-2:/etc/gitlab-runner
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - DOCKER_HOST=unix:///var/run/docker.sock

  gitlab-runner-3:
    image: gitlab/gitlab-runner:latest
    container_name: gitlab-runner-3
    restart: always
    volumes:
      - ./config/runner-3:/etc/gitlab-runner
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      - DOCKER_HOST=unix:///var/run/docker.sock
```

### 3.2 Create Configuration Directories

```bash
mkdir -p config/runner-1 config/runner-2 config/runner-3
```

### 3.3 Start the Runner Containers

```bash
docker-compose up -d
```

### 3.4 Register Each Runner

For each runner, run the registration command:

```bash
# Register runner 1
docker exec -it gitlab-runner-1 gitlab-runner register

# Register runner 2
docker exec -it gitlab-runner-2 gitlab-runner register

# Register runner 3
docker exec -it gitlab-runner-3 gitlab-runner register
```

Follow the same interactive prompts as described in section 1.3, but make sure to give each runner a unique description and appropriate tags.

## 4. Configure Runner-Specific Settings

### 4.1 Concurrent Jobs

You can control how many jobs each runner can process concurrently.

Edit the configuration file:

```bash
# For native installation
sudo nano /etc/gitlab-runner/config.toml

# For Docker Compose setup
nano ~/gitlab-runners/config/runner-1/config.toml
```

Modify the concurrent setting:

```toml
concurrent = 3  # Number of concurrent jobs this runner can handle
```

### 4.2 Job Timeout

Set a timeout for jobs to prevent hung jobs from consuming resources:

```toml
[[runners]]
  # Other settings...
  [runners.custom]
    run_exec = ""
  [runners.cache]
    # Other cache settings...
  [runners.custom_build_dir]
  # Add job timeout (in seconds)
  timeout = 3600  # 1 hour timeout
```

### 4.3 Runner Tags and Specificity

In your GitLab CI/CD pipeline (`.gitlab-ci.yml`), target specific runners using tags:

```yaml
job_name:
  tags:
    - linux
    - docker
    - runner-1
  script:
    - echo "This job will only run on runners with all three tags"
```

## 5. Advanced Configuration

### 5.1 Autoscaling with Docker Machine

For dynamic scaling of runners, you can set up Docker Machine:

```toml
[[runners]]
  name = "Autoscaling Runner"
  url = "https://gitlab.com/"
  token = "YOUR_TOKEN"
  executor = "docker+machine"
  [runners.docker]
    image = "alpine:latest"
  [runners.machine]
    IdleCount = 1
    IdleTime = 1800
    MaxBuilds = 10
    MachineDriver = "digitalocean"
    MachineName = "gitlab-docker-machine-%s"
    MachineOptions = [
      "digitalocean-image=ubuntu-20-04-x64",
      "digitalocean-ssh-user=root",
      "digitalocean-access-token=YOUR_DIGITALOCEAN_TOKEN",
      "digitalocean-region=nyc1",
      "digitalocean-size=s-2vcpu-2gb",
      "digitalocean-private-networking=true"
    ]
```

### 5.2 Cache Configuration

Improve build performance with caching:

```toml
[[runners]]
  # Other settings...
  [runners.cache]
    Type = "s3"
    Shared = true
    [runners.cache.s3]
      ServerAddress = "s3.amazonaws.com"
      AccessKey = "YOUR_S3_ACCESS_KEY"
      SecretKey = "YOUR_S3_SECRET_KEY"
      BucketName = "gitlab-runner-cache"
      BucketLocation = "us-east-1"
```

## 6. Monitor and Maintain Runners

### 6.1 Viewing Runner Status

1. Go to your GitLab project, group, or admin area
2. Navigate to **Settings > CI/CD > Runners**
3. View all connected runners, their status, and when they last contacted GitLab

### 6.2 Troubleshooting Runners

View runner logs:

```bash
# For native installation
sudo gitlab-runner --debug run

# For Docker installation
docker logs gitlab-runner-1
```

### 6.3 Updating Runners

For native installation:

```bash
sudo apt-get update
sudo apt-get install gitlab-runner
```

For Docker Compose installation:

```bash
cd ~/gitlab-runners
docker-compose pull
docker-compose down
docker-compose up -d
```

### 6.4 Create a Maintenance Script

```bash
nano ~/update-runners.sh
```

Add the following:

```bash
#!/bin/bash
# Update GitLab Runners

cd ~/gitlab-runners
docker-compose down
docker-compose pull
docker-compose up -d

echo "Runners updated at $(date)" >> ~/runner-updates.log
```

Make it executable:

```bash
chmod +x ~/update-runners.sh
```

Set up a monthly cron job:

```bash
(crontab -l 2>/dev/null; echo "0 2 1 * * ~/update-runners.sh") | crontab -
```

## 7. Security Best Practices

1. **Use least privilege principle**:
   - Create a dedicated user for each runner
   - Limit sudo access for runner users

2. **Isolate runner environments**:
   - Use Docker executor for better isolation
   - Use private networks where possible

3. **Protect runner tokens**:
   - Store registration tokens securely
   - Rotate tokens periodically

4. **Secure sensitive information**:
   - Use GitLab CI/CD variables for secrets
   - Mask variables containing sensitive information

5. **Regular updates**:
   - Keep runners updated to receive security patches
   - Keep base Docker images updated

## 8. Example GitLab CI Configuration with Specific Runners

```yaml
stages:
  - build
  - test
  - deploy

build_job:
  stage: build
  tags:
    - linux
    - docker
    - builder
  script:
    - echo "Building with the builder runner"
    - docker build -t my-app:$CI_COMMIT_SHORT_SHA .

test_job:
  stage: test
  tags:
    - linux
    - docker
    - tester
  script:
    - echo "Testing with the tester runner"
    - docker run my-app:$CI_COMMIT_SHORT_SHA npm test

deploy_job:
  stage: deploy
  tags:
    - linux
    - shell
    - production
  script:
    - echo "Deploying with the production deployment runner"
    - ./deploy.sh
  only:
    - main
```

By following this guide, you should have a robust setup of self-hosted GitLab runners that can handle your CI/CD workloads efficiently and securely.