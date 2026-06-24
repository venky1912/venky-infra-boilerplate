# Hybrid EKS Cluster - On-Premises Node Setup

## Overview

EKS Hybrid Nodes allow you to register on-premises or edge servers as Kubernetes nodes in your EKS cluster.

## Prerequisites

- EKS cluster deployed with `cluster_type = "hybrid"`
- On-prem nodes running Ubuntu 22.04+ or Amazon Linux 2023
- Network connectivity from on-prem to AWS (Direct Connect or VPN)
- On-prem CIDRs configured in `remote_node_cidrs` and `remote_pod_cidrs`

## Steps

### 1. Deploy Infrastructure

```hcl
# terraform.tfvars
cluster_type      = "hybrid"
remote_node_cidrs = ["172.16.0.0/16"]
remote_pod_cidrs  = ["172.17.0.0/16"]
```

```bash
terraform apply
```

### 2. Get SSM Activation Credentials

```bash
terraform output hybrid_ssm_activation_id
terraform output -raw hybrid_ssm_activation_code  # sensitive
```

### 3. Install nodeadm on On-Prem Nodes

```bash
# On each on-prem node:
curl -sL https://github.com/awslabs/amazon-eks-ami/releases/latest/download/nodeadm-linux-amd64 -o /usr/local/bin/nodeadm
chmod +x /usr/local/bin/nodeadm
```

### 4. Create nodeadm Config

```yaml
# /etc/nodeadm/nodeConfig.yaml
apiVersion: node.eks.aws/v1alpha1
kind: NodeConfig
spec:
  cluster:
    name: <cluster-name>
    region: <region>
  hybrid:
    ssm:
      activationId: <from-terraform-output>
      activationCode: <from-terraform-output>
```

### 5. Register Node

```bash
sudo nodeadm init --config /etc/nodeadm/nodeConfig.yaml
```

### 6. Verify

```bash
kubectl get nodes
# Should show your on-prem node with status Ready
```

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Node not registering | Check SSM activation hasn't expired |
| Node in NotReady | Verify network connectivity to EKS API |
| CNI errors | Ensure remote_pod_cidrs matches on-prem CNI config |
