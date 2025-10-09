# modules/ec2/outputs.tf

output "public_servers" {
  description = "Map of public server details"
  value = {
    for name, instance in aws_instance.public_servers : name => {
      id         = instance.id
      public_ip  = instance.public_ip
      private_ip = instance.private_ip
      role       = instance.tags["Role"]
    }
  }
}

output "private_servers" {
  description = "Map of private server details"
  value = {
    for name, instance in aws_instance.private_servers : name => {
      id         = instance.id
      private_ip = instance.private_ip
      role       = instance.tags["Role"]
    }
  }
}

output "public_security_group_id" {
  description = "Security group ID for public instances"
  value       = aws_security_group.public_sg.id
}

output "private_security_group_id" {
  description = "Security group ID for private instances"
  value       = aws_security_group.private_sg.id
}

output "all_server_ids" {
  description = "List of all server IDs"
  value = concat(
    [for instance in aws_instance.public_servers : instance.id],
    [for instance in aws_instance.private_servers : instance.id]
  )
}

output "all_server_names" {
  description = "List of all server names"
  value = concat(
    [for name in keys(aws_instance.public_servers) : name],
    [for name in keys(aws_instance.private_servers) : name]
  )
}