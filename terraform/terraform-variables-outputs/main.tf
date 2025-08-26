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

resource "aws_instance" "custom_ec2" {
ami           = var.ami
instance_type = var.instance_type
tags = {
 Name = var.instance_name
}
}

output "instance_id" {
description = "ID of the EC2 instance"
value       = aws_instance.custom_ec2.id
}

output "public_ip" {
description = "Public IP of the EC2 instance"
value       = aws_instance.custom_ec2.public_ip
}

output "private_ip" {
description = "Public IP of the EC2 instance"
value       = aws_instance.custom_ec2.private_ip
}