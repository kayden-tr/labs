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

# Create VPC
resource "aws_vpc" "my_vpc" {
cidr_block = "10.0.0.0/16"
tags = {
 Name = "MyVPC"
}
}

# Create subnet
resource "aws_subnet" "my_subnet" {
vpc_id     = aws_vpc.my_vpc.id
cidr_block = "10.0.1.0/24"
tags = {
 Name = "MySubnet"
}
}

# Create Internet Gateway
resource "aws_internet_gateway" "my_igw" {
vpc_id = aws_vpc.my_vpc.id
tags = {
 Name = "MyInternetGateway"
}
}

# Create Route Table
resource "aws_route_table" "my_route_table" {
vpc_id = aws_vpc.my_vpc.id

route {
 cidr_block = "0.0.0.0/0"
 gateway_id = aws_internet_gateway.my_igw.id
}

tags = {
 Name = "MyRouteTable"
}
}

# Assign Route Table with Subnet
resource "aws_route_table_association" "my_route_table_association" {
subnet_id      = aws_subnet.my_subnet.id
route_table_id = aws_route_table.my_route_table.id
}
