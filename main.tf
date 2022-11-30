terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS Provider


provider "aws" {
  shared_config_files      = ["C:/Users/arfin/.aws/config"]
  shared_credentials_files = ["C:/Users/arfin/.aws/credentials"]
  #profile                  = "default"
}


resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my_vpc"
  }
}

resource "aws_subnet" "my_subnet_1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "my_subnet_1"
  }
}

resource "aws_subnet" "my_subnet_2" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "my_subnet_2"
  }
}

# resource "aws_instance" "my_first_instance" {
#   ami                       = "ami-02aeff1a953c5c2ff"
#   instance_type             = "t3.micro"
# }