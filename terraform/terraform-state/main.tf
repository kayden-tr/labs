terraform {
required_providers {
 aws = {
   source = "hashicorp/aws"
   version = "5.0.0"
 }
}

backend "s3" {
 bucket         = "terraform-state-example-123"
 key            = "terraform.tfstate"
 region         = "us-east-1"
 dynamodb_table = "TerraformStateLock"
}
}

provider "aws" {
region = "us-east-1"
}

# Tạo Security Group cho EC2
resource "aws_security_group" "state_sg" {
name_prefix = "state-sg-"

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
 Name = "StateSG"
}
}

# Tạo EC2
resource "aws_instance" "state_ec2" {
ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 in us-east-1
instance_type = "t2.micro"
vpc_security_group_ids = [aws_security_group.state_sg.id]

tags = {
 Name = "StateEC2"
}
}

# Output public IP của EC2
output "ec2_public_ip" {
description = "Public IP of the EC2 instance"
value       = aws_instance.state_ec2.public_ip
}