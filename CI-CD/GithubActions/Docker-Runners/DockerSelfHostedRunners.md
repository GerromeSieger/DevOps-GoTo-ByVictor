# Setting Up Multiple GitHub Actions Self-Hosted Runners with Docker Compose Using Env Files

This guide demonstrates how to set up multiple GitHub Actions self-hosted runners using Docker Compose with environment variables stored in `.env` files for better security and configuration management.

## Prerequisites

- Linux server with Docker and Docker Compose installed
- GitHub account with admin access to your repository or organization
- Runner registration tokens from GitHub

## Setup Process

### 1. Create Project Directory

First, create a directory for your runners setup:

```bash
mkdir -p github-runners
cd github-runners
```

### 2. Create Main Environment File

Create a `.env` file with common configurations:

```bash
nano .env
```

Add the following variables:

```
# GitHub Repository/Organization configuration
GITHUB_REPO_URL=https://github.com/your-username/your-repo
# Or for organization runners:
# GITHUB_ORG_NAME=your-organization-name

# Runner configuration
RUNNER_SCOPE=repo  # Use 'repo' for repository runners or 'org' for organization runners
LABELS_COMMON=linux,x64,docker
```

### 3. Create Runner-Specific Environment Files

Create separate environment files for each runner to maintain individual configurations:

```bash
mkdir -p runner-envs
```

For Runner 1:
```bash
nano runner-envs/runner-1.env
```

Add:
```
RUNNER_NAME=docker-runner-1
RUNNER_TOKEN=your-runner-1-token
RUNNER_WORKDIR=/tmp/runner-1-workdir
```

For Runner 2:
```bash
nano runner-envs/runner-2.env
```

Add:
```
RUNNER_NAME=docker-runner-2
RUNNER_TOKEN=your-runner-2-token
RUNNER_WORKDIR=/tmp/runner-2-workdir
```

For Runner 3:
```bash
nano runner-envs/runner-3.env
```

Add:
```
RUNNER_NAME=docker-runner-3
RUNNER_TOKEN=your-runner-3-token
RUNNER_WORKDIR=/tmp/runner-3-workdir
```

### 4. Create Docker Compose Configuration

Create a `docker-compose.yml` file:

```bash
nano docker-compose.yml
```

Add the following configuration for multiple runners using environment files:

```yaml
services:
  runner-1:
    image: myoung34/github-runner:latest
    restart: unless-stopped
    env_file:
      - .env
      - runner-envs/runner-1.env
    environment:
      - REPO_URL=${GITHUB_REPO_URL:-}
      - ORG_NAME=${GITHUB_ORG_NAME:-}
      - LABELS=${LABELS_COMMON_1}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - runner-1-data:${RUNNER_WORKDIR:-/tmp/runner-1-workdir}

  runner-2:
    image: myoung34/github-runner:latest
    restart: unless-stopped
    env_file:
      - .env
      - runner-envs/runner-2.env
    environment:
      - REPO_URL=${GITHUB_REPO_URL:-}
      - ORG_NAME=${GITHUB_ORG_NAME:-}
      - LABELS=${LABELS_COMMON_2}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - runner-2-data:${RUNNER_WORKDIR:-/tmp/runner-2-workdir}

  runner-3:
    image: myoung34/github-runner:latest
    restart: unless-stopped
    env_file:
      - .env
      - runner-envs/runner-3.env
    environment:
      - REPO_URL=${GITHUB_REPO_URL:-}
      - ORG_NAME=${GITHUB_ORG_NAME:-}
      - LABELS=${LABELS_COMMON_3}
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - runner-3-data:${RUNNER_WORKDIR:-/tmp/runner-3-workdir}

volumes:
  runner-1-data:
  runner-2-data:
  runner-3-data:
```

### 5. Create a Helper Script to Update Tokens

Since GitHub runner tokens expire, create a helper script to easily update them:

```bash
nano update-token.sh
```

Add:

```bash
#!/bin/bash

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <runner-number> <new-token>"
  exit 1
fi

RUNNER_NUM=$1
NEW_TOKEN=$2
RUNNER_ENV_FILE="runner-envs/runner-${RUNNER_NUM}.env"

if [ ! -f "$RUNNER_ENV_FILE" ]; then
  echo "Error: Runner env file $RUNNER_ENV_FILE not found"
  exit 1
fi

sed -i "s/^RUNNER_TOKEN=.*/RUNNER_TOKEN=${NEW_TOKEN}/" "$RUNNER_ENV_FILE"
echo "Token updated in $RUNNER_ENV_FILE"

docker-compose restart "runner-${RUNNER_NUM}"
echo "Runner ${RUNNER_NUM} restarted with new token"
```

Make it executable:

```bash
chmod +x update-token.sh
```

### 6. Get Runner Registration Tokens

For each runner, you'll need a separate registration token from GitHub:

#### For Repository Runners
1. Go to your GitHub repository
2. Navigate to **Settings > Actions > Runners > New self-hosted runner**
3. Copy the token from the configuration instructions
4. Add each token to the respective runner env file

#### For Organization Runners
1. Go to your GitHub organization
2. Navigate to **Settings > Actions > Runners > New self-hosted runner**
3. Copy the token from the configuration instructions
4. Add each token to the respective runner env file
5. Make sure to set `RUNNER_SCOPE=org` in your main `.env` file and provide `GITHUB_ORG_NAME` instead of `GITHUB_REPO_URL`

### 7. Start Your Runners

Start all the runners:

```bash
docker-compose up -d
```

This will launch all three runner containers in detached mode.

### 8. Verify Runner Status

Check if your runners are running properly:

```bash
docker-compose ps
```

View the logs for a specific runner:

```bash
docker-compose logs runner-1
```

Verify on GitHub:
1. Go to your repository or organization settings
2. Navigate to **Actions > Runners**
3. Your runners should be listed and show as "Idle"

### 9. Using Specific Runners in Workflows

You can target specific runners in your GitHub Actions workflow:

```yaml
name: CI with Specific Runner

on: [push, pull_request]

jobs:
  build:
    runs-on: [self-hosted, runner-1]
    steps:
      - uses: actions/checkout@v3
      - name: Build on Runner 1
        run: echo "Running on runner-1"
        
  test:
    runs-on: [self-hosted, runner-2]
    needs: build
    steps:
      - uses: actions/checkout@v3
      - name: Test on Runner 2
        run: echo "Running on runner-2"
        
  deploy:
    runs-on: [self-hosted, runner-3]
    needs: test
    steps:
      - uses: actions/checkout@v3  
      - name: Deploy on Runner 3
        run: echo "Running on runner-3"
```

### 10. Updating Tokens When They Expire

When a runner token expires, you'll need to get a new one and update the runner:

```bash
# Get a new token from GitHub (repo or org settings)
# Then update the token for runner 1
./update-token.sh 1 your-new-token-for-runner-1
```

### 11. Adding a New Runner

To add a new runner:

1. Create a new env file:

```bash
nano runner-envs/runner-4.env
```

2. Add the runner configuration:

```
RUNNER_NAME=docker-runner-4
RUNNER_TOKEN=your-runner-4-token
RUNNER_WORKDIR=/tmp/runner-4-workdir
LABELS_SPECIFIC=runner-4
```

3. Add the new runner to `docker-compose.yml`:

```yaml
# Runner 4
runner-4:
  image: myoung34/github-runner:latest
  restart: unless-stopped
  env_file:
    - .env
    - runner-envs/runner-4.env
  environment:
    - REPO_URL=${GITHUB_REPO_URL:-}
    - ORG_NAME=${GITHUB_ORG_NAME:-}
    - LABELS=${LABELS_COMMON},${LABELS_SPECIFIC}
  volumes:
    - /var/run/docker.sock:/var/run/docker.sock
    - runner-4-data:${RUNNER_WORKDIR:-/tmp/runner-4-workdir}
```

4. Add the new volume:

```yaml
volumes:
  runner-1-data:
  runner-2-data:
  runner-3-data:
  runner-4-data:
```

5. Start the new runner:

```bash
docker-compose up -d runner-4
```

### 12. Monitoring and Maintenance

You can create a simple script to check the status of your runners:

```bash
nano check-runners.sh
```

Add:

```bash
#!/bin/bash

echo "===== Runner Status ====="
docker-compose ps

echo -e "\n===== Runner Logs (last 5 lines each) ====="
for runner in runner-1 runner-2 runner-3; do
  echo -e "\n--- $runner ---"
  docker-compose logs --tail=5 $runner
done
```

Make it executable:

```bash
chmod +x check-runners.sh
```

Run whenever you need to check your runners:

```bash
./check-runners.sh
```

## Security Considerations

1. **Protect your `.env` files**:
   ```bash
   # Restrict access to env files
   chmod 600 .env runner-envs/*.env
   ```

2. **Consider using Docker secrets** for even more security in a Docker Swarm environment

3. **Regularly update your runners**:
   ```bash
   docker-compose pull
   docker-compose up -d
   ```

4. **Monitor runner processes and resource usage**

## Troubleshooting

1. **Runner won't register:**
   - Check if the token is valid (tokens expire after a short time)
   - Verify environment variables are set correctly
   - Check the runner logs: `docker-compose logs runner-1`

2. **Environment variable issues:**
   - Validate your env files: `cat runner-envs/runner-1.env`
   - Make sure there are no spaces around the equal sign in variable assignments
   - Check if the variables are properly referenced in docker-compose.yml

3. **Volume mounting issues:**
   - Ensure the mount paths exist
   - Check permissions on the host directories