output "vpc_id" {
description = "ID of the VPC"
value       = aws_vpc.module_vpc.id
}

output "subnet_id" {
description = "ID of the subnet"
value       = aws_subnet.module_subnet.id
}

output "ec2_public_ip" {
description = "Public IP of the EC2 instance"
value       = aws_instance.module_ec2.public_ip
}