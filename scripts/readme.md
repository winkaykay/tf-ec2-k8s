<<<<<<< HEAD

# 1. Remote to K8s Master
## Option 1 - Remote via SSH forwarding
eval $(ssh-agent)
ssh-add k8s-key-us-east-1.pem
ssh -A ubuntu@<Jump_Host_Public_IP>
ssh ubuntu@<K8S_Master_Private_IP>

## Option 2 - Remote via copy private key
scp -i my-key.pem my-key.pem ubuntu@<Jump_Host_Public_IP:~/
ssh -i my-key.pem ubuntu@<Jump_Host_Public_IP>
ssh -i my-key.pem ubuntu@<K8S_Master_Private_IP>

# 2. verify nodes
kubectl get nodes

kubectl label node k8s-wrk-1  node-role.kubernetes.io/worker=worker
=======
sudo kubeadm join <private-ip-of-control-plane>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash> --cri-socket "unix:///run/containerd/containerd.sock" --v=5





eval $(ssh-agent)
ssh-add k8s-key-us-east-1.pem

ssh -A ubuntu@<Jump_Host_Public_IP>


sudo snap install aws-cli --classic

aws ec2 describe-instances --filters "Name=tag:Name,Values=k8s_msr_1" \
  --query "Reservations[*].Instances[*].PrivateIpAddress" \
  --output text --region us-east-1

ssh ubuntu@<K8S_Master_Private_IP>


scp -i my-key.pem my-key.pem ubuntu@<remote-server-ip>:/home/ubuntu/

>>>>>>> a5e3f25 (initial commit)
