output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnet_ids" {
  value = [for s in aws_subnet.public_subnet : s.id]
}

output "private_subnet_ids" {
  value = [for s in aws_subnet.private_subnet : s.id]
}

output "internet_gateway_id" {
  value = aws_internet_gateway.internet_gateway.id
}

output "nat_gateway_ids" {
  value = [for ng in aws_nat_gateway.nat_gateway : ng.id]
}
