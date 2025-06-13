# Setting Up Self-Hosted Runners for GitHub Actions

This guide provides step-by-step instructions for setting up self-hosted runners for GitHub Actions on a Linux machine. Self-hosted runners allow you to run GitHub Actions workflows on your own infrastructure.

## Prerequisites

- Linux server with sufficient resources (recommended minimum: 2 CPU cores, 4GB RAM)
- Docker (optional, for containerized runners)
- Network access to GitHub.com
- GitHub account with admin access to your repository or organization
- Sudo/root access on your server

## Installation Steps

### 1. Prepare Your Server

First, ensure your server has all necessary dependencies:

```bash
sudo apt-get update
sudo apt-get upgrade -y
sudo apt-get install -y curl jq build-essential libssl-dev libffi-dev python3 python3-venv python3-dev
```

### 2. Create a Dedicated User Account (Recommended for Security)

```bash
sudo useradd -m actions-runner
sudo passwd actions-runner
sudo usermod -aG sudo actions-runner
su - actions-runner
```

### 3. Register a Runner at Repository Level

These steps will register a runner for a specific repository:

```bash
mkdir ~/actions-runner && cd ~/actions-runner
curl -o actions-runner-linux-x64-2.308.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.308.0/actions-runner-linux-x64-2.308.0.tar.gz

# Optional: Validate the hash
echo "08456ad5f3d2bf4beeab290db83bdbb386b98de0bd4e8807a641ba17a7aeb365  actions-runner-linux-x64-2.308.0.tar.gz" | shasum -a 256 -c

tar xzf ./actions-runner-linux-x64-2.308.0.tar.gz
```

Now, get your repository's runner registration token:

1. Navigate to your GitHub repository
2. Go to **Settings > Actions > Runners > New self-hosted runner**
3. Copy the provided token

Then, register the runner:

```bash
# Configure the runner
./config.sh --url https://github.com/YOUR-USERNAME/YOUR-REPO --token YOUR_TOKEN

# Follow the interactive prompts to configure your runner:
# - Runner name: Provide a descriptive name or accept the default
# - Runner group: Usually 'Default'
# - Work folder: Directory where jobs will run or accept the default
# - Additional labels (optional): Add custom labels to target this runner

# Install and start the runner as a service
sudo ./svc.sh install
sudo ./svc.sh start
```

### 4. Register a Runner at Organization Level (Alternative)

To register a runner for an entire organization:

1. Navigate to your GitHub organization
2. Go to **Settings > Actions > Runners > New self-hosted runner**
3. Copy the provided token
4. Follow the same steps as above, but use:

```bash
./config.sh --url https://github.com/YOUR-ORGANIZATION --token YOUR_ORG_TOKEN
```

### 5. Verify the Runner Installation

1. Check that the runner is online:
   - Go to the repository or organization settings
   - Navigate to **Actions > Runners**
   - Your runner should be listed as "Idle"

2. Check the runner service status:

```bash
sudo ./svc.sh status
```

### 6. Configure Runner Groups (Organization-Level Only)

For organization runners, you can create runner groups to control access:

1. Go to **Organization Settings > Actions > Runner groups > New runner group**
2. Name your group and select which repositories can access it
3. Move runners between groups as needed

### 7. Using Self-Hosted Runners in Workflows

To use your self-hosted runner in a GitHub Actions workflow:

```yaml
name: CI on Self-Hosted Runner

on: [push, pull_request]

jobs:
  build:
    runs-on: self-hosted  # Specify to use self-hosted runners
    # If you added custom labels, you can target specific runners:
    # runs-on: [self-hosted, linux, x64, your-label]
    
    steps:
      - uses: actions/checkout@v3
      - name: Run a simple command
        run: echo "Running on a self-hosted runner!"
      # Add your build steps here
```

### 8. Setting Up Containerized Runners (Optional)

For better isolation, you can run your runners in Docker containers:

```bash
# Create a directory for the runner data
mkdir -p ~/actions-runner-docker/runner-data

# Pull the GitHub Actions Runner Docker image
docker pull myoung34/github-runner:latest

# Start the runner container
docker run -d --restart always --name github-runner \
  -e REPO_URL="https://github.com/YOUR-USERNAME/YOUR-REPO" \
  -e RUNNER_TOKEN="YOUR_TOKEN" \
  -e RUNNER_NAME="docker-runner" \
  -e RUNNER_WORKDIR="/tmp/github-runner-your-repo" \
  -e LABELS="linux,x64,docker" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/actions-runner-docker/runner-data:/tmp/github-runner-your-repo \
  myoung34/github-runner:latest
```

For organization level:

```bash
docker run -d --restart always --name github-org-runner \
  -e ORG_NAME="YOUR-ORGANIZATION" \
  -e RUNNER_TOKEN="YOUR_ORG_TOKEN" \
  -e RUNNER_NAME="docker-org-runner" \
  -e RUNNER_WORKDIR="/tmp/github-runner-your-org" \
  -e LABELS="linux,x64,docker" \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v ~/actions-runner-docker/runner-data:/tmp/github-runner-your-org \
  myoung34/github-runner:latest
```

### 9. Auto-Scaling with Runner Groups (Advanced)

For dynamic environments, consider setting up auto-scaling:

1. Create a script to monitor job queue and scale runners:

```bash
#!/bin/bash
# Example of a simple auto-scaling script
# This would need additional logic for real-world use

MAX_RUNNERS=5
CURRENT_RUNNERS=$(curl -s -H "Authorization: token YOUR_GITHUB_PAT" \
  https://api.github.com/repos/YOUR-USERNAME/YOUR-REPO/actions/runners | jq '.total_count')

if [ "$CURRENT_RUNNERS" -lt "$MAX_RUNNERS" ]; then
  # Logic to start a new runner
  echo "Starting new runner..."
fi
```

2. Set this up with a cron job or Kubernetes-based solution for more sophisticated scaling

### 10. Maintenance and Updates

Keep your self-hosted runner up-to-date:

```bash
# Stop the runner service
sudo ./svc.sh stop

# Update the runner
cd ~/actions-runner
rm -rf *.tar.gz
curl -o actions-runner-linux-x64-[version].tar.gz -L https://github.com/actions/runner/releases/download/v[version]/actions-runner-linux-x64-[version].tar.gz
tar xzf ./actions-runner-linux-x64-[version].tar.gz

# Start the runner service
sudo ./svc.sh start
```

For Docker-based runners, simply pull the latest image and restart the container.

### 11. Monitoring and Troubleshooting

1. View runner logs:

```bash
# For service-based runners
cd ~/actions-runner
tail -f ./_diag/SVC_*.log

# For Docker-based runners
docker logs -f github-runner
```

2. Common troubleshooting steps:

```bash
# Restart a runner
sudo ./svc.sh restart

# Unregister a runner that's no longer needed
./config.sh remove --token YOUR_REMOVAL_TOKEN

# Check runner connectivity
cd ~/actions-runner
./run.sh --check
```

## Security Considerations

1. **Runner isolation**: Consider using containerized runners to provide job isolation
2. **Network security**: Restrict outbound network access from runner machines as appropriate
3. **Repository access**: Be aware that workflows running on self-hosted runners can access your network resources
4. **Regular updates**: Keep runners updated to receive security patches
5. **Secrets management**: Be cautious with secrets on self-hosted runners; use GitHub's encrypted secrets feature

## Additional Resources

- [GitHub Actions self-hosted runners documentation](https://docs.github.com/en/actions/hosting-your-own-runners)
- [Runner security with self-hosted runners](https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions#hardening-for-self-hosted-runners)
- [Auto-scaling self-hosted runners](https://docs.github.com/en/actions/hosting-your-own-runners/autoscaling-with-self-hosted-runners)