output "ec2_instance_ids" {
  value = [for i in aws_instance.ec2_instances : i.id]
}

output "ec2_public_ips" {
  value = [for i in aws_instance.ec2_instances : i.public_ip]
}

output "ec2_private_ips" {
  value = [for i in aws_instance.ec2_instances : i.private_ip]
}

output "security_group_id" {
  value = aws_security_group.ec2_sg.id
}
