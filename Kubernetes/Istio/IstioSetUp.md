# Istio Setup Guide for Kubernetes

This guide walks through the process of installing and configuring Istio on a Kubernetes cluster.

## Prerequisites

- A running Kubernetes cluster (v1.21+)
- `kubectl` command-line tool configured to communicate with your cluster
- Admin access to the Kubernetes cluster
- Minimum resources available:
  - 4 vCPUs
  - 8 GB memory
  - 2 GB storage

## 1. Download and Install Istio

First, download the latest Istio release:

```bash
curl -L https://istio.io/downloadIstio | sh -
```

Navigate to the Istio package directory:

```bash
cd istio-1.19.0  # Version number may differ
```

Add the `istioctl` client to your path:

```bash
cp bin/istioctl /bin
```

## 2. Install Istio

You can install Istio using one of the provided profiles or a custom configuration.

### Option 1: Install using default profile

```bash
istioctl install --set profile=default -y
```

### Option 2: Install using demo profile (includes more features)

```bash
istioctl install --set profile=demo --set components.cni.enabled=false -y
```

### Option 3: Install using a custom configuration file

```bash
istioctl install -f custom-config.yaml -y
```

## 3. Label Namespaces for Istio Injection

For Istio to work, you need to enable automatic sidecar injection in the namespaces where you want Istio to manage traffic:

```bash
kubectl label namespace default istio-injection=enabled
```

You can also create a dedicated namespace for your applications:

```bash
kubectl create namespace my-app
kubectl label namespace my-app istio-injection=enabled
```

## 4. Verify the Installation

Check if all Istio components are deployed and running:

```bash
kubectl get pods -n istio-system
```

Verify Istio CRDs:

```bash
kubectl get crds | grep 'istio.io\|cert-manager.io' | wc -l
```

You should see approximately 25-30 CRDs.

## 5. Install Addons (Optional)

### Install Kiali Dashboard

```bash
kubectl apply -f samples/addons/kiali.yaml
```

### Install Prometheus for Metrics

```bash
kubectl apply -f samples/addons/prometheus.yaml
```

### Install Grafana for Visualization

```bash
kubectl apply -f samples/addons/grafana.yaml
```

### Install Jaeger for Tracing

```bash
kubectl apply -f samples/addons/jaeger.yaml
```

## 6. Access the Dashboards

### Kiali Dashboard

```bash
istioctl dashboard kiali
```

Or:

```bash
kubectl port-forward svc/kiali -n istio-system 20001:20001
```

Then access: http://localhost:20001

### Grafana Dashboard

```bash
kubectl port-forward svc/grafana -n istio-system 3000:3000
```

Then access: http://localhost:3000

### Jaeger Dashboard

```bash
kubectl port-forward svc/tracing -n istio-system 8080:80
```

Then access: http://localhost:16686

## 7. Deploy a Sample Application

Deploy the Bookinfo sample application to test Istio:

```bash
kubectl apply -f samples/bookinfo/platform/kube/bookinfo.yaml
```

Verify that the application is running:

```bash
kubectl get services
kubectl get pods
```

Create an Istio gateway for the application:

```bash
kubectl apply -f samples/bookinfo/networking/bookinfo-gateway.yaml
```

## 8. Determine the Ingress IP and Port

```bash
export INGRESS_HOST=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
export INGRESS_PORT=$(kubectl -n istio-system get service istio-ingressgateway -o jsonpath='{.spec.ports[?(@.name=="http2")].port}')
export GATEWAY_URL=$INGRESS_HOST:$INGRESS_PORT
```

Access the application:

```bash
echo "http://$GATEWAY_URL/productpage"
```

## 9. Traffic Management Examples

### Apply Default Destination Rules

```bash
kubectl apply -f samples/bookinfo/networking/destination-rule-all.yaml
```

### Route All Traffic to v1 of All Services

```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-all-v1.yaml
```

### Route to v2 of Reviews Service for a Specific User

```bash
kubectl apply -f samples/bookinfo/networking/virtual-service-reviews-test-v2.yaml
```

## 10. Security Configuration Examples

### Enable mTLS Strict Mode Cluster-Wide

```bash
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: PeerAuthentication
metadata:
  name: default
  namespace: istio-system
spec:
  mtls:
    mode: STRICT
EOF
```

### Create JWT Authentication Policy

```bash
kubectl apply -f - <<EOF
apiVersion: security.istio.io/v1beta1
kind: RequestAuthentication
metadata:
  name: jwt-example
  namespace: istio-system
spec:
  jwtRules:
  - issuer: "testing@secure.istio.io"
    jwksUri: "https://raw.githubusercontent.com/istio/istio/release-1.19/security/tools/jwt/samples/jwks.json"
EOF
```

## 11. Uninstalling Istio

To uninstall Istio from your Kubernetes cluster:

```bash
istioctl uninstall --purge -y
```

Remove the namespace:

```bash
kubectl delete namespace istio-system
```

## Troubleshooting

### Check Proxy Status

```bash
istioctl proxy-status
```

### Debug Envoy Configuration

```bash
istioctl proxy-config all <pod-name>.<namespace>
```

### View Istio Logs

```bash
kubectl logs -n istio-system -l app=istiod -c discovery
```

### Check Mesh Configuration

```bash
istioctl analyze
```

## Further Resources

- [Istio Documentation](https://istio.io/latest/docs/)
- [Istio GitHub Repository](https://github.com/istio/istio)
- [Istio Community](https://istio.io/latest/about/community/join/)