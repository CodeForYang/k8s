terraform {
  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
  }
}


resource "local_file" "hello" {
  content  = "Hello Terraform!"
  filename = "${path.module}/hello.txt"
}