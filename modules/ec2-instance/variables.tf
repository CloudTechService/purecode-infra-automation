variable "name" {
  description = "Name of the EC2 instance"
  type        = string
  default     = "Jenkins Server"
}

variable "instance_type" {
  description = "EC2 instance type"
  type        = string
  default     = "t3.micro"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  type        = string
  default     = "qa-keypair"
}

variable "monitoring" {
  description = "Enable detailed monitoring"
  type        = bool
  default     = true
}

variable "subnet_id" {
  description = "Subnet ID where EC2 instance will be launched"
  type        = string
  default     = "subnet-0f5d7f800a61ce166"
}

variable "vpc_id" {
  description = "VPC ID where security group will be created"
  type        = string
  default     = "vpc-0f1f05c1122134138"
}

variable "ssh_cidr_blocks" {
  description = "CIDR blocks allowed for SSH access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "http_cidr_blocks" {
  description = "CIDR blocks allowed for HTTP access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "https_cidr_blocks" {
  description = "CIDR blocks allowed for HTTPS access"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default = {
    Terraform   = "true"
    Environment = "qa"
  }
}