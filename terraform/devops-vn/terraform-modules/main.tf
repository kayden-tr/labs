terraform {
required_providers {
 aws = {
   source = "hashicorp/aws"
   version = "5.0.0"
 }
}
}

provider "aws" {
region = "us-east-1"
}

# Sử dụng module vpc-ec2 cho môi trường dev
module "dev_vpc_ec2" {
source = "./modules/vpc-ec2"

environment    = "dev"
vpc_cidr       = "10.1.0.0/16"
subnet_cidr    = "10.1.1.0/24"
ami            = "ami-0c55b159cbfafe1f0"
instance_type  = "t2.micro"
}

# Output từ module
output "dev_vpc_id" {
description = "VPC ID for dev environment"
value       = module.dev_vpc_ec2.vpc_id
}

output "dev_subnet_id" {
description = "Subnet ID for dev environment"
value       = module.dev_vpc_ec2.subnet_id
}

output "dev_ec2_public_ip" {
description = "Public IP of the EC2 instance in dev environment"
value       = module.dev_vpc_ec2.ec2_public_ip
}