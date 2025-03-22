
#****** VPC Start ******#

#VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block = "10.0.0.0/24"

  tags = {
    Name = "K8S VPC"
  }
}
# Generate Random AWS Zone
resource "random_shuffle" "az" {
  input        = ["${var.region}a", "${var.region}b", "${var.region}c", "${var.region}d", "${var.region}e"]
  result_count = 1
}

# Public Subnet
resource "aws_subnet" "k8s_public_subnet" {
  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = "10.0.0.0/27"
  availability_zone       = random_shuffle.az.result[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "K8S Public Subnet"
  }
}

# Private Subnet
resource "aws_subnet" "k8s_private_subnet" {
  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = "10.0.0.32/27"
  availability_zone = random_shuffle.az.result[0]

  tags = {
    Name = "K8S Private Subnet"
  }
}


# Internet Gateway
resource "aws_internet_gateway" "k8s_ig" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "K8S Internet Gateway"
  }
}

# Create Route Table for Public Subnet
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.k8s_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.k8s_ig.id
  }

  tags = {
    Name = "k8s-public-route-table"
  }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.k8s_public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}


# Create an Elastic IP (EIP)
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "k8s-eip"
  }
}

# Create a NAT Gateway in the Public Subnet:
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.k8s_public_subnet.id

  tags = {
    Name = "k8s-net"
  }
}

# Create a Route Table for Private Subnet
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.k8s_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
  tags = {
    Name = "k8s-private-route-table"
  }
}

# Associate the Route Table with the Private Subnet
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.k8s_private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

