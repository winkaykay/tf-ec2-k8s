# 1. Remote to K8s Master
## Option 1 - Remote via SSH forwarding
eval $(ssh-agent)
ssh-add k8s-key-us-east-1.pem
ssh -A ec2-user@<Jump_Host_Public_IP>
ssh ec2-user@<K8S_Master_Private_IP>

## Option 2 - Remote via copy private key
scp -i my-key.pem my-key.pem ec2-user@<Jump_Host_Public_IP:~/
ssh -i my-key.pem ec2-user@<Jump_Host_Public_IP>
ssh -i my-key.pem ec2-user@<K8S_Master_Private_IP>

# 2. verify nodes
kubectl get nodes

kubectl label node k8s-wrk-1  node-role.kubernetes.io/worker=worker


curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
chmod 700 get_helm.sh
./get_helm.sh

#Install aws-load-balancer controller
helm repo add eks https://aws.github.io/eks-charts
helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system --set clusterName=kubernetes 


kubectl patch node k8s-wrk-1 -p '{"spec":{"providerID":"aws:///us-east-1/i-004be7d5f0bc03edf"}}'
kubectl patch node k8s-wrk-2 -p '{"spec":{"providerID":"aws:///us-east-1/i-072a7c3eb4a689e8c"}}'

