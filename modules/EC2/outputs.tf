output "ec2_instance_ids" {
  description = "List of EC2 instance IDs"
  value       = [for inst in aws_instance.ec2_instance : inst.id]
}

output "ec2_public_ips" {
  description = "List of public IP addresses"
  value       = [for inst in aws_instance.ec2_instance : inst.public_ip]
}

output "ec2_private_ips" {
  description = "List of private IP addresses"
  value       = [for inst in aws_instance.ec2_instance : inst.private_ip]
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.ec2_sg.id
}