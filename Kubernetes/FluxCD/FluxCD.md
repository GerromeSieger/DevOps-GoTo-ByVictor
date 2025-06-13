# Setting up FluxCD for a Kubernetes Cluster

This guide provides step-by-step instructions for setting up FluxCD on a Kubernetes cluster.

## Prerequisites

- A running Kubernetes cluster
- kubectl configured to interact with your cluster
- Git repository to store your infrastructure configuration
- Personal access token for your Git provider (GitHub, GitLab, etc.)

## Installation Methods

### Option 1: Using Flux CLI (Recommended)

#### Steps

1. Install the Flux CLI:

**For macOS:**
```bash
brew install fluxcd/tap/flux
```

**For Linux:**
```bash
curl -s https://fluxcd.io/install.sh | sudo bash
```

**For Windows (using Chocolatey):**
```powershell
choco install flux
```

2. Verify the installation:

```bash
flux --version
```

3. Check if your Kubernetes cluster is ready for Flux:

```bash
flux check --pre
```

4. Bootstrap Flux on your cluster with GitHub:

For public repositories:
```bash
flux bootstrap github \
  --owner=YOUR-GITHUB-USERNAME \
  --repository=fleet-infra \
  --branch=main \
  --path=clusters/my-cluster \
  --personal
```

For private repositories:
```bash
flux bootstrap github \
  --owner=YOUR-GITHUB-USERNAME \
  --repository=fleet-infra \
  --branch=main \
  --path=clusters/my-cluster \
  --personal \
  --private=true \
  --token-auth
```

For other Git providers (GitLab, BitBucket, etc.), use the appropriate bootstrap command with similar private repository options.

5. Create a source for your application repository:

For public repositories:
```bash
flux create source git my-app \
  --url=https://github.com/YOUR-GITHUB-USERNAME/my-app \
  --branch=main \
  --interval=1m
```

For private repositories using SSH:
```bash
flux create secret git my-app-auth \
  --url=ssh://git@github.com/YOUR-GITHUB-USERNAME/my-app \
  --ssh-key-algorithm=rsa \
  --ssh-rsa-bits=4096

flux create source git my-app \
  --url=ssh://git@github.com/YOUR-GITHUB-USERNAME/my-app \
  --branch=main \
  --interval=1m \
  --secret-ref=my-app-auth
```

For private repositories using HTTPS:
```bash
flux create secret git my-app-auth \
  --url=https://github.com/YOUR-GITHUB-USERNAME/my-app \
  --username=git \
  --password=<your-token>

flux create source git my-app \
  --url=https://github.com/YOUR-GITHUB-USERNAME/my-app \
  --branch=main \
  --interval=1m \
  --secret-ref=my-app-auth
```

6. Create a Kustomization to deploy your application:

```bash
flux create kustomization my-app \
  --source=my-app \
  --path="./kustomize" \
  --prune=true \
  --interval=10m
```

7. Verify the Flux components are running:

```bash
kubectl get pods -n flux-system
```

8. Watch Flux sync your application:

```bash
flux get kustomizations --watch
```

## Setting up Monitoring (Optional)

1. Install Flux monitoring components:

```bash
flux create kustomization monitoring \
  --source=flux-system \
  --path="./monitoring/kube-prometheus-stack" \
  --prune=true \
  --interval=10m
```

2. Configure Flux notifications for Slack (optional):

```bash
flux create alert-provider slack \
  --type=slack \
  --channel=flux-alerts \
  --address=https://hooks.slack.com/services/YOUR/SLACK/WEBHOOK

flux create alert flux-system \
  --provider-ref=slack \
  --event-severity=info \
  --event-source=GitRepository/flux-system \
  --event-source=Kustomization/flux-system
```

## Common FluxCD Workflows

### 1. Updating an application

Simply commit changes to your Git repository, and Flux will automatically detect and apply them based on your configured sync interval.

### 2. Suspending automatic updates

```bash
flux suspend kustomization my-app
```

### 3. Resuming automatic updates

```bash
flux resume kustomization my-app
```

### 4. Triggering a manual sync

```bash
flux reconcile kustomization my-app --with-source
```

### 5. Debugging issues

```bash
flux logs --follow
```

## Key Concepts

- **Sources**: Define where Flux should sync from (Git repositories, Helm repositories, S3 buckets)
- **Kustomizations**: Define which paths in the sources should be deployed to the cluster
- **Receivers**: Handle webhook events from Git providers
- **Alerts**: Notify external systems about reconciliation events

## Best Practices

1. Structure your Git repository with a clear separation of environments
2. Use Kustomize bases and overlays for different environments
3. Seal sensitive data using sealed-secrets or external-secrets
4. Set appropriate sync intervals for different resources
5. Enable drift detection with `--prune=true`
6. Implement progressive delivery with Flagger (a Flux component)

### Option 2: Using Kubernetes Manifests

If you prefer to install Flux using manifest files (similar to ArgoCD's approach), follow these steps:

1. Create the flux-system namespace:

```bash
kubectl create namespace flux-system
```

2. Apply the Flux manifests:

```bash
kubectl apply -f https://github.com/fluxcd/flux2/releases/latest/download/install.yaml
```

3. Verify the installation:

```bash
kubectl get pods -n flux-system
```

4. Configure Git repository access:

For HTTPS with personal access token:
```bash
kubectl create secret generic git-credentials \
  --namespace=flux-system \
  --from-literal=username=git \
  --from-literal=password=<your-token>

cat <<EOF | kubectl apply -f -
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: my-repository
  namespace: flux-system
spec:
  interval: 1m
  url: https://github.com/YOUR-GITHUB-USERNAME/my-app
  secretRef:
    name: git-credentials
EOF
```

For SSH authentication:
```bash
kubectl create secret generic ssh-credentials \
  --namespace=flux-system \
  --from-file=identity=/path/to/private-key \
  --from-file=known_hosts=/path/to/known_hosts

cat <<EOF | kubectl apply -f -
apiVersion: source.toolkit.fluxcd.io/v1beta2
kind: GitRepository
metadata:
  name: my-repository
  namespace: flux-system
spec:
  interval: 1m
  url: ssh://git@github.com/YOUR-GITHUB-USERNAME/my-app
  secretRef:
    name: ssh-credentials
EOF
```

5. Configure Kustomization using manifests:

```bash
cat <<EOF | kubectl apply -f -
apiVersion: kustomize.toolkit.fluxcd.io/v1beta2
kind: Kustomization
metadata:
  name: my-app
  namespace: flux-system
spec:
  interval: 10m
  path: "./kustomize"
  prune: true
  sourceRef:
    kind: GitRepository
    name: my-repository
EOF
```

## Troubleshooting

If you encounter issues, check:

1. Flux system logs:
```bash
kubectl logs -n flux-system deploy/source-controller
kubectl logs -n flux-system deploy/kustomize-controller
```

2. Events related to your resources:
```bash
kubectl describe kustomization my-app -n flux-system
```

3. Ensure Git credentials are correctly configured:
   - For SSH keys, verify the key format and permissions
   - For HTTPS tokens, ensure the token has the necessary repository access permissions
   - Check that secrets are correctly referenced in your GitRepository resources

4. Verify your Git repository structure matches your Kustomization paths