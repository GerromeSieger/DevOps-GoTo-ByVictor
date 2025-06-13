# Setting Up CircleCI Self-Hosted Runners with Docker Compose

This guide provides a streamlined approach to setting up CircleCI self-hosted runners using Docker Compose. This method allows you to easily deploy and manage multiple runners on a single host.

## Prerequisites

- Linux server with Docker and Docker Compose installed
- CircleCI account with a paid plan that supports self-hosted runners
- Organization admin access in CircleCI
- Runner authentication token from CircleCI

## Step 1: Create Resource Class in CircleCI

Before setting up the runners, you need to create a resource class in CircleCI:

1. Log in to your CircleCI account
2. Navigate to **Organization Settings**
3. Select **Self-Hosted Runners** from the menu
4. Click **Create Resource Class**
5. Enter a resource class name in the format `your-namespace/your-resource-class`
   - Note: The namespace must match your organization name
6. Click **Create**
7. After creation, click the vertical ellipsis (⋮) next to your resource class
8. Select **Get Authentication Token**
9. Copy the provided token for use in the next steps

## Step 2: Create Docker Compose Configuration

1. Create a directory for your CircleCI runners:

```bash
mkdir -p ~/circleci-runners
cd ~/circleci-runners
```

2. Create a `docker-compose.yml` file:

```bash
nano docker-compose.yml
```

3. Add the following configuration:

```yaml
services:
  runner-1:
    image: circleci/runner:latest
    container_name: circleci-runner-1
    restart: unless-stopped
    env_file:
      - .env    
    environment:
      - CIRCLECI_API_TOKEN=${CIRCLECI_API_TOKEN}
      - CIRCLECI_RESOURCE_CLASS=${CIRCLECI_RESOURCE_CLASS}
      - CIRCLECI_RUNNER_NAME=runner-1
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./runner-1-data:/home/circleci/.circleci-runner
    networks:
      - runner-network

  runner-2:
    image: circleci/runner:latest
    container_name: circleci-runner-2
    restart: unless-stopped
    env_file:
      - .env    
    environment:
      - CIRCLECI_API_TOKEN=${CIRCLECI_API_TOKEN}
      - CIRCLECI_RESOURCE_CLASS=${CIRCLECI_RESOURCE_CLASS}
      - CIRCLECI_RUNNER_NAME=runner-2
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./runner-2-data:/home/circleci/.circleci-runner
    networks:
      - runner-network

  runner-3:
    image: circleci/runner:latest
    container_name: circleci-runner-3
    restart: unless-stopped
    env_file:
      - .env    
    environment:
      - CIRCLECI_API_TOKEN=${CIRCLECI_API_TOKEN}
      - CIRCLECI_RESOURCE_CLASS=${CIRCLECI_RESOURCE_CLASS}
      - CIRCLECI_RUNNER_NAME=runner-3
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./runner-3-data:/home/circleci/.circleci-runner
    networks:
      - runner-network

networks:
  runner-network:
    driver: bridge
```

## Step 3: Create Environment File

Create a `.env` file to store your CircleCI token and resource class:

```bash
nano .env
```

Add the following contents:

```
CIRCLECI_API_TOKEN=your-authentication-token
CIRCLECI_RESOURCE_CLASS=your-namespace/your-resource-class
```

Replace `your-authentication-token` with the token you copied earlier, and `your-namespace/your-resource-class` with your actual resource class name.

## Step 4: Start the Runners

Launch your CircleCI runners:

```bash
docker-compose up -d
```

This command starts all three runners in detached mode.

## Step 5: Verify Runner Status

Check if your runners are running properly:

```bash
docker-compose ps
```

You should see all three containers running.

View the logs to check for successful registration:

```bash
docker-compose logs
```

Look for messages indicating successful connection to CircleCI.

You can also verify in the CircleCI UI:
1. Go to **Organization Settings > Self-Hosted Runners**
2. Your runners should appear under your resource class and show as "Connected"

## Step 6: Use Runners in CircleCI Workflows

To use your self-hosted runners in CircleCI workflows, update your `.circleci/config.yml`:

```yaml
version: 2.1

jobs:
  build:
    machine: true
    resource_class: your-namespace/your-resource-class
    steps:
      - checkout
      - run:
          name: "Build application"
          command: echo "Building on self-hosted runner"
      # Add your build steps here

workflows:
  main:
    jobs:
      - build
```

Replace `your-namespace/your-resource-class` with your actual resource class name.

## Step 7: Managing Your Runners

### Viewing logs

```bash
# View logs for all runners
docker-compose logs

# View logs for a specific runner
docker-compose logs runner-1
```

### Stopping runners

```bash
# Stop all runners
docker-compose down

# Stop a specific runner
docker-compose stop runner-1
```

### Restarting runners

```bash
# Restart all runners
docker-compose restart

# Restart a specific runner
docker-compose restart runner-1
```

### Updating runners

```bash
# Pull the latest runner image
docker-compose pull

# Restart with the new image
docker-compose down
docker-compose up -d
```

## Step 8: Creating a Custom Runner Image (Optional)

If you need specific tools or dependencies for your builds, create a custom Docker image:

1. Create a `Dockerfile`:

```bash
nano Dockerfile
```

2. Add your customizations:

```dockerfile
FROM circleci/runner:latest

USER root

# Install additional dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    nodejs \
    npm \
    awscli

# Any other customizations

# Switch back to circleci user
USER circleci
```

3. Build your custom image:

```bash
docker build -t custom-circleci-runner .
```

4. Update your `docker-compose.yml` to use the custom image:

```yaml
services:
  runner-1:
    image: custom-circleci-runner
    # Rest of the configuration remains the same
```

## Step 9: Setup Auto-Update Script (Optional)

Create an update script to keep your runners up to date:

```bash
nano update-runners.sh
```

Add the following content:

```bash
#!/bin/bash
cd ~/circleci-runners
docker-compose pull
docker-compose down
docker-compose up -d
echo "Runners updated at $(date)" >> update-log.txt
```

Make it executable:

```bash
chmod +x update-runners.sh
```

Set up a monthly cron job:

```bash
(crontab -l 2>/dev/null; echo "0 2 1 * * ~/circleci-runners/update-runners.sh") | crontab -
```

## Troubleshooting

### Runners not connecting

Check the logs for connection issues:

```bash
docker-compose logs | grep error
```

Verify your authentication token is correct in the `.env` file.

### Network issues

Ensure your server can reach CircleCI's services:

```bash
curl -v https://runner.circleci.com
```

### Resource class not found

Make sure the resource class in your `.env` file exactly matches what you created in CircleCI, including the namespace.

### Containers stopping unexpectedly

Check for resource constraints (memory, CPU) on your host machine:

```bash
docker stats
```

---

This setup provides a robust, easy-to-maintain configuration for CircleCI self-hosted runners using Docker Compose. The configuration can be extended to add more runners or customize them with different capabilities as needed.