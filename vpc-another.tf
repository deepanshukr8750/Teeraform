# Define your AWS provider configuration

provider "aws" {
  region = "ap-south-1"
}

# Create a VPC

resource "aws_vpc" "my_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "my_vpc"
  }
}

# Create two public subnets

resource "aws_subnet" "public_subnet_01" {
  vpc_id             = aws_vpc.my_vpc.id
  cidr_block         = "10.0.1.0/24"
  availability_zone  = "ap-south-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-01"
  }
}

resource "aws_subnet" "public_subnet_02" {
  vpc_id             = aws_vpc.my_vpc.id
  cidr_block         = "10.0.2.0/24"
  availability_zone  = "ap-south-1b"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet-02"
  }
}

# Create two private subnets

resource "aws_subnet" "private_subnet_01" {
  vpc_id             = aws_vpc.my_vpc.id
  cidr_block         = "10.0.3.0/24"
  availability_zone  = "ap-south-1a"
  tags = {
    Name = "private-subnet-01"
  }
}

resource "aws_subnet" "private_subnet_02" {
  vpc_id             = aws_vpc.my_vpc.id
  cidr_block         = "10.0.4.0/24"
  availability_zone  = "ap-south-1b"
  tags = {
    Name = "privat-subnet-02"
  }
}

# Create a public route table

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "public-rt"
  }
}

# Create a private route table

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "private-rt"
  }
}

# Create associations between public subnets and the public route table

resource "aws_route_table_association" "public_subnet_association_01" {
  subnet_id      = aws_subnet.public_subnet_01.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_subnet_association_02" {
  subnet_id      = aws_subnet.public_subnet_02.id
  route_table_id = aws_route_table.public_rt.id
}

# Create associations between private subnets and the private route table

resource "aws_route_table_association" "private_subnet_association_01" {
  subnet_id      = aws_subnet.private_subnet_01.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_subnet_association_02" {
  subnet_id      = aws_subnet.private_subnet_02.id
  route_table_id = aws_route_table.private_rt.id
}

# Create a route for the public route table to the Internet Gateway

resource "aws_route" "public_route" {
  route_table_id         = aws_route_table.public_rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id

}

# Create an Internet Gateway

resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id
  tags = {
    Name = "IGW"
  }
}

# Create a single Elastic IP

resource "aws_eip" "nat_eip" {
  vpc = true
  depends_on = [aws_internet_gateway.my_igw]
  tags = {
    Name = "EIP"
  }
}

# Create a NAT Gateway

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_01.id # Use a public subnet for the NAT Gateway
  tags = {
    Name = "new-nat"
  }
}

# Create routes for the private route tables to the NAT Gateway

resource "aws_route" "private_route" {
  route_table_id         = aws_route_table.private_rt.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}


resource "aws_instance" "ec2_public" {
  ami   =  "ami-0f5ee92e2d63afc18"
  instance_type = "t2.micro"
  key_name  =  "Deepkey"
  subnet_id  = aws_subnet.public_subnet_01.id
  vpc_security_group_ids =  [aws_security_group.demo_sg.id]
  user_data   = file("userdata")

  tags = {
      Name = "public-ec2"

  }
}

resource "aws_instance" "ec2_private" {
  ami   =  "ami-0f5ee92e2d63afc18"
  instance_type = "t2.micro"
  key_name  =  "Deepkey"
  subnet_id  = aws_subnet.private_subnet_01.id
  vpc_security_group_ids =  [aws_security_group.demo_sg.id]
  

  tags = {
      Name = "private-ec2"

  }
}

# Security group


resource "aws_security_group" "demo_sg" {
  name        = "demo_sg"
  description = "allow ssh on 22 & http on port 80"
  vpc_id      = aws_vpc.my_vpc.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }



  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }
}


