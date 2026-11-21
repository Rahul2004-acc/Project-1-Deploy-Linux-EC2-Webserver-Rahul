
terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# 1. Existing VPC
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = false
}

# 2. Existing Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
}

# 3. Existing Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

# 4. Existing Public Route Table
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

# 5. Existing Route Table Association
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# 6. Existing Security Group
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP inbound traffic only"
  vpc_id      = aws_vpc.main.id

  # Allow HTTP traffic
  ingress {
    # description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "terraform-web-sg"
  }
}


# 7. Existing EC2 Web Server

resource "aws_instance" "webserver" {
  ami           = "ami-0037855f86d0a04b4"
  instance_type = "t3.micro"

  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  associate_public_ip_address = true

  # No key_name because the existing instance has no key pair

  user_data = <<-EOF
    #!/bin/bash
    yum install -y httpd
    systemctl start httpd
    systemctl enable httpd
    echo "<h1>WEB SERVER DEPLOYED BY TERRAFORM</h1>" > /var/www/html/index.html
  EOF

  tags = {
    Name        = "Terraform-Web-Server"
    Environment = "Development"
    ManagedBy   = "Terraform"
    Project     = "Branching-Policy"
  }

  lifecycle {
    ignore_changes = [user_data]
  }
}


