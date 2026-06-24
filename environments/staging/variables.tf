################################################################################
# General
################################################################################

variable "project_name" {
  description = "Project name used for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
}

variable "region" {
  description = "AWS region"
  type        = string
}

variable "owner" {
  description = "Team or individual owning this infrastructure"
  type        = string
}

################################################################################
# VPC
################################################################################

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  description = "List of availability zones"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "CIDR blocks for public subnets"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "CIDR blocks for private subnets"
  type        = list(string)
}

variable "database_subnet_cidrs" {
  description = "CIDR blocks for database subnets"
  type        = list(string)
  default     = []
}

variable "single_nat_gateway" {
  description = "Use single NAT gateway (cost saving for non-prod)"
  type        = bool
  default     = true
}

################################################################################
# EKS
################################################################################

variable "cluster_version" {
  description = "EKS Kubernetes version"
  type        = string
  default     = "1.30"
}

variable "cluster_type" {
  description = "EKS cluster type: cloud or hybrid"
  type        = string
  default     = "cloud"

  validation {
    condition     = contains(["cloud", "hybrid"], var.cluster_type)
    error_message = "cluster_type must be 'cloud' or 'hybrid'."
  }
}

variable "node_instance_types" {
  description = "Instance types for EKS managed node group"
  type        = list(string)
  default     = ["m5.large"]
}

variable "node_min_size" {
  description = "Minimum number of nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of nodes"
  type        = number
  default     = 10
}

variable "node_desired_size" {
  description = "Desired number of nodes"
  type        = number
  default     = 3
}

variable "node_disk_size" {
  description = "Disk size in GB for nodes"
  type        = number
  default     = 50
}

################################################################################
# Hybrid (optional)
################################################################################

variable "remote_node_cidrs" {
  description = "On-prem node CIDRs for hybrid cluster"
  type        = list(string)
  default     = []
}

variable "remote_pod_cidrs" {
  description = "On-prem pod CIDRs for hybrid cluster"
  type        = list(string)
  default     = []
}

################################################################################
# Security
################################################################################

variable "cluster_endpoint_public_access" {
  description = "Allow public access to EKS API endpoint"
  type        = bool
  default     = false
}

variable "cluster_endpoint_public_access_cidrs" {
  description = "CIDRs allowed for public API access (if enabled)"
  type        = list(string)
  default     = []
}
