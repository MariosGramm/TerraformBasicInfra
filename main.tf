terraform {
  required_providers {
    aws = {
        source  = "hashicorp/aws"
        version = "~> 5.0"
    }
  }
}

provider "aws" {
    region     = var.region
    access_key = var.access_key
    secret_key = var.secret_key
}

#VPC 

resource "aws_vpc" "my_vpc" {
    cidr_block = "10.0.0.0/16"

    tags ={
        Name = "Our VPC"
    }
}

#Subnet 

resource "aws_subnet" "my_subnet" {
    vpc_id            = aws_vpc.my_vpc.id
    cidr_block        = "10.0.0.0/24"
    availability_zone = "us-east-1a"

    tags = {
      Name = "Our Subnet"
    }
  
}

#Internet Gateway

resource "aws_internet_gateway" "my_ig" {
    vpc_id = aws_vpc.my_vpc.id

    tags = {
      name = "Our Internet Gateway"
    }

  
}

#Route Table

resource "aws_route_table" "my_rt" {
    vpc_id = aws_vpc.my_vpc.id

    route {
        cidr_block = "0.0.0.0/0"    #default route
        gateway_id = aws_internet_gateway.my_ig.id
    }
  
    

    tags = {
      name = "Our Route Table"
    }
}

#Route Table association with Subnet

resource "aws_route_table_association" "rta" {
    subnet_id      = aws_subnet.my_subnet.id
    route_table_id = aws_route_table.my_rt.id
    
    

}

#Security Group

resource "aws_security_group" "my_sg" {
    description = "Web Traffic Allowance"
    vpc_id      = aws_vpc.my_vpc.id

    ingress {
        description = "SSH"
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTPS"
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        description = "HTTP"
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"] 
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = -1
        cidr_blocks = ["0.0.0.0/0"] 
    }

    tags = {
        Name = "Our Security Group"

    }
  
}

#Νetwork interface 

resource "aws_network_interface" "my_nic" {
  subnet_id       = aws_subnet.my_subnet.id
  private_ips     = ["10.0.0.50"]
  security_groups = [aws_security_group.my_sg.id]

}

#Elastic IP Adress

resource "aws_eip" "one" {
  network_interface         = aws_network_interface.my_nic.id
  associate_with_private_ip = "10.0.0.50"
  depends_on                = [aws_instance.Ubuntu_server]

}

# EC2 Instance

resource "aws_instance" "Ubuntu_server" {
    ami                         = "ami-0866a3c8686eaeeba"
    instance_type               = "t2.micro"
    availability_zone           = "us-east-1a"
    key_name                    = "my-kpair"  
    
   
    network_interface {
      network_interface_id = aws_network_interface.my_nic.id
      device_index         = 0
    }

    user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemctl start apache2
              sudo bash -c 'echo This is a test page for my EC2 Instance >/var/www/html/index.html'
 
             EOF


     tags = {
         name = "Instance running on Ubuntu Server"
     } 




  
}

output "vpc_id" {
    value = aws_vpc.my_vpc.id
    description = "The ID of our VPC"
  
}


  
