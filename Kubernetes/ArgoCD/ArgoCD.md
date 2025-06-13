# Setting up ArgoCD for a Kubernetes Cluster

This guide provides step-by-step instructions for setting up ArgoCD on a Kubernetes cluster.

## Prerequisites

- A running Kubernetes cluster
- kubectl configured to interact with your cluster
- Helm (optional, but recommended)

## Steps

1. Create a namespace for ArgoCD:

```bash
kubectl create namespace argocd
```

2. Install ArgoCD using either kubectl or Helm:
Using kubectl:

```bash
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

Using Helm:

```bash
helm repo add argo https://argoproj.github.io/argo-helm
helm install argocd argo/argo-cd -n argocd
```

3. Wait for ArgoCD pods to be ready:

```bash
kubectl wait --for=condition=Ready pods --all -n argocd --timeout=300s
```

4. Access the ArgoCD UI:

a. For kubectl installations, get the initial admin password

```bash
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d
```

b. Port-forward the ArgoCD server:

```bash
kubectl port-forward svc/argocd-server -n argocd 8080:443
```

c. Access the UI at https://localhost:8080

5. (Optional) Install the ArgoCD CLI:

```bash
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64
sudo install -m 555 argocd-linux-amd64 /usr/local/bin/argocd
rm argocd-linux-amd64
```

6. Log in using the CLI:

```bash
argocd login localhost:8080
```

7. Change the admin password:

```bash
argocd account update-password
```

8. Start using ArgoCD to manage your applications!