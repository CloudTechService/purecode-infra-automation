variable "region" {
  description = "AWS region"
  type        = string
}

variable "env" {
  description = "Environment name"
  type        = string
}

variable "subnets" {
  description = <<EOT
Map of subnet IDs to number of EC2 instances to create.
Key   = subnet ID
Value = number of instances in that subnet
EOT
  type = map(number)
}

variable "public_subnet_ids" {
  description = "List of public subnet IDs to identify which subnets get public IP"
  type        = list(string)
  default     = []
}

variable "ami_id" {
  description = "AMI ID for EC2 instances"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
}

variable "key_name" {
  description = "Key pair name for SSH access"
  type        = string
}

variable "ssh_allowed_cidrs" {
  description = "CIDR blocks allowed for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "http_allowed_cidrs" {
  description = "CIDR blocks allowed for HTTP"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default     = {}
}

variable "vpc_id" {
  type        = string
  description = "VPC ID where EC2 instances will be deployed"
}
