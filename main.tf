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


# Define variables

variable "my_keypair" {
  description = "My personal KEYPAIR"
  type = string

}

variable "my_tag" {
  description = "My personal tag to group resources"
  type = string

}

variable "vpc_prefix" {
  description = "cidr block for the vpc"
  type = string
}

variable "subnet_prefix" {
  description = "cidr block for the subnet"
  type = string
}

variable "nic_private_ip" {
  description = "List of private IP addresses associated to the network interface"
  type = string
}


# Set up a VPC
resource "aws_vpc" "my_vpc" {
  cidr_block = var.vpc_prefix

  tags = {
    Name = var.my_tag
  }
}

# Create Internet Gateway
resource "aws_internet_gateway" "my_gw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = var.my_tag
  }
}

# Define Route Table
resource "aws_route_table" "my_route_table" {
  vpc_id = aws_vpc.my_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.my_gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.my_gw.id
  }

  tags = {
    Name = var.my_tag
  }
}

# Create a Subnet 
resource "aws_subnet" "my_subnet_1" {
  vpc_id     = aws_vpc.my_vpc.id
  cidr_block = var.subnet_prefix
  availability_zone = "eu-north-1a"

  tags = {
    Name = "nadir-terraform-project"
  }
}

# Route table association to the subnet 
resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.my_subnet_1.id
  route_table_id = aws_route_table.my_route_table.id
}

# Create Security Group to allow port 22 SSH, 80 HTTP, 443 HTTPS
resource "aws_security_group" "sg_ssh" {
  name        = "sg_ssh"
  description = "Allow secure SSH connection"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description      = "Allow SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = var.my_tag
  }
}

resource "aws_security_group" "sg_http_https" {
  name        = "sg_http_https"
  description = "Allow web traffic"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    description      = "Allow HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "Allow HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = var.my_tag
  }
}

# Create a network interface 
resource "aws_network_interface" "my_web_server_nic" {
  subnet_id       = aws_subnet.my_subnet_1.id
  private_ips     = [var.nic_private_ip]
  security_groups = [aws_security_group.sg_ssh.id, aws_security_group.sg_http_https.id]
  tags = {
    Name = var.my_tag
  }
}

# Assign an Elastic IP  
resource "aws_eip" "my_elastic_ip" {
  vpc      = true
  network_interface = aws_network_interface.my_web_server_nic.id
  associate_with_private_ip = var.nic_private_ip
  depends_on                = [aws_internet_gateway.my_gw]
  tags = {
    Name = var.my_tag
  }  
}

# Create an EC2 instance 
resource "aws_instance" "my_web_server" {
  ami                       = "ami-0efda064d1b5e46a5" # Canonical, Ubuntu, 22.04 LTS, amd64 jammy image build on 2022-09-12 
  instance_type             = "t3.micro"
  availability_zone         = "eu-north-1a"
  key_name                  = var.my_keypair
  user_data = "${file("user_data.sh")}"

  network_interface {
    device_index         = 0
    network_interface_id = aws_network_interface.my_web_server_nic.id
  }

  tags = {
    Name = var.my_tag
  }  
}

# Install and enable an apache server


