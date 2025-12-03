variable "region" {
description = "AWS region to deploy resources"
type        = string
default     = "us-east-1"
}

variable "ami" {
description = "AMI ID for the EC2 instance"
type        = string
default     = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 in us-east-1
}