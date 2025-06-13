# Setting Up a Self-Managed Kubernetes Cluster on Ubuntu 22.04

This guide walks you through setting up a self-managed Kubernetes cluster on Ubuntu 22.04, including connecting a worker node to the cluster.

## Prerequisites

- Two or more Ubuntu 22.04 servers (one for control plane, others for worker nodes)
- Root or sudo access on all servers
- Minimum 2 CPU cores and 2GB RAM per machine
- Full network connectivity between all machines
- Unique hostname, MAC address, and product_uuid for each machine
- Certain ports opened (detailed below)
- Swap disabled on all nodes

## Step 1: Prepare All Nodes (Control Plane and Workers)

Run these commands on **all nodes**:

```bash
# Update the system
sudo apt update
sudo apt upgrade -y

# Install required packages
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common

# Add Kubernetes apt repository (updated method)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# Create the repository file (first ensure directory exists)
sudo mkdir -p /etc/apt/keyrings
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update apt with the new repository
sudo apt update

# Install containerd using the official method
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the Docker repository
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package list again
sudo apt update

# Install containerd
sudo apt install -y containerd.io

# Create containerd configuration directory
sudo mkdir -p /etc/containerd

# Generate default configuration
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Edit configuration to enable SystemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Configure kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Install kubelet, kubeadm, and kubectl
sudo apt install -y kubelet kubeadm kubectl

# Pin their versions to avoid unexpected upgrades
sudo apt-mark hold kubelet kubeadm kubectl
```

## Step 2: Initialize the Control Plane Node

Run these commands **only on the control plane node**:

```bash
# Initialize the Control Plane Node

Run these commands **only on the control plane node**:

```bash
# First, identify your server's network interfaces and IP addresses
ip addr show

# Get the IP address of your primary network interface (usually eth0 or ens4)
# Replace eth0 with your actual interface name if different
SERVER_IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')
echo "Using IP: $SERVER_IP"

# Initialize the cluster with the specific IP address
sudo kubeadm init --apiserver-advertise-address=$SERVER_IP --pod-network-cidr=10.244.0.0/16

# If the above fails, try with verbose logging for troubleshooting
# sudo kubeadm init --apiserver-advertise-address=$SERVER_IP --pod-network-cidr=10.244.0.0/16 --v=5
```

If initialization fails, you can reset and try again:

```bash
# Complete reset of Kubernetes components
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/
sudo rm -rf ~/.kube/
sudo rm -rf /var/lib/etcd

# Clean up iptables rules
sudo iptables -F
sudo iptables -t nat -F
sudo iptables -t mangle -F
sudo iptables -X

# Restart containerd
sudo systemctl restart containerd

# Then try initializing again with the commands above
```

# Set up kubeconfig for the root user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Set up kubeconfig for a regular user (if needed)
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Verify that you can access the cluster
kubectl get nodes

# Deploy a pod network (using Calico in this example)
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Wait for the pods to start
kubectl get pods -n kube-system -w

# Check the status of the control plane pods
kubectl get pods -n kube-system

# Verify that your node is now Ready
kubectl get nodes
```

Make note of the `kubeadm join` command that is output after the initialization. It will look something like this:

```
kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

You'll need this command to join worker nodes to the cluster.

## Step 3: Prepare Worker Nodes

After setting up the control plane, you'll need to prepare each worker node:

```bash
# Update the system
sudo apt update
sudo apt upgrade -y

# Install required packages
sudo apt install -y apt-transport-https ca-certificates curl software-properties-common net-tools

# Add Kubernetes apt repository (updated method)
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.29/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
# Create the repository file (first ensure directory exists)
sudo mkdir -p /etc/apt/keyrings
echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.29/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# Update package list
sudo apt update

# Install containerd using the official method
sudo apt install -y ca-certificates curl gnupg
sudo install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
sudo chmod a+r /etc/apt/keyrings/docker.gpg

# Add the Docker repository
echo \
  "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
  "$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update package list again
sudo apt update

# Install containerd
sudo apt install -y containerd.io

# Create containerd configuration directory
sudo mkdir -p /etc/containerd

# Generate default configuration
sudo containerd config default | sudo tee /etc/containerd/config.toml

# Edit configuration to enable SystemdCgroup
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/g' /etc/containerd/config.toml

# Restart containerd
sudo systemctl restart containerd
sudo systemctl enable containerd

# Disable swap
sudo swapoff -a
sudo sed -i '/ swap / s/^\(.*\)$/#\1/g' /etc/fstab

# Configure kernel modules
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# Configure sysctl parameters
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system

# Install kubelet, kubeadm, and kubectl
sudo apt install -y kubelet kubeadm kubectl

# Pin their versions to avoid unexpected upgrades
sudo apt-mark hold kubelet kubeadm kubectl

# Verify the installations
kubeadm version
kubectl version --client
sudo systemctl status containerd
sudo systemctl enable kubelet
sudo systemctl start kubelet
```

## Step 4: Join Worker Nodes to the Cluster

Run the `kubeadm join` command **on each worker node**:

```bash
# Join the cluster using the token from the kubeadm init output
sudo kubeadm join <control-plane-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
```

If you've lost the token or it has expired, you can generate a new one on the control plane:

```bash
# Generate a new token
kubeadm token create --print-join-command
```

## Step 4: Verify the Cluster

Run these commands **on the control plane node**:

```bash
# Verify that all nodes are ready
kubectl get nodes

# Get detailed information about the nodes
kubectl describe nodes
```

## Step 5: Deploy a Test Application (Optional)

```bash
# Create a simple deployment
kubectl create deployment nginx --image=nginx

# Expose the deployment
kubectl expose deployment nginx --port=80 --type=NodePort

# Check the service
kubectl get svc nginx

# Access the application using <any-node-ip>:<node-port>
```

## Troubleshooting

### Common Issues:

1. **API Server Not Starting**:
   - Check if the API server is listening: `sudo netstat -tuln | grep 6443`
   - If not listening, reset the cluster: `sudo kubeadm reset -f`
   - Try initialization with explicit network interface: `SERVER_IP=$(ip -4 addr show eth0 | grep -oP '(?<=inet\s)\d+(\.\d+){3}')`

2. **kubectl Connection Refused Error**:
   - If you see `The connection to the server localhost:8080 was refused`, it means kubectl is not configured with the correct kubeconfig file
   - Run the kubeconfig setup commands again:
     ```bash
     mkdir -p $HOME/.kube
     sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
     sudo chown $(id -u):$(id -g) $HOME/.kube/config
     ```

3. **Node Status Shows "NotReady"**:
   - This is usually because the Container Network Interface (CNI) plugin isn't installed or initialized
   - Apply the network plugin:
     ```bash
     kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
     ```
   - Check network plugin pod status:
     ```bash
     kubectl get pods -n kube-system | grep calico
     ```
   - Check kubelet logs for issues:
     ```bash
     journalctl -xeu kubelet
     ```

4. **Pods stuck in "Pending" state**:
   - Check if the network plugin is installed correctly
   - Verify node resources using `kubectl describe node <node-name>`

3. **Nodes not joining the cluster**:
   - Verify network connectivity between nodes: `ping <control-plane-ip>`
   - Check that the correct token and discovery hash are used
   - Ensure containerd is running: `systemctl status containerd`
   - Check the kubelet service: `systemctl status kubelet`

4. **Control Plane Components not starting**:
   - Check logs: `kubectl logs -n kube-system <pod-name>`
   - Check container status: `sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps -a | grep kube`
   - Examine container logs: `sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock logs <container-id>`

### Useful Commands:

```bash
# Check pod status
kubectl get pods --all-namespaces

# Check kubelet status
systemctl status kubelet

# View kubelet logs
journalctl -xeu kubelet

# Check if API server is running
sudo netstat -tuln | grep 6443

# Install netstat if needed
sudo apt install -y net-tools

# Check running containers
sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock ps -a

# Check container logs
sudo crictl --runtime-endpoint unix:///var/run/containerd/containerd.sock logs <container-id>

# Reset kubeadm (if you need to start over)
sudo kubeadm reset -f
sudo rm -rf /etc/kubernetes/
sudo rm -rf ~/.kube/
sudo rm -rf /var/lib/etcd

# Clean iptables rules
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
```

## Additional Configuration

### Required Open Ports

**Control Plane Node**:
- TCP 6443: Kubernetes API server
- TCP 2379-2380: etcd server client API
- TCP 10250: Kubelet API
- TCP 10259: kube-scheduler
- TCP 10257: kube-controller-manager

**Worker Nodes**:
- TCP 10250: Kubelet API
- TCP 30000-32767: NodePort Services

### Setting Up Dashboard (Optional)

```bash
# Deploy the dashboard
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.7.0/aio/deploy/recommended.yaml

# Create an admin user
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

# Get the token
kubectl -n kubernetes-dashboard create token admin-user

# Start proxy to access the dashboard
kubectl proxy

# Access the dashboard at:
# http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/
```

## Upgrading the Cluster

To upgrade your Kubernetes cluster, refer to the official Kubernetes documentation for the appropriate version upgrade path and follow their recommended procedures.

## Backup Considerations

- Regularly back up etcd data from the control plane
- Consider using tools like Velero for cluster and application backups
- Document your setup and maintain procedures for disaster recovery

## References

- [Kubernetes Official Documentation](https://kubernetes.io/docs/setup/)
- [kubeadm Installation Guide](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/install-kubeadm/)
- [Calico Network Plugin](https://docs.projectcalico.org/getting-started/kubernetes/quickstart)