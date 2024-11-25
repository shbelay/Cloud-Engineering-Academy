provider "aws" {
  region = "us-east-2"
}

#VPC
resource "aws_vpc" "main" {
  cidr_block = "192.168.0.0/16"
  tags = {
    name = "main-tf-vpc"
  }
}

#Subnet 1
resource "aws_subnet" "subnet1" {
  vpc_id = aws_vpc.main.id
  cidr_block = "192.168.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    name = "Subnet 1"
  }
}

#Subnet 2
resource "aws_subnet" "subnet2" {
  vpc_id = aws_vpc.main.id
  cidr_block = "192.168.2.0/24"
  availability_zone = "us-east-2a"

  tags = {
    name = "Subnet2"
  }
}

#Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    name = "main-vpc-igw"
  }
}

#Route Table
resource "aws_route_table" "aws_route_table" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    name = "main-route-table"
  }
}

#Route Table Association Subnet 1
resource "aws_route_table_association" "routetable1" {
  subnet_id = aws_subnet.subnet1.id
  route_table_id = aws_route_table.aws_route_table.id
}

#Route Table Association Subnet 2
resource "aws_route_table_association" "routetable2" {
  subnet_id = aws_subnet.subnet2.id
  route_table_id = aws_route_table.aws_route_table.id
}