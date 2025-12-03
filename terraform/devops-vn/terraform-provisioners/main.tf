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

# Tạo Security Group cho EC2
resource "aws_security_group" "web_sg" {
name_prefix = "web-sg-"

ingress {
 from_port   = 22
 to_port     = 22
 protocol    = "tcp"
 cidr_blocks = ["0.0.0.0/0"]
}

ingress {
 from_port   = 80
 to_port     = 80
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
 Name = "WebSG"
}
}

# Tạo EC2 với provisioner
resource "aws_instance" "web_server" {
ami           = "ami-0c55b159cbfafe1f0" # Amazon Linux 2 in us-east-1
instance_type = "t2.micro"
key_name      = "my-key" # Thay bằng tên key pair của bạn đã tạo trên AWS
vpc_security_group_ids = [aws_security_group.web_sg.id]
associate_public_ip_address = true

tags = {
 Name = "WebServer"
}

# Sử dụng provisioner để cài đặt Nginx
provisioner "remote-exec" {
 inline = [
   "sudo yum update -y",
   "sudo yum install -y nginx",
   "sudo systemctl start nginx",
   "sudo systemctl enable nginx",
   "echo '
<h1>Welcome to Nginx - Deployed by Terraform!</h1>' | sudo tee /usr/share/nginx/html/index.html"
 ]

 connection {
   type        = "ssh"
   user        = "ec2-user"
   private_key = file("my-key.pem") # Đường dẫn đến file .pem của bạn
   host        = self.public_ip
 }
}
}

# Output public IP của EC2
output "web_server_public_ip" {
description = "Public IP of the web server"
value       = aws_instance.web_server.public_ip
}