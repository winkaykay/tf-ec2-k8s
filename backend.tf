terraform {
  backend "remote" {
    organization = "hello-bag-hub"

    workspaces {
      name = "k8s-ec2-cluster"
    }
  }
}
