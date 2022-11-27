variable "name" { default = "dynamic-aws-creds-operator" }
variable "region" { default = "us-east-1" }
variable "path" { default = "../vault-admin-workspace/terraform.tfstate" }
variable "ttl" { default = "1" }

terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}

data "terraform_remote_state" "admin" {
  backend = "local"

  config = {
    path = var.path
  }
}

data "vault_aws_access_credentials" "creds" {
  backend = data.terraform_remote_state.admin.outputs.backend
  role    = data.terraform_remote_state.admin.outputs.role
}

provider "aws" {
  region     = var.region
  access_key = data.vault_aws_access_credentials.creds.access_key
  secret_key = data.vault_aws_access_credentials.creds.secret_key
}

# 1 create VPC
resource "aws_vpc" "production-vpc" {
  cidr_block = "10.0.0.0/16"
  
   tags = {
    Name = "production"
  }
}
# 2 create internet gateway 
resource "aws_internet_gateway" "production-gateway" {
  vpc_id = aws_vpc.production-vpc.id # .id == id

}



# 3 custom route table
resource "aws_route_table" "production-route-table" {
  vpc_id = aws_vpc.production-vpc.id # here we reference the prod-vpc

  route {
    cidr_block = "0.0.0.0/0" # send all traffic to wherever route points
    gateway_id = aws_internet_gateway.production-gateway.id
  }

  route {
    ipv6_cidr_block        = "::/0" # equivelent to above but for IPV6
    gateway_id = aws_internet_gateway.production-gateway.id
  }

  tags = {
    Name = "production"
  }
}


# 4 create subnet 
## this is where web server will reside 

resource "aws_subnet" "subnet-prod" {
  vpc_id     = aws_vpc.production-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a" # within region

  tags = {
    Name = "prod-subnet"
  }
}

# 5 assoc subnet with route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-prod.id
  route_table_id = aws_route_table.production-route-table.id
}


# 6 create security group to allow port 22(ssh) 80 443
## this looks similar to k8 networkPolicy resource

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.production-vpc.id

  ingress {
    description      = "HTTP"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
ingress {
    description      = "HTTPS"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
 


ingress {
    description      = "SSH"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_web"
  }
}



# 7 create a network interface with an IP in the subnet that was created in 4
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-prod.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

# 8 assign an elastic IP to the network interface created in 7
## for public access
# needs to have a gateway created prior to EIP

resource "aws_eip" "one" {
  vpc                       = true #- (Optional) Boolean if the EIP is in a VPC or not. Defaults to true unless the region supports EC2-Classic.
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.production-gateway,aws_instance.web-server] # needs to reference the whole object
  
}
# 9 create an ubuntu server and install enable/apache


resource "aws_instance" "web-server" {
  ami           = "ami-08c40ec9ead489470"
  instance_type = "t2.micro"
  availability_zone = "us-east-1a" # remember to use same AZ
  key_name = "terraform"

   network_interface {
    network_interface_id = aws_network_interface.web-server-nic.id
    device_index         = 0
  }

  user_data = <<-EOF
                 #!/bin/bash
                 sudo apt update -y
                 sudo apt install apache2 -y
                 sudo systemctl start apache2
                 sudo bash -c 'echo YOU DID IT BROTHER > /var/www/html/index.html'
                 EOF

  tags = {
    "Name" = "web-server-final"

}
}
