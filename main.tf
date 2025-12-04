terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2"
}

# 1. Find Amazon Linux 2 AMI
data "aws_ami" "amazon_linux_2" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
}

# --- NETWORKING ---
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = { Name = "devsecops-sydney-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-southeast-2a"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public_rt.id
}

# --- SECURITY GROUP (HARDENED) ---
resource "aws_security_group" "web_sg" {
  name        = "web-sg-https-only"
  description = "Allow HTTPS and SSH only"
  vpc_id      = aws_vpc.main.id

  # HTTPS (443) - ALLOWED
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SSH (22) - ALLOWED
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # NOTE: Port 80 is missing, so it is BLOCKED by default.

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# --- COMPUTE ---
resource "aws_instance" "web" {
  ami           = data.aws_ami.amazon_linux_2.id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public.id
  security_groups = [aws_security_group.web_sg.id]

  # Startup Script: Install Nginx + Generate SSL Cert + Configure HTTPS
  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              amazon-linux-extras install nginx1 -y
              
              # 1. Generate a Self-Signed SSL Certificate
              mkdir -p /etc/nginx/ssl
              openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
                -keyout /etc/nginx/ssl/nginx-selfsigned.key \
                -out /etc/nginx/ssl/nginx-selfsigned.crt \
                -subj "/C=AU/ST=NSW/L=Sydney/O=DevSecOps/OU=IT/CN=localhost"

              # 2. Configure Nginx to use SSL
              # We create a new config file for HTTPS
              cat <<EOT > /etc/nginx/conf.d/ssl.conf
              server {
                  listen 443 ssl;
                  server_name _;
                  
                  ssl_certificate /etc/nginx/ssl/nginx-selfsigned.crt;
                  ssl_certificate_key /etc/nginx/ssl/nginx-selfsigned.key;
                  
                  location / {
                      root /usr/share/nginx/html;
                      index index.html index.htm;
                  }
              }
              EOT

              # 3. Create a Landing Page
              echo "<h1>SECURE CONNECTION HAS BEEN ESTABLISHED (HTTPS)</h1>" > /usr/share/nginx/html/index.html
              
              # 4. Start Nginx
              systemctl start nginx
              systemctl enable nginx
              EOF

  tags = { Name = "DevSecOps-HTTPS-Server" }
}

# --- OUTPUT ---
output "website_url" {
  # Note: changing http to https in the output
  value = "https://${aws_instance.web.public_ip}"
}