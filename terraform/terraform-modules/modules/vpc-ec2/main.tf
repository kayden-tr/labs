# Tạo VPC
resource "aws_vpc" "module_vpc" {
cidr_block = var.vpc_cidr
tags = {
 Name = "${var.environment}-VPC"
}
}

# Tạo Subnet
resource "aws_subnet" "module_subnet" {
vpc_id     = aws_vpc.module_vpc.id
cidr_block = var.subnet_cidr
tags = {
 Name = "${var.environment}-Subnet"
}
}

# Tạo Internet Gateway
resource "aws_internet_gateway" "module_igw" {
vpc_id = aws_vpc.module_vpc.id
tags = {
 Name = "${var.environment}-IGW"
}
}

# Tạo Route Table
resource "aws_route_table" "module_route_table" {
vpc_id = aws_vpc.module_vpc.id

route {
 cidr_block = "0.0.0.0/0"
 gateway_id = aws_internet_gateway.module_igw.id
}

tags = {
 Name = "${var.environment}-RouteTable"
}
}

# Gắn Route Table với Subnet
resource "aws_route_table_association" "module_route_table_association" {
subnet_id      = aws_subnet.module_subnet.id
route_table_id = aws_route_table.module_route_table.id
}

# Tạo Security Group cho EC2
resource "aws_security_group" "module_sg" {
vpc_id = aws_vpc.module_vpc.id

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
 Name = "${var.environment}-SG"
}
}

# Tạo EC2
resource "aws_instance" "module_ec2" {
ami           = var.ami
instance_type = var.instance_type
subnet_id     = aws_subnet.module_subnet.id
vpc_security_group_ids = [aws_security_group.module_sg.id]
associate_public_ip_address = true

tags = {
 Name = "${var.environment}-EC2"
}
}
