
#****** VPC Start ******#

#VPC
resource "aws_vpc" "k8s_vpc" {
  cidr_block = var.cidr_block
  enable_dns_hostnames = true

  tags = {
    Name = var.vpc_name
  }
}
data "aws_availability_zones" "available" {
state = "available"
}

# Public Subnet
resource "aws_subnet" "k8s_public_subnet" {

  count =2

  vpc_id                  = aws_vpc.k8s_vpc.id
  cidr_block              = cidrsubnet(var.cidr_block, 8, count.index * 10)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.vpc_name}-public-${count.index + 1}"
    "kubernetes.io/role/elb"  = 1
    "kubernetes.io/cluster/kubernetes"	= "owned"
  }
  
}

# Private Subnet
resource "aws_subnet" "k8s_private_subnet" {

  count=2

  vpc_id            = aws_vpc.k8s_vpc.id
  cidr_block        = cidrsubnet(var.cidr_block, 8, 100 + count.index * 10)
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.vpc_name}-private-${count.index + 1}" 
  }
}

# Internet Gateway
resource "aws_internet_gateway" "k8s_ig" {
  vpc_id = aws_vpc.k8s_vpc.id

  tags = {
    Name = "${var.vpc_name}-igw" 
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
    Name = "${var.vpc_name}-public-rt"
  }
}

# Associate Route Table with Public Subnet
resource "aws_route_table_association" "public_assoc" {
  count=2 
  
  subnet_id      = aws_subnet.k8s_public_subnet[count.index].id
  route_table_id = aws_route_table.public_rt.id
}




# Create an Elastic IP (EIP)
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.vpc_name}-eip"
  }
}

# Create a NAT Gateway in the Public Subnet:
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.k8s_public_subnet[0].id

  tags = {
    Name = "${var.vpc_name}-nat"
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
    Name = "${var.vpc_name}-private-rt"
  }
}

# Associate the Route Table with the Private Subnet
resource "aws_route_table_association" "private_assoc" {

  count = 2

  subnet_id      = aws_subnet.k8s_private_subnet[count.index].id
  route_table_id = aws_route_table.private_rt.id
}

