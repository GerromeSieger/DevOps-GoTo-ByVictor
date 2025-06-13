# Install Google Cloud CLI (gcloud) on Linux, Windows or Mac

## Linux (CLI)

```bash
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-510.0.0-linux-x86_64.tar.gz

./google-cloud-sdk/install.sh
tar -xf google-cloud-cli-510.0.0-linux-x86_64.tar.gz

exec -l $SHELL

# authenticate with google cloud
gcloud auth login
gcloud auth application-default login
gcloud config set project <project-id>
gcloud projects get-iam-policy <project-id>
gcloud services enable compute.googleapis.com

```

## Windows (GUI)

Download and run the Google Cloud SDK installer:
https://dl.google.com/dl/cloudsdk/channels/rapid/GoogleCloudSDKInstaller.exe

## Mac (CLI)
Using Homebrew

```bash
brew install --cask google-cloud-sdk

# Download the Google Cloud SDK
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-438.0.0-darwin-x86_64.tar.gz

# Extract the archive
tar -xf google-cloud-cli-438.0.0-darwin-x86_64.tar.gz

# Run the install script
./google-cloud-sdk/install.sh

# Initialize gcloud
./google-cloud-sdk/bin/gcloud init
```