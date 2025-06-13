# Kubernetes Dashboard Access Guide

This document provides steps to verify if the Kubernetes Dashboard is installed and how to access it.

## Table of Contents
1. [Check if Dashboard Exists](#1-check-if-dashboard-exists)
2. [Access Methods](#2-access-methods)
   - [Method A: kubectl proxy](#method-a-kubectl-proxy-recommended)
   - [Method B: Port Forwarding](#method-b-port-forwarding)
   - [Method C: NodePort/LoadBalancer](#method-c-nodeportloadbalancer)
3. [Authentication](#3-authentication)
4. [Troubleshooting](#4-troubleshooting)
5. [Installation](#5-installation-if-not-present)

---

## 1. Check if Dashboard Exists

Run these commands to verify installation:

```bash
# Check deployment
kubectl get deployments -n kubernetes-dashboard

# Check service
kubectl get svc -n kubernetes-dashboard

# Check pod status
kubectl get pods -n kubernetes-dashboard
```

✅ **Expected Output**: Look for `kubernetes-dashboard` in deployment and service lists. Pod should be in `Running` state.

## 2. Access Methods

### Method A: kubectl proxy (Recommended)

```bash
kubectl proxy
```

Access URL: `http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/`

### Method B: Port Forwarding

```bash
kubectl port-forward -n kubernetes-dashboard service/kubernetes-dashboard 8443:443
```

Access URL: `https://localhost:8443`

### Method C: NodePort/LoadBalancer

```bash
kubectl get svc -n kubernetes-dashboard
```

Access via:
* NodePort: `https://<Node-IP>:<NodePort>`
* LoadBalancer: Use `EXTERNAL-IP` from output

## 3. Authentication

Get Access Token:

```bash
# For admin-user (if exists)
kubectl -n kubernetes-dashboard create token admin-user

# For any service account
kubectl -n kubernetes-dashboard get serviceaccounts
kubectl -n kubernetes-dashboard create token <service-account-name>
```

## 4. Troubleshooting

| **Issue** | **Solution** |
|-----------|--------------|
| "No endpoints available" | Check pod logs: `kubectl logs -n kubernetes-dashboard <pod-name>` |
| Token not working | Verify RBAC: `kubectl get clusterrolebindings -A \| grep dashboard` |
| SSL warnings | Chrome: Type `thisisunsafe`<br>Firefox: Accept risk |

## 5. Installation (If Not Present)

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create admin user
cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: ServiceAccount
metadata:
  name: admin-user
  namespace: kubernetes-dashboard
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: admin-user
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: cluster-admin
subjects:
- kind: ServiceAccount
  name: admin-user
  namespace: kubernetes-dashboard
EOF
```

**Note**: For production environments, always secure your dashboard with proper network policies and authentication.