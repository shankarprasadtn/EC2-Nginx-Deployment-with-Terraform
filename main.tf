provider "aws" {
  region = var.aws_region
}

# Fetch the latest Ubuntu 20.04 LTS AMI in the given region
data "aws_ami" "ubuntu_20_04" {
  most_recent = true
  owners      = ["099720109477"] # Canonical ID

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Security group allowing HTTP and SSH
resource "aws_security_group" "nginx_sg" {
  name        = "nginx_web_sg"
  description = "Allow HTTP and SSH inbound traffic"
  vpc_id      = data.aws_vpc.default.id

  ingress {
    description = "HTTP from anywhere"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH from anywhere"
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
    Name = "nginx_web_sg"
  }
}

# EC2 instance running Nginx
resource "aws_instance" "nginx_server" {
  ami           = data.aws_ami.ubuntu_20_04.id
  instance_type = "t2.micro"
  
  vpc_security_group_ids = [aws_security_group.nginx_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update
              apt-get install -y nginx
              echo "Welcome to the Terraform-managed Nginx Server on Ubuntu" > /var/www/html/index.html
              systemctl start nginx
              systemctl enable nginx
              EOF

  user_data_replace_on_change = true

  tags = {
    Name = "Terraform-Nginx-Server"
  }
}
