# Start from official Bamboo agent image
FROM atlassian/bamboo-agent-base:latest

USER root

# Install required dependencies
RUN apt-get update && \
    apt-get install -y \
        apt-transport-https \
        ca-certificates \
        curl \
        gnupg \
        lsb-release \
        git \
        openssh-client \
        fish \
        build-essential

# Install Node.js (using NodeSource's official setup)
# This installs the latest LTS version of Node.js (currently v20.x)
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

# Install Yarn package manager
RUN npm install -g yarn

# Install some common global Node.js packages
RUN npm install -g \
    npm@latest \
    pnpm \
    typescript \
    ts-node \
    eslint \
    jest

# Verify Node.js installation
RUN node --version && \
    npm --version && \
    yarn --version && \
    pnpm --version

# Create a directory for global npm modules and fix permissions
RUN mkdir -p /home/bamboo/.npm-global && \
    chown -R bamboo:bamboo /home/bamboo/.npm-global

# Set up environment variables for the bamboo user
RUN echo 'export PATH=/home/bamboo/.npm-global/bin:$PATH' >> /home/bamboo/.bashrc && \
    echo 'export NPM_CONFIG_PREFIX=/home/bamboo/.npm-global' >> /home/bamboo/.bashrc

# Switch back to bamboo user
USER bamboo

# Update npm config for the bamboo user
RUN npm config set prefix '/home/bamboo/.npm-global'

# Print versions for verification
RUN echo "Node.js setup complete" && \
    node -v && \
    npm -v