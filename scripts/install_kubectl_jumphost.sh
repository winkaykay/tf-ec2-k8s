#!/bin/bash
set -e


# Install dependencies
sudo apt-get update -y
sleep 2
sudo apt-get install -y software-properties-common gpg curl unzip apt-transport-https ca-certificates
sleep 2

# Install Kubeadm & Kubelet & Kubectl on all Nodes

KUBERNETES_VERSION=1.30

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sleep 2

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sleep 2

sudo apt-get update -y
sleep 2

sudo apt-get install -y kubectl
sleep 2

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install

# to insure the join command start when the installion of master node is done.
sleep 2m

mkdir /home/ubuntu/.kube
sudo aws s3 cp s3://${bucket_name}/config /home/ubuntu/.kube/config
sudo chown ubuntu:ubuntu /home/ubuntu/.kube/config


echo "Kubernetes setup completed."

  