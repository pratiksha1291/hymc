provider "aws" {
    region ="ap-south-1"
    profile = "lwprofile"
  
}

resource "aws_vpc" "myvpc1" {
  cidr_block       = "192.168.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "pratvpc"
  }
}

resource "aws_subnet" "subnet1" {
  vpc_id     = aws_vpc.myvpc1.id
  cidr_block = "192.168.0.0/24"
  availability_zone = "ap-south-1a"
  map_public_ip_on_launch = true

   tags = {
    Name = "1stPublicSubnet"
  }
}

resource "aws_subnet" "subnet2" {
  vpc_id     = aws_vpc.myvpc1.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "ap-south-1b"
  
  tags = {
    Name = "2ndPrivateSubnet"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.myvpc1.id

  tags = {
    Name = "gateway"
  }
}

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.myvpc1.id

   tags = {
    Name = "route_table"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet1.id
  route_table_id = aws_route_table.r.id
}

resource "aws_route" "b" {
  route_table_id = aws_route_table.r.id
  destination_cidr_block ="0.0.0.0/0"
  gateway_id     = aws_internet_gateway.gw.id
}

resource "tls_private_key" "mykey"{
 algorithm = "RSA"
}

module "key_pair"{
 source ="terraform-aws-modules/key-pair/aws"

 key_name = "new_key"
 public_key = tls_private_key.mykey.public_key_openssh
}

resource "aws_security_group" "new_sg" {
  name        = "allow_tls"
  description = "Allow TLS inbound traffic"
  vpc_id      = aws_vpc.myvpc1.id

  ingress {
    description = "ssh"
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  
  ingress {
    description = "http"
    from_port   = 0
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
    Name ="sgforWordPress"
  }
}

resource "aws_instance" "os1" {
  ami           = "ami-7e257211"
  instance_type = "t2.micro"
  key_name = "new_key"
  vpc_security_group_ids =[aws_security_group.new_sg.id]
  subnet_id = aws_subnet.subnet1.id
 

  tags = {
    Name = "wordpress_instance"
  }
}

resource "aws_security_group" "new_sg2" {
  name        = "sg_mysql"
  description = "Allow MYSQL"
  vpc_id      = aws_vpc.myvpc1.id

  ingress {
    description = "MYSQL/Aurora"
    from_port   = 0
    to_port     = 3306
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
    Name ="sgformysql"
  }
}

resource "aws_instance" "os2" {
  ami           = "ami-08706cb5f68222d09"
  instance_type = "t2.micro"
  key_name = "new_key"
  vpc_security_group_ids =[aws_security_group.new_sg2.id]
  subnet_id = aws_subnet.subnet2.id
 

  tags = {
    Name = "mysql_instance"
  }
}
