output "vpc_id" {
  value = aws_vpc.vpc.id
}

output "public_subnets" {
  value = aws_subnet.public
}

output "private_subnets" {
  value = aws_subnet.private
}

output "private_route_tables" {
  value = aws_route_table.private
}

output "availability_zones" {
  value = data.aws_availability_zones.available
}

output "vpc_security_group" {
  value = aws_security_group.vpc
}
