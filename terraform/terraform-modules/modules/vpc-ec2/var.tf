variable "vpc_cidr" {
description = "CIDR block for the VPC"
type        = string
default     = "10.0.0.0/16"
}

variable "subnet_cidr" {
description = "CIDR block for the subnet"
type        = string
default     = "10.0.1.0/24"
}

variable "environment" {
description = "Dev"
type        = string
}

variable "ami" {
description = "AMI ID for the EC2 instance"
type        = string
default     = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 in us-east-1
}

variable "instance_type" {
description = "EC2 instance type"
type        = string
default     = "t2.micro"
}