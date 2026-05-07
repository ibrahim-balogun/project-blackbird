# ============================================
# SECURITY MODULE OUTPUTS
# ============================================
# Shared with other modules that need
# security group IDs and IAM roles
# ============================================

output "load_balancer_sg_id" {
  description = "Security group ID for load balancer"
  value       = aws_security_group.load_balancer.id
}

output "application_sg_id" {
  description = "Security group ID for application tier"
  value       = aws_security_group.application.id
}

output "database_sg_id" {
  description = "Security group ID for database tier"
  value       = aws_security_group.database.id
}

output "ec2_instance_profile" {
  description = "IAM instance profile for EC2"
  value       = aws_iam_instance_profile.ec2.name
}

output "ec2_role_arn" {
  description = "IAM role ARN for EC2"
  value       = aws_iam_role.ec2.arn
}
