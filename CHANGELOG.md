# Changelog

## [0.1.0] - 2026-06-24

### Added

- Initial release
- Multi-environment infra (dev/staging/prod)
- VPC with multi-AZ subnets, NAT, endpoints
- EKS cluster (cloud + hybrid support)
- EKS managed add-ons (CoreDNS, VPC CNI, kube-proxy, EBS CSI, Pod Identity)
- IAM roles (cluster, node, hybrid)
- KMS encryption for EKS secrets
- Security groups with EKS port configuration
- Hybrid node support (SSM activation, HYBRID_LINUX access entry)
- Full documentation (prerequisites, hybrid setup, pipeline stages)
- CI/CD pipelines (security scan, validate, plan)
- State backend creation script
