resource "aws_iam_role" "control_plane_role" {
  name = "K8SControlPlaneRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "s3_write_policy" {
  name        = "K8SControlPlaneS3Write"
  description = "Allows the control plane to upload join command to S3"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject"]
      Resource = ["arn:aws:s3:::k8s-${random_string.s3name.result}", "arn:aws:s3:::k8s-${random_string.s3name.result}/*"]

    }]
  })
}

resource "aws_iam_role_policy_attachment" "attach_s3_write_policy" {
  role       = aws_iam_role.control_plane_role.name
  policy_arn = aws_iam_policy.s3_write_policy.arn
}

resource "aws_iam_instance_profile" "control_plane_profile" {
  name = "K8SControlPlaneProfile"
  role = aws_iam_role.control_plane_role.name
}

resource "aws_iam_role" "worker_node_role" {
  name = "K8SWorkerNodesRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_policy" "s3_policy" {
  name        = "K8SWorkerNodesS3Read"
  description = "Allows read access to S3"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect   = "Allow",
      Action   = ["s3:ListBucket", "s3:GetObject"],
      Resource = ["arn:aws:s3:::k8s-${random_string.s3name.result}", "arn:aws:s3:::k8s-${random_string.s3name.result}/*"]
    }]
  })
  depends_on = [
    random_string.s3name
  ]

}

resource "aws_iam_role_policy_attachment" "attach_s3_policy" {
  role       = aws_iam_role.worker_node_role.name
  policy_arn = aws_iam_policy.s3_policy.arn
}

resource "aws_iam_instance_profile" "worker_node_profile" {
  name = "K8SWorkerNodeProfile"
  role = aws_iam_role.worker_node_role.name
}
