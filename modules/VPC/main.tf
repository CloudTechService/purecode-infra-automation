# VPC
resource "aws_vpc" "vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = merge(var.tags, {
    Name = "${var.env}-vpc"
  })
}

# Public Subnets
resource "aws_subnet" "public_subnet" {
  for_each = { for idx, cidr in var.public_subnets : idx => cidr }

  vpc_id                  = aws_vpc.vpc.id
  cidr_block              = each.value
  availability_zone       = element(var.azs, each.key)
  map_public_ip_on_launch = true

  tags = merge(var.tags, {
    Name = "${var.env}-public-subnet-${each.key + 1}"
  })
}

# Private Subnets
resource "aws_subnet" "private_subnet" {
  for_each = { for idx, cidr in var.private_subnets : idx => cidr }

  vpc_id            = aws_vpc.vpc.id
  cidr_block        = each.value
  availability_zone = element(var.azs, each.key)

  tags = merge(var.tags, {
    Name = "${var.env}-private-subnet-${each.key + 1}"
  })
}

# Internet Gateway
resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.vpc.id

  tags = merge(var.tags, {
    Name = "${var.env}-igw"
  })
}

# Single Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = merge(var.tags, {
    Name = "${var.env}-nat-eip"
  })

  depends_on = [aws_internet_gateway.internet_gateway]
}

# Single NAT Gateway (in first public subnet)
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet[0].id

  tags = merge(var.tags, {
    Name = "${var.env}-nat"
  })

  depends_on = [aws_internet_gateway.internet_gateway]
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  tags = merge(var.tags, {
    Name = "${var.env}-public-rt"
  })
}

# Single Private Route Table (all private subnets use same NAT)
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gateway.id
  }

  tags = merge(var.tags, {
    Name = "${var.env}-private-rt"
  })
}

# Associate Public Route Table
resource "aws_route_table_association" "public_rta" {
  for_each = aws_subnet.public_subnet
  
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public_rt.id
}

# Associate Private Route Table (all private subnets to same route table)
resource "aws_route_table_association" "private_rta" {
  for_each = aws_subnet.private_subnet
  
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private_rt.id
}