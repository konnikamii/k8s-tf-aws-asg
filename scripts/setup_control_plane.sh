#!/bin/bash
  
sudo hostnamectl set-hostname controlplane

API_DIR="/var/www/api"
HELM_VERSION="3.17.1"
echo "API_DIR=${API_DIR}" | sudo tee -a /etc/environment
echo "HELM_VERSION=${HELM_VERSION}" | sudo tee -a /etc/environment
source /etc/environment
sudo mkdir -p $API_DIR
sudo chown -R www-data:www-data $API_DIR
sudo kubeadm init --pod-network-cidr=192.168.0.0/16 | tee $API_DIR/kubeadm-init.log

grep -A 1 "kubeadm join" $API_DIR/kubeadm-init.log > $API_DIR/join-command.sh
chmod +x $API_DIR/join-command.sh

for user in root ubuntu konnik; do
  home_dir=$(getent passwd "$user" | cut -d: -f6)
  echo "Setting up kubeconfig for $user at $home_dir/.kube/config"
  sudo mkdir -p "$home_dir/.kube"
  sudo cp -i /etc/kubernetes/admin.conf "$home_dir/.kube/config"
  sudo chown "$user:$user" "$home_dir/.kube/config"
done 
echo 'export KUBECONFIG=/root/.kube/config' | sudo tee -a /root/.bashrc
export KUBECONFIG=/root/.kube/config

# Wait for the Kubernetes API server to be ready
echo "Waiting for the Kubernetes API server to be ready..."
until kubectl get nodes &>/dev/null; do
  echo "Kubernetes API is not ready yet... retrying in 10 seconds."
  sleep 10
done 
sleep 5 
echo "Control plane node is Ready!"

# Install Calico networking
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/tigera-operator.yaml
kubectl create -f https://raw.githubusercontent.com/projectcalico/calico/v3.29.2/manifests/custom-resources.yaml


kubectl taint nodes --all node-role.kubernetes.io/control-plane-
 

# Download and install calicoctl 
sudo curl -L https://github.com/projectcalico/calico/releases/download/v3.29.2/calicoctl-linux-amd64 -o /usr/local/bin/calicoctl
sudo chmod +x /usr/local/bin/calicoctl

# Download and install metrics api 
sudo kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
kubectl patch deployment metrics-server -n kube-system --type='json' -p='[{"op": "add", "path": "/spec/template/spec/containers/0/args/-", "value": "--kubelet-insecure-tls"}]'
 
# Download and install helm
sudo wget -P $DOWNLOAD_DIR https://get.helm.sh/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz
sudo tar --strip-components=1 -C /usr/local/bin -xvf $DOWNLOAD_DIR/helm-v${HELM_VERSION}-linux-${ARCH}.tar.gz linux-amd64/helm
 

# kubectl create deployment nginx --image=nginx
# kubectl expose deployment nginx --port=80 --type=NodePort

# Cleanup cluster
# sudo kubeadm reset
# sudo rm -rf /etc/kubernetes/


# watch kubectl get pods -n calico-system
# kubectl get nodes -o wide
# nc 127.0.0.1 6443 -v
# cat /root/join-command.sh