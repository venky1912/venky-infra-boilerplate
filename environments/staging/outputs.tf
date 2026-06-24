################################################################################
# VPC
################################################################################

output "vpc_id" {
  description = "VPC ID"
  value       = module.vpc.vpc_id
}

output "private_subnet_ids" {
  description = "Private subnet IDs"
  value       = module.vpc.private_subnet_ids
}

################################################################################
# EKS
################################################################################

output "cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = module.eks.cluster_endpoint
}

output "cluster_oidc_issuer_url" {
  description = "EKS cluster OIDC issuer URL"
  value       = module.eks.cluster_oidc_issuer_url
}

output "cluster_certificate_authority_data" {
  description = "EKS cluster CA data"
  value       = module.eks.cluster_certificate_authority_data
  sensitive   = true
}

################################################################################
# Hybrid (conditional)
################################################################################

output "hybrid_node_role_arn" {
  description = "Hybrid node IAM role ARN (if hybrid)"
  value       = try(module.hybrid_node_role[0].role_arn, null)
}

output "hybrid_ssm_activation_id" {
  description = "SSM activation ID for hybrid nodes (if hybrid)"
  value       = try(module.hybrid_node_role[0].ssm_activation_id, null)
}

################################################################################
# Kubeconfig
################################################################################

output "kubeconfig_command" {
  description = "Command to configure kubectl"
  value       = "aws eks update-kubeconfig --region ${var.region} --name ${module.eks.cluster_name}"
}
