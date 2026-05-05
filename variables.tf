variable "aws_region" {
  description = "AWS Region to deploy to"
  type        = string
  default     = "ca-central-1"
}

variable "project_name" {
  description = "Name of the project"
  type        = string
  default     = "redis-connector"
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)"
  type        = string
}

variable "vpc_id" {
  description = "The ID of the existing VPC"
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet for the Lambda VPC config"
  type        = string
}

variable "redis_host" {
  description = "ElastiCache Redis cluster endpoint"
  type        = string
}

variable "redis_port" {
  description = "ElastiCache Redis port"
  type        = number
  default     = 6379
}

variable "origin_host" {
  description = "Origin server address used by the handler for CORS"
  type        = string
}

variable "app_domain" {
  description = "Application domain (e.g. staging.example.com)"
  type        = string
}
