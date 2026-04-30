# ============================================
# PROJECT BLACKBIRD — VPC MODULE
# ============================================
# This file creates all networking resources
# for TechNova's infrastructure
# ============================================

# ── VPC ──────────────────────────────────────
# This is our private network in AWS
# Everything we build lives inside this VPC
resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-vpc"
  })
}

# ── INTERNET GATEWAY ─────────────────────────
# This is the door between our VPC 
# and the public internet.
# Without this nothing in our VPC 
# can reach the internet.
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-igw"
  })
}

# ── PUBLIC SUBNETS ───────────────────────────
# These subnets face the internet
# Used for: Load Balancers only
# NOT for application servers or databases
resource "aws_subnet" "public" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.public_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  map_public_ip_on_launch = true

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-public-${var.availability_zones[count.index]}"
    Tier = "Public"
    "kubernetes.io/role/elb" = "1"
  })
}

# ── PRIVATE SUBNETS ──────────────────────────
# Hidden from internet
# Used for: EKS nodes, Application servers
resource "aws_subnet" "private" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.private_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-private-${var.availability_zones[count.index]}"
    Tier = "Private"
    "kubernetes.io/role/internal-elb" = "1"
  })
}

# ── DATABASE SUBNETS ─────────────────────────
# Completely isolated from internet
# Used for: RDS PostgreSQL, ElastiCache Redis
# Only application servers can reach these
resource "aws_subnet" "database" {
  count             = length(var.availability_zones)
  vpc_id            = aws_vpc.main.id
  cidr_block        = var.database_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-database-${var.availability_zones[count.index]}"
    Tier = "Database"
  })
}

# ── ELASTIC IPs FOR NAT GATEWAYS ─────────────
# NAT Gateways need static public IP addresses
resource "aws_eip" "nat" {
  count  = length(var.availability_zones)
  domain = "vpc"

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-eip-${count.index + 1}"
  })

  depends_on = [aws_internet_gateway.main]
}

# ── NAT GATEWAYS ─────────────────────────────
# One per AZ for high availability
# Allows private subnets outbound internet access
# Inbound internet CANNOT reach private subnets
resource "aws_nat_gateway" "main" {
  count         = length(var.availability_zones)
  allocation_id = aws_eip.nat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-nat-${var.availability_zones[count.index]}"
  })

  depends_on = [aws_internet_gateway.main]
}
