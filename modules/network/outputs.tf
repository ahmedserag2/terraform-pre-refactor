output "subnet_ids" {
  description = "ID of project VPC"
  value       = aws_subnet.private_sub[*].id
}

output "vpc_id" {
  description = "ID of project VPC"
  value       = aws_vpc.main.id
}

output "public_subnet_ids" {
  description = "subnets ids"
  value       = aws_subnet.public_sub[*].id
}
