terraform {
required_providers {
 aws = {
   source = "hashicorp/aws"
   version = "5.0.0"
 }
}
}

provider "aws" {
region = "ap-southeast-1"
}

resource "aws_instance" "my_first_ec2" {
ami           = "ami-0779c82fbb81e731c"
instance_type = "t2.micro"
tags = {
 Name = "MyFirstEC2"
}
}