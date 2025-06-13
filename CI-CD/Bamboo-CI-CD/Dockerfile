# Start from official Bamboo agent image
FROM atlassian/bamboo-agent-base:latest

USER root

# Install Docker prerequisites
RUN apt-get update && \
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release

# Add Docker's official GPG key
RUN mkdir -p /etc/apt/keyrings && \
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# Set up Docker repository
RUN echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Install Docker
RUN apt-get update && \
    apt-get install -y \
        docker-ce \
        docker-ce-cli \
        openssh-client \
        fish \
        ant \
        containerd.io \
        docker-compose-plugin

# Add bamboo user to docker group
RUN usermod -aG docker bamboo

# Verify Docker installation
RUN docker --version

# Switch back to bamboo user
USER bamboo