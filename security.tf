# Create Security Group for Jump Host
resource "aws_security_group" "jump_host_sg" {
  name   = "Jump Host Ports"
  vpc_id = aws_vpc.k8s_vpc.id

  # Allow SSH from anywhere (You should restrict this to a trusted IP range)
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Security Group for Kubernetes Cluster (private instances)
resource "aws_security_group" "k8s_sg" {
  name   = "K8S Ports"
  vpc_id = aws_vpc.k8s_vpc.id

  # Allow SSH from Jump Host
  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.jump_host_sg.id]
  }

  ingress {
    from_port       = 6443
    to_port         = 6443
    protocol        = "tcp"
    security_groups = [aws_security_group.jump_host_sg.id]
  }

  # Allow all internal traffic within VPC
  ingress {
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}

