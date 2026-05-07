# ============================================
# PROJECT BLACKBIRD — SECURITY MODULE
# ============================================
# This file creates all security resources:
# - Security Groups for each tier
# - IAM roles for EC2 and EKS
# - GuardDuty threat detection
# ============================================

# ── SECURITY GROUP — LOAD BALANCER ───────────
# Only allows HTTP and HTTPS from internet
# Everything else is blocked
resource "aws_security_group" "load_balancer" {
  name        = "${var.project_name}-sg-alb"
  description = "Security group for Application Load Balancer"
  vpc_id      = var.vpc_id

  # Allow HTTP from anywhere
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTP from internet"
  }

  # Allow HTTPS from anywhere
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow HTTPS from internet"
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-sg-alb"
  })
}

# ── SECURITY GROUP — APPLICATION ─────────────
# Only accepts traffic FROM load balancer
# Direct internet access is blocked
resource "aws_security_group" "application" {
  name        = "${var.project_name}-sg-app"
  description = "Security group for application servers"
  vpc_id      = var.vpc_id

  # Only allow traffic from load balancer
  ingress {
    from_port       = 8080
    to_port         = 8080
    protocol        = "tcp"
    security_groups = [aws_security_group.load_balancer.id]
    description     = "Allow traffic from load balancer only"
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-sg-app"
  })
}

# ── SECURITY GROUP — DATABASE ─────────────────
# Only accepts traffic FROM application servers
# Internet cannot reach database directly
# This is critical for security
resource "aws_security_group" "database" {
  name        = "${var.project_name}-sg-db"
  description = "Security group for database tier"
  vpc_id      = var.vpc_id

  # Only allow traffic from application servers
  ingress {
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.application.id]
    description     = "Allow PostgreSQL from app servers only"
  }

  # Allow all outbound
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    description = "Allow all outbound"
  }

  tags = merge(var.common_tags, {
    Name = "${var.project_name}-sg-db"
  })
}

# ── IAM ROLE — EC2 ────────────────────────────
# Allows EC2 instances to access AWS services
# Without this EC2 cannot talk to S3, 
# CloudWatch, Secrets Manager etc
resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = var.common_tags
}

# Attach policies to EC2 role
resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "ec2_cloudwatch" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

# EC2 instance profile — attaches role to EC2
resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name

  tags = var.common_tags
}
