# Istio Canary Deployment Guide

This guide walks through setting up canary deployments and traffic splitting in Istio using your existing Next.js application as an example.

## Prerequisites

- Kubernetes cluster with Istio installed
- `kubectl` configured for your cluster
- Existing application deployment (already provided in your manifest)

## 1. Understanding Canary Deployments

Canary deployments allow you to release a new version of your application to a subset of users before rolling it out to everyone. This helps detect potential issues before they affect all users.

In Istio, canary deployments are implemented using:
- Multiple Kubernetes deployments (stable and canary versions)
- Kubernetes services to expose the deployments
- Istio virtual services to manage traffic routing
- Istio destination rules to define subsets

## 2. Prepare Your Environment

Ensure the namespace has Istio injection enabled:

```bash
kubectl label namespace default istio-injection=enabled
```

## 3. Deploy the Stable Version (Current Version)

Your current deployment will serve as the "stable" version. Let's modify it slightly to include a version label:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: next-deployment-v1
  namespace: default
  labels:
    app: next
    tier: frontend
    version: v1
spec:
  replicas: 4
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: next
      tier: frontend
      version: v1
  template:
    metadata:
      labels:
        app: next
        tier: frontend
        version: v1
      annotations:
        prometheus.io/scrape: "true"
    spec:
      containers:
      - name: nextapp
        image: gerrome/next-site:v1  # Specify a tag for clarity
        # Rest of the container spec remains the same as your original
```

Apply this modified deployment:

```bash
kubectl apply -f next-deployment-v1.yaml
```

## 4. Create the Canary Deployment (New Version)

Create a new deployment for the canary version:

```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: next-deployment-v2
  namespace: default
  labels:
    app: next
    tier: frontend
    version: v2
spec:
  replicas: 1  # Start with fewer replicas for the canary
  revisionHistoryLimit: 3
  selector:
    matchLabels:
      app: next
      tier: frontend
      version: v2
  template:
    metadata:
      labels:
        app: next
        tier: frontend
        version: v2
      annotations:
        prometheus.io/scrape: "true"
    spec:
      containers:
      - name: nextapp
        image: gerrome/next-site:v2  # New version of your application
        imagePullPolicy: IfNotPresent
        ports:
        - containerPort: 3000
          name: http
        resources:
          requests:
            cpu: "100m"
            memory: "128Mi"
          limits:
            cpu: "500m"
            memory: "512Mi"
        livenessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /
            port: 3000
          initialDelaySeconds: 5
          periodSeconds: 5
        env:
        - name: NODE_ENV
          value: "production"
        - name: VERSION
          value: "v2"  # Add an environment variable to identify the version
      terminationGracePeriodSeconds: 30
      affinity:
        podAntiAffinity:
          preferredDuringSchedulingIgnoredDuringExecution:
          - weight: 100
            podAffinityTerm:
              labelSelector:
                matchExpressions:
                - key: app
                  operator: In
                  values:
                  - next
              topologyKey: "kubernetes.io/hostname"
```

Apply the canary deployment:

```bash
kubectl apply -f next-deployment-v2.yaml
```

## 5. Update the Service to Include Both Versions

Your original service doesn't need to change much, but ensure it selects both versions:

```yaml
apiVersion: v1
kind: Service
metadata:
  name: next-service
  namespace: default
  labels:
    app: next
    tier: frontend
spec:
  type: ClusterIP
  selector:
    app: next
    tier: frontend
  # Note: We've removed version from the selector to include all versions
  ports:
    - name: http
      protocol: TCP
      port: 80
      targetPort: 3000
```

Apply this service:

```bash
kubectl apply -f next-service.yaml
```

## 6. Create Istio Gateway

Create an Istio Gateway to expose your application externally:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: Gateway
metadata:
  name: next-gateway
  namespace: default
spec:
  selector:
    istio: ingressgateway # Use the default istio gateway
  servers:
  - port:
      number: 80
      name: http
      protocol: HTTP
    hosts:
    - "*"  # Or your specific domain
```

Apply the gateway:

```bash
kubectl apply -f next-gateway.yaml
```

## 7. Create Destination Rule for Subsets

Define subsets for your application versions:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: DestinationRule
metadata:
  name: next-destination-rule
  namespace: default
spec:
  host: next-service
  subsets:
  - name: v1
    labels:
      version: v1
  - name: v2
    labels:
      version: v2
```

Apply the destination rule:

```bash
kubectl apply -f next-destination-rule.yaml
```

## 8. Create Virtual Service for Traffic Splitting

Now create a virtual service to split traffic between stable (v1) and canary (v2) versions:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: next-virtual-service
  namespace: default
spec:
  hosts:
  - "*"
  gateways:
  - next-gateway
  http:
  - route:
    - destination:
        host: next-service
        subset: v1
        port:
          number: 80
      weight: 90
    - destination:
        host: next-service
        subset: v2
        port:
          number: 80
      weight: 10  # Start with 10% traffic to canary
```

Apply the virtual service:

```bash
kubectl apply -f next-virtual-service.yaml
```

## 9. Gradual Traffic Migration

As you gain confidence in your canary version, you can gradually increase traffic to v2:

### 20% to Canary
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: next-virtual-service
  namespace: default
spec:
  hosts:
  - "*"
  gateways:
  - next-gateway
  http:
  - route:
    - destination:
        host: next-service
        subset: v1
        port:
          number: 80
      weight: 80
    - destination:
        host: next-service
        subset: v2
        port:
          number: 80
      weight: 20
```

### 50% to Canary
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: next-virtual-service
  namespace: default
spec:
  hosts:
  - "*"
  gateways:
  - next-gateway
  http:
  - route:
    - destination:
        host: next-service
        subset: v1
        port:
          number: 80
      weight: 50
    - destination:
        host: next-service
        subset: v2
        port:
          number: 80
      weight: 50
```

### 100% to Canary (Complete Migration)
```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: next-virtual-service
  namespace: default
spec:
  hosts:
  - "*"
  gateways:
  - next-gateway
  http:
  - route:
    - destination:
        host: next-service
        subset: v2
        port:
          number: 80
      weight: 100
```

## 10. Advanced Traffic Splitting Techniques

### Route Based on Headers (A/B Testing)

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: next-virtual-service
  namespace: default
spec:
  hosts:
  - "*"
  gateways:
  - next-gateway
  http:
  - match:
    - headers:
        user-agent:
          regex: ".*Chrome.*"  # Chrome users get v2
    route:
    - destination:
        host: next-service
        subset: v2
        port:
          number: 80
  - route:  # All other users get v1
    - destination:
        host: next-service
        subset: v1
        port:
          number: 80
```

### Route Based on Cookies/User ID

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: next-virtual-service
  namespace: default
spec:
  hosts:
  - "*"
  gateways:
  - next-gateway
  http:
  - match:
    - headers:
        cookie:
          regex: ".*user=test.*"  # Test users get v2
    route:
    - destination:
        host: next-service
        subset: v2
        port:
          number: 80
  - route:  # Regular users get v1
    - destination:
        host: next-service
        subset: v1
        port:
          number: 80
```

## 11. Monitoring Your Canary Deployment

Monitor your canary deployment with Istio's built-in tools:

### Using Kiali
```bash
istioctl dashboard kiali
```

### Using Prometheus for Metrics
```bash
istioctl dashboard prometheus
```

Add queries to compare error rates, response times, and other metrics between v1 and v2.

### Using Grafana for Visualization
```bash
istioctl dashboard grafana
```

## 12. Rollback Strategy

If issues are detected with the canary version, you can quickly roll back to the stable version:

```yaml
apiVersion: networking.istio.io/v1alpha3
kind: VirtualService
metadata:
  name: next-virtual-service
  namespace: default
spec:
  hosts:
  - "*"
  gateways:
  - next-gateway
  http:
  - route:
    - destination:
        host: next-service
        subset: v1
        port:
          number: 80
      weight: 100
```

## 13. Complete Canary Promotion

Once the canary is proven stable, you can:

1. Update the virtual service to route 100% traffic to v2
2. Scale up the v2 deployment to handle all traffic
3. Scale down and eventually remove the v1 deployment

## 14. Automation with Flagger (Optional)

For automated canary analysis and promotion, consider using Flagger:

```bash
# Install Flagger
kubectl apply -k github.com/fluxcd/flagger/kustomize/istio
```

Example Flagger Canary custom resource:

```yaml
apiVersion: flagger.app/v1beta1
kind: Canary
metadata:
  name: next-canary
  namespace: default
spec:
  targetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: next-deployment
  service:
    port: 80
    targetPort: 3000
  analysis:
    interval: 30s
    threshold: 5
    maxWeight: 50
    stepWeight: 10
    metrics:
    - name: request-success-rate
      threshold: 99
      interval: 1m
    - name: request-duration
      threshold: 500
      interval: 1m
```

## Additional Resources

- [Istio Traffic Management Documentation](https://istio.io/latest/docs/concepts/traffic-management/)
- [Istio Virtual Service API Reference](https://istio.io/latest/docs/reference/config/networking/virtual-service/)
- [Flagger Documentation](https://docs.flagger.app/)

## Tips for Successful Canary Deployments

1. **Start small**: Begin with a small percentage (5-10%) of traffic to the canary
2. **Monitor carefully**: Watch error rates, latency, and resource usage
3. **Automate rollbacks**: Set up automatic rollbacks based on error thresholds
4. **Test thoroughly**: Ensure both versions can run side by side without issues
5. **Consistent deployment artifacts**: Use the same base image or build process
6. **Feature flags**: Consider using feature flags as an additional safety mechanism