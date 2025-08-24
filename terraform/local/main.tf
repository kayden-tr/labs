terraform {
required_providers {
 local = {
   source = "hashicorp/local"
   version = "2.5.1"
 }
}
}

provider "local" {}

resource "local_file" "hello" {
filename = "hello.txt"
content  = "Chào mừng bạn đến với Terraform!"
}