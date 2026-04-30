# ============================================
# DEVELOPMENT ENVIRONMENT
# ============================================
# This calls our VPC module with dev values
# ============================================

terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "eu-west-1"
}

locals {
  project_name = "technova"
  environment  = "dev"

  common_tags = {
    Project     = "technova"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Owner       = "Platform-Engineering"
  }
}

# ── CALL VPC MODULE ───────────────────────────
module "vpc" {
  source = "../../modules/vpc"

  project_name = "${local.project_name}-${local.environment}"

  vpc_cidr           = "10.0.0.0/16"
  availability_zones = ["eu-west-1a", "eu-west-1b"]

  public_subnet_cidrs = [
    "10.0.1.0/24",
    "10.0.2.0/24"
  ]

  private_subnet_cidrs = [
    "10.0.3.0/24",
    "10.0.4.0/24"
  ]

  database_subnet_cidrs = [
    "10.0.5.0/24",
    "10.0.6.0/24"
  ]

  common_tags = local.common_tags
}
