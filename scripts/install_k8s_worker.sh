#!/bin/bash
set -e

# Define the worker number (can be passed as an argument or set dynamically)


# Check if worker_number is provided
if [[ -z "$worker_number" ]]; then
   worker_number=1
fi
hostname k8s-wrk-${worker_number}
# Set the hostname
echo  $(hostname -s) > /etc/hostname

# Enable iptables Bridged Traffic on all the Nodes

cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter
sleep 2

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
sleep 2

## Disable swap on all the Nodes
sudo swapoff -a
(crontab -l 2>/dev/null; echo "@reboot /sbin/swapoff -a") | crontab - || true
sleep 2

# Install dependencies
sudo apt-get update -y
sleep 2
sudo apt-get install -y software-properties-common gpg curl unzip apt-transport-https ca-certificates
sleep 2

#Install CRI-O Runtime On All The Nodes
curl -fsSL https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/Release.key |
    gpg --dearmor -o /etc/apt/keyrings/cri-o-apt-keyring.gpg
echo "deb [signed-by=/etc/apt/keyrings/cri-o-apt-keyring.gpg] https://pkgs.k8s.io/addons:/cri-o:/prerelease:/main/deb/ /" |
    tee /etc/apt/sources.list.d/cri-o.list

sudo apt-get update -y
sudo apt-get install -y cri-o

sudo systemctl daemon-reload
sudo systemctl enable crio --now
sudo systemctl start crio.service

## Install crictl

VERSION="v1.30.0"
wget https://github.com/kubernetes-sigs/cri-tools/releases/download/$VERSION/crictl-$VERSION-linux-amd64.tar.gz
sudo tar zxvf crictl-$VERSION-linux-amd64.tar.gz -C /usr/local/bin
rm -f crictl-$VERSION-linux-amd64.tar.gz


# Install Kubeadm & Kubelet & Kubectl on all Nodes

KUBERNETES_VERSION=1.30

sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
sleep 2

echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v$KUBERNETES_VERSION/deb/ /" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sleep 2

sudo apt-get update -y
sleep 2

sudo apt-get install -y kubelet kubeadm kubectl
sleep 2

sudo apt-mark hold kubelet kubeadm kubectl
sleep 2

sudo apt-get install -y jq
local_ip="$(ip --json addr show eth0 | jq -r '.[0].addr_info[] | select(.family == "inet") | .local')"
cat > /etc/default/kubelet << EOF
KUBELET_EXTRA_ARGS=--node-ip=$local_ip
EOF
sleep 2

echo "Kubernetes setup completed."

# Install AWS CLI v2
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
sleep 2

# to insure the join command start when the installion of master node is done.
sleep 1m

# Fetch Join Command from S3
aws s3 cp s3://${bucket_name}/join_command.sh /home/ubuntu/join_command.sh
sleep 2

# Execute Join Command
chmod +x /home/ubuntu/join_command.sh
sudo /home/ubuntu/join_command.sh
  