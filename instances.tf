data "aws_ami" "latest_ami" {
  most_recent = true

  filter {
    name   = "name"
    values = ["al2023-ami-2023*-x86_64"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }

  owners = ["amazon"]
}


# Jump Host (Bastion) in Public Subnet
resource "aws_instance" "jump_host" {
  ami             = data.aws_ami.latest_ami.id# AWS AMI
  instance_type   = var.jump_host_instance_type
  key_name        = var.ami_key_pair_name
  subnet_id       = aws_subnet.k8s_public_subnet[0].id
  security_groups = [aws_security_group.jump_host_sg.id]
  iam_instance_profile = aws_iam_instance_profile.jump_host_profile.name
   user_data = templatefile("scripts/install_kubectl_jumphost.sh", { bucket_name = "k8s-${random_string.s3name.result}" })

  tags = {
    Name = "Jump-Host"
  }
  depends_on = [

    aws_instance.k8s_master_instance,
    aws_iam_instance_profile.jump_host_profile,
    aws_s3_bucket.k8s_join_bucket,
    random_string.s3name
  ]
}

# Kubernetes Master in Private Subnet
resource "aws_instance" "k8s_master_instance" {
  ami                         = data.aws_ami.latest_ami.id# AWS AMI
  subnet_id                   = aws_subnet.k8s_private_subnet[0].id
  instance_type               = var.instance_type
  key_name                    = var.ami_key_pair_name
  associate_public_ip_address = false
  security_groups             = [aws_security_group.k8s_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.control_plane_profile.name
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "16"
    delete_on_termination = true
  }
  tags = {
    Name = "k8s-msr-1"
  }

  user_data = templatefile("scripts/install_k8s_msr.sh", { bucket_name = "k8s-${random_string.s3name.result}" })

  depends_on = [

    aws_iam_instance_profile.control_plane_profile,
    aws_s3_bucket.k8s_join_bucket,
    aws_nat_gateway.nat,
    random_string.s3name
  ]
}


# Kubernetes Workers in Private Subnet
resource "aws_instance" "k8s_instance_wrk" {
  ami                         = data.aws_ami.latest_ami.id# AWS AMI
  count                       = var.number_of_worker
  subnet_id                   = aws_subnet.k8s_private_subnet[1].id
  instance_type               = var.instance_type
  key_name                    = var.ami_key_pair_name
  associate_public_ip_address = false
  security_groups             = [aws_security_group.k8s_sg.id]
  iam_instance_profile        = aws_iam_instance_profile.worker_node_profile.name
  root_block_device {
    volume_type           = "gp2"
    volume_size           = "16"
    delete_on_termination = true
  }
  tags = {
    Name = "k8s-wrk-${count.index + 1}"
  }
  user_data = templatefile("scripts/install_k8s_worker.sh", {

    bucket_name   = "k8s-${random_string.s3name.result}"
    worker_number = "${count.index + 1}"

  })


  depends_on = [

    aws_instance.k8s_master_instance,
    aws_iam_instance_profile.worker_node_profile,
    aws_s3_bucket.k8s_join_bucket,
    random_string.s3name
  ]
}

resource "random_string" "s3name" {
  length  = 9
  special = false
  upper   = false
  lower   = true
}

resource "aws_s3_bucket" "k8s_join_bucket" {
  bucket        = "k8s-${random_string.s3name.result}" # Change this to a globally unique name
  force_destroy = true

  tags = {
    Name        = "K8S Join Bucket"
    Environment = "Production"
  }
  depends_on = [
    random_string.s3name
  ]
}

# Enable encryption (optional, for security)
resource "aws_s3_bucket_server_side_encryption_configuration" "s3_encryption" {
  bucket = aws_s3_bucket.k8s_join_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}


# Block public access to the bucket
resource "aws_s3_bucket_public_access_block" "s3_block_public_access" {
  bucket = aws_s3_bucket.k8s_join_bucket.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}