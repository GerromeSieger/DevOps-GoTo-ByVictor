# Node Infrastructure Management for Ethereum and Solana

This guide covers the essential components, tools, and best practices for managing blockchain node infrastructure at scale for Ethereum and Solana networks.

## Table of Contents

1. [Introduction](#introduction)
2. [Ethereum Node Infrastructure](#ethereum-node-infrastructure)
3. [Solana Node Infrastructure](#solana-node-infrastructure)
4. [Infrastructure as Code](#infrastructure-as-code)
5. [Monitoring and Observability](#monitoring-and-observability)
6. [Scaling and High Availability](#scaling-and-high-availability)
7. [Security Best Practices](#security-best-practices)
8. [Automation and DevOps](#automation-and-devops)
9. [Cost Optimization](#cost-optimization)
10. [Resources and References](#resources-and-references)

## Introduction

Node infrastructure management in Web3 involves deploying, maintaining, scaling, and securing blockchain nodes. These nodes are critical for:

- Providing RPC endpoints for dApps
- Validating transactions (for validators)
- Indexing blockchain data
- Supporting development and testing environments
- Running private blockchain networks

## Ethereum Node Infrastructure

### Node Types

1. **Execution Layer (formerly ETH1)**
   - **Full Nodes**: Store the entire blockchain state
   - **Archive Nodes**: Store historical states, significantly larger storage requirements
   - **Light Clients**: Store block headers only, rely on full nodes for state data

2. **Consensus Layer (formerly ETH2)**
   - **Beacon Nodes**: Track the Beacon Chain
   - **Validators**: Participate in block production and validation

### Client Software Options

#### Execution Layer Clients
- **Geth (Go Ethereum)**: Most popular client, written in Go
- **Erigon**: Optimized for storage and sync speed
- **Nethermind**: .NET implementation with better RPC capabilities
- **Besu**: Enterprise-focused Java implementation with permissioning

#### Consensus Layer Clients
- **Prysm**: Go implementation
- **Lighthouse**: Rust implementation
- **Teku**: Java implementation 
- **Nimbus**: Nim implementation, good for resource-constrained environments

### Hardware Requirements

| Node Type | CPU | RAM | Storage | Network |
|-----------|-----|-----|---------|---------|
| Full Node | 4+ cores | 16+ GB | 1+ TB SSD | 25+ Mbps |
| Archive Node | 8+ cores | 32+ GB | 12+ TB SSD | 25+ Mbps |
| Validator | 4+ cores | 8+ GB | 500+ GB SSD | 25+ Mbps |

### Docker Configurations

Example docker-compose.yml for a Geth full node:

```yaml
version: '3'
services:
  geth:
    image: ethereum/client-go:latest
    container_name: geth
    restart: unless-stopped
    ports:
      - "30303:30303/tcp"
      - "30303:30303/udp"
      - "8545:8545"  # RPC
      - "8546:8546"  # WebSocket
    volumes:
      - ./ethereum-data:/root/.ethereum
    command:
      - --http
      - --http.addr=0.0.0.0
      - --http.api=eth,net,web3,txpool
      - --http.vhosts=*
      - --ws
      - --ws.addr=0.0.0.0
      - --ws.origins=*
      - --cache=4096
```

### Kubernetes Setup

Example Kubernetes deployment for Geth:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: geth
spec:
  serviceName: "geth"
  replicas: 1
  selector:
    matchLabels:
      app: geth
  template:
    metadata:
      labels:
        app: geth
    spec:
      containers:
      - name: geth
        image: ethereum/client-go:latest
        args:
          - --http
          - --http.addr=0.0.0.0
          - --http.api=eth,net,web3,txpool
          - --http.vhosts=*
          - --ws
          - --ws.addr=0.0.0.0
          - --ws.origins=*
          - --cache=4096
        ports:
        - containerPort: 8545
          name: http-rpc
        - containerPort: 8546
          name: ws-rpc
        - containerPort: 30303
          name: discovery-tcp
          protocol: TCP
        - containerPort: 30303
          name: discovery-udp
          protocol: UDP
        volumeMounts:
        - name: ethereum-data
          mountPath: /root/.ethereum
  volumeClaimTemplates:
  - metadata:
      name: ethereum-data
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1Ti
```

## Solana Node Infrastructure

### Node Types

1. **Validator Nodes**: Process transactions and produce blocks
2. **RPC Nodes**: Serve client requests and API calls
3. **Archival Nodes**: Store complete transaction history

### Hardware Requirements

| Node Type | CPU | RAM | Storage | Network |
|-----------|-----|-----|---------|---------|
| Validator | 12+ cores/24+ threads | 128+ GB | 2+ TB NVMe SSD | 1+ Gbps |
| RPC Node | 8+ cores | 64+ GB | 1.5+ TB SSD | 1+ Gbps |
| Archival | 16+ cores | 256+ GB | 10+ TB SSD | 1+ Gbps |

### Docker Configuration

Example docker-compose.yml for a Solana RPC node:

```yaml
version: '3'
services:
  solana:
    image: solanalabs/solana:latest
    container_name: solana-rpc
    restart: unless-stopped
    ports:
      - "8899:8899"  # RPC port
      - "8900:8900"  # WebSocket port
    volumes:
      - ./solana-ledger:/opt/solana/ledger
    command:
      - solana-validator
      - --ledger /opt/solana/ledger
      - --identity /opt/solana/identity/validator-keypair.json
      - --entrypoint entrypoint.mainnet-beta.solana.com:8001
      - --entrypoint entrypoint2.mainnet-beta.solana.com:8001
      - --entrypoint entrypoint3.mainnet-beta.solana.com:8001
      - --entrypoint entrypoint4.mainnet-beta.solana.com:8001
      - --entrypoint entrypoint5.mainnet-beta.solana.com:8001
      - --known-validator 7Np41oeYqPefeNQEHSv1UDhYrehxin3NStELsSKCT4K2
      - --known-validator GdnSyH3YtwcxFvQrVVJMm1JhTS4QVX7MFsX56uJLUfiZ
      - --known-validator DE1bawNcRJB9rVm3buyMVfr8mBEoyyu73NBovf2oXJsJ
      - --rpc-port 8899
      - --rpc-bind-address 0.0.0.0
      - --full-rpc-api
      - --no-voting
      - --no-untrusted-rpc
```

### Kubernetes Setup

Example Kubernetes configuration for Solana RPC node:

```yaml
apiVersion: apps/v1
kind: StatefulSet
metadata:
  name: solana-rpc
spec:
  serviceName: "solana-rpc"
  replicas: 1
  selector:
    matchLabels:
      app: solana-rpc
  template:
    metadata:
      labels:
        app: solana-rpc
    spec:
      containers:
      - name: solana-rpc
        image: solanalabs/solana:latest
        command:
        - solana-validator
        - --ledger
        - /opt/solana/ledger
        - --identity
        - /opt/solana/identity/validator-keypair.json
        - --entrypoint
        - entrypoint.mainnet-beta.solana.com:8001
        - --entrypoint
        - entrypoint2.mainnet-beta.solana.com:8001
        - --entrypoint
        - entrypoint3.mainnet-beta.solana.com:8001
        - --rpc-port
        - "8899"
        - --rpc-bind-address
        - "0.0.0.0"
        - --full-rpc-api
        - --no-voting
        - --no-untrusted-rpc
        ports:
        - containerPort: 8899
          name: rpc
        - containerPort: 8900
          name: ws
        volumeMounts:
        - name: solana-ledger
          mountPath: /opt/solana/ledger
        - name: solana-identity
          mountPath: /opt/solana/identity
          readOnly: true
        resources:
          requests:
            memory: "64Gi"
            cpu: "8"
          limits:
            memory: "96Gi"
            cpu: "12"
      volumes:
      - name: solana-identity
        secret:
          secretName: solana-validator-keypair
  volumeClaimTemplates:
  - metadata:
      name: solana-ledger
    spec:
      accessModes: [ "ReadWriteOnce" ]
      resources:
        requests:
          storage: 1.5Ti
```

## Infrastructure as Code

### Tools for Managing Node Infrastructure

1. **Terraform**
   - Provision cloud resources (VMs, storage, networking)
   - Example: [ethereum-terraform](https://github.com/BenSchZA/ethereum-terraform)

2. **Ansible**
   - Configure nodes and install required software
   - Example: [ansible-ethereum](https://github.com/pegasyseng/ansible-role-ethereum-client)

3. **Pulumi**
   - Cloud-native infrastructure as code
   - Supports multiple languages (TypeScript, Python, Go)

4. **Docker & Kubernetes**
   - Containerization and orchestration
   - Helm charts for deployment management

### Example Terraform Configuration

Basic AWS EC2 instance for an Ethereum node:

```hcl
provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "ethereum_node" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "r5.2xlarge"
  
  root_block_device {
    volume_size = 1000
    volume_type = "gp3"
  }
  
  tags = {
    Name = "ethereum-node"
  }
  
  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              docker pull ethereum/client-go:latest
              EOF
}
```

## Monitoring and Observability

### Essential Monitoring Tools

1. **Prometheus**
   - Primary metrics collection platform
   - Node exporters for system metrics

2. **Grafana**
   - Visualization and dashboards
   - Pre-built dashboards for Ethereum and Solana

3. **Alertmanager**
   - Alert routing, grouping, and notifications
   - Integration with PagerDuty, Slack, etc.

4. **Loki/ELK Stack**
   - Log aggregation and searching
   - Useful for debugging node issues

### Key Metrics to Monitor

#### Ethereum
- Node sync status
- Peer count
- Block height/lag
- Transaction pool size
- RPC request counts and latency
- Gas price
- CPU, memory, disk, and network usage

#### Solana
- Slot height and skipped slots
- Transaction count and success rate
- Vote transaction performance
- Validator stake and rewards
- RPC request counts and latency
- CPU, memory, disk I/O, and network usage

### Example Prometheus Configuration

```yaml
global:
  scrape_interval: 15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'ethereum'
    static_configs:
      - targets: ['geth:8545']
    metrics_path: /debug/metrics/prometheus
    
  - job_name: 'solana'
    static_configs:
      - targets: ['solana-validator:8899']
    metrics_path: /metrics
    
  - job_name: 'node_exporter'
    static_configs:
      - targets: ['node_exporter:9100']
```

## Scaling and High Availability

### Scaling Strategies

1. **Load Balancing**
   - API Gateway/Load Balancer in front of multiple RPC nodes
   - Smart routing based on request type

2. **Read/Write Separation**
   - Dedicated nodes for read operations vs. write operations
   - Cache common read requests

3. **Regional Distribution**
   - Deploy nodes across multiple regions
   - Use global load balancing for routing users to closest node

### High Availability Setup

#### Architecture Components
- Multiple nodes across availability zones
- Automated failover
- Health checks and auto-healing
- Regular state backups

#### Example AWS Architecture

```plaintext
VPC
├── AZ-1
│   ├── EC2 (Ethereum Node 1)
│   └── EBS Volume (1TB gp3)
├── AZ-2
│   ├── EC2 (Ethereum Node 2)
│   └── EBS Volume (1TB gp3)
├── ElastiCache (for state caching)
├── Application Load Balancer
└── Auto Scaling Group
```

## Security Best Practices

### Network Security

1. **Firewall Rules**
   - Allow only necessary ports
   - Ethereum: 30303 (P2P), 8545 (RPC), 8546 (WebSocket)
   - Solana: 8000-8002 (P2P), 8899 (RPC), 8900 (WebSocket)

2. **Private Network**
   - Run nodes in private subnets
   - Use bastion hosts for management
   - Implement VPC endpoints for secure access

3. **DDoS Protection**
   - Use services like Cloudflare or AWS Shield
   - Implement rate limiting on RPC endpoints

### Node Security

1. **Minimize Attack Surface**
   - Disable unnecessary APIs
   - Implement proper authentication for RPC endpoints
   - Use whitelists for public RPC endpoints

2. **Regular Updates**
   - Keep node software up to date
   - Follow security advisories

3. **Secure Key Management**
   - Use hardware security modules (HSMs) for validator keys
   - Implement proper secret management (HashiCorp Vault, AWS Secrets Manager)

## Automation and DevOps

### CI/CD Pipelines

1. **GitHub Actions/GitLab CI**
   - Automated testing and deployment
   - Infrastructure validation

2. **ArgoCD/Flux**
   - GitOps for Kubernetes deployments
   - Automated synchronization with repositories

### Backup and Disaster Recovery

1. **Regular Snapshots**
   - Daily backups of node data
   - Cold storage for backups

2. **Recovery Procedures**
   - Documented recovery processes
   - Regular recovery drills

3. **Fast Sync Capabilities**
   - Checkpoint sync for Ethereum
   - Snapshot downloading for Solana

## Cost Optimization

### Strategies

1. **Right-sizing**
   - Match instance types to workload
   - Adjust resources based on monitoring data

2. **Storage Optimization**
   - Use pruned nodes where possible
   - Implement storage tiering

3. **Reserved/Spot Instances**
   - Use reserved instances for base capacity
   - Spot instances for non-critical workloads

### Cost Comparison

| Setup Type | Monthly Cost Range (USD) |
|------------|--------------------------|
| Ethereum Full Node (Self-hosted) | $300-$500 |
| Ethereum Archive Node (Self-hosted) | $1,500-$3,000 |
| Solana RPC Node (Self-hosted) | $1,000-$2,000 |
| Solana Validator (Self-hosted) | $2,000-$4,000 |

## Resources and References

### Ethereum Resources
- [Ethereum Node Documentation](https://ethereum.org/en/developers/docs/nodes-and-clients/)
- [Geth Documentation](https://geth.ethereum.org/docs/)
- [Ethereum Client Comparison](https://docs.ethhub.io/using-ethereum/running-an-ethereum-node/)

### Solana Resources
- [Solana Validator Requirements](https://docs.solana.com/running-validator/validator-reqs)
- [RPC Node Setup Guide](https://docs.solana.com/running-validator/validator-start)
- [Solana Monitoring Guide](https://docs.solana.com/operations/monitoring)

### Infrastructure Tools
- [Terraform Documentation](https://www.terraform.io/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/home/)
- [Prometheus for Blockchain Monitoring](https://prometheus.io/docs/introduction/overview/)
- [Grafana Dashboards](https://grafana.com/grafana/dashboards/)

### Community Resources
- [Ethereum Stack Exchange](https://ethereum.stackexchange.com/)
- [Solana Tech Discord](https://discord.com/invite/pquxPsq)
- [Web3 Infrastructure Twitter List](https://twitter.com/i/lists/1496886255154196486)