# Setting up Ingress with Nginx Ingress Controller in Kubernetes

This guide explains how to set up an Ingress controller using NGINX in Kubernetes.

## Steps to Set Up Ingress with NGINX

1. Install the NGINX Ingress Controller:

Using Helm:
```bash
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm install ingress-nginx ingress-nginx/ingress-nginx
```

Using kubectl:

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

2. Verify the installation:

```bash
kubectl get pods -n ingress-nginx
```

3. Create an Ingress resource

4. Apply Ingress Resource:

```bash
kubectl apply -f ingress.yml
```

5. Verify the Ingress:

```bash
kubectl get ingress 
```



