# Installing an SSL Certificate with Cert-Manager and Ingress on Kubernetes

This guide provides steps to install Cert-Manager and set up SSL certificates for your Kubernetes Ingress resources.

## Prerequisites

- A Kubernetes cluster
- kubectl configured to interact with your cluster
- Helm (optional, but recommended)

## Steps

1. Install Cert-Manager:

Using kubectl:

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.11.0/cert-manager.yaml
```

Using Helm:
   
```bash
helm repo add jetstack https://charts.jetstack.io
helm repo update
kubectl create namespace cert-manager
helm install cert-manager jetstack/cert-manager --namespace cert-manager --version v1.11.0 --set installCRDs=true
```

2. Verify the installation:

```bash
kubectl get pods -n cert-manager
```

3. Create a ClusterIssuer for Let's Encrypt:

Create a file named letsencrypt-cluster-issuer.yml

Apply the ClusterIssuer:

```bash
kubectl apply -f letsencrypt-cluster-issuer.yml
```

4. Update your Ingress resource to use the SSL certificate:

Apply the Ingress:

```bash
kubectl apply -f ingress-ssl.yml
```

5. Verify the certificate:

```bash
kubectl get certificate
```

The certificate should be in a "Ready" state after a few minutes.