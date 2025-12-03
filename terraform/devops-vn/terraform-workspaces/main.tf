terraform {
required_providers {
 aws = {
   source = "hashicorp/aws"
   version = "5.0.0"
 }
}
}

provider "aws" {
region = var.region
}

# Định nghĩa thông số dựa trên workspace
locals {
instance_type = terraform.workspace == "prod" ? "t3.medium" : "t2.micro"
instance_count = terraform.workspace == "prod" ? 2 : 1
environment = terraform.workspace
}

# Tạo Security Group cho EC2
resource "aws_security_group" "workspace_sg" {
name_prefix = "${local.environment}-sg-"

ingress {
 from_port   = 22
 to_port     = 22
 protocol    = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
}

egress {
 from_port   = 0
 to_port     = 0
 protocol    = "-1"
 cidr_blocks = ["0.0.0.0/0"]
}

tags = {
 Name = "${local.environment}-SG"
}
}

# Tạo EC2
resource "aws_instance" "workspace_ec2" {
count         = local.instance_count
ami           = var.ami
instance_type = local.instance_type
vpc_security_group_ids = [aws_security_group.workspace_sg.id]

tags = {
 Name = "${local.environment}-EC2-${count.index + 1}"
}
}

# Output public IP của EC2
output "ec2_public_ips" {
description = "Public IPs of the EC2 instances"
value       = aws_instance.workspace_ec2[*].public_ip
}