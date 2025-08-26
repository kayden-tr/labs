variable "region" {
description = "AWS region to deploy resources"
type        = string
default     = "ap-southeast-1"
}

variable "ami" {
description = "AMI ID for the EC2 instance"
type        = string
default     = "ami-0779c82fbb81e731c"
}

variable "instance_type" {
description = "EC2 instance type"
type        = string
default     = "t2.micro"
}

variable "instance_name" {
description = "Name tag for the EC2 instance"
type        = string
default     = "MyCustomWithVarEC2"
}
