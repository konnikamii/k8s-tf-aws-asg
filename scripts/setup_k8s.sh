#!/bin/bash
  
# sudo hostnamectl set-hostname controlplane
DOWNLOAD_DIR="/root/downloads" 
INSTALL_DIR="/usr/local/bin" 
SERVICE_DIR="/usr/local/lib/systemd/system" 
LATEST_KUBECTL_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt) 
ARCH="amd64"

# Persist environment variables across reboots
echo "DOWNLOAD_DIR=${DOWNLOAD_DIR}" | sudo tee -a /etc/environment
echo "INSTALL_DIR=${INSTALL_DIR}" | sudo tee -a /etc/environment
echo "SERVICE_DIR=${SERVICE_DIR}" | sudo tee -a /etc/environment
echo "LATEST_KUBECTL_VERSION=${LATEST_KUBECTL_VERSION}" | sudo tee -a /etc/environment
echo "ARCH=${ARCH}" | sudo tee -a /etc/environment
source /etc/environment

# sysctl network settings for packet forwarding (persist across reboots)
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
EOF
sudo sysctl --system

sudo swapoff -a

# Download and install kubectl  
curl -Lo $DOWNLOAD_DIR/kubectl "https://dl.k8s.io/release/${LATEST_KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl" 
curl -Lo $DOWNLOAD_DIR/kubectl.sha256 "https://dl.k8s.io/release/${LATEST_KUBECTL_VERSION}/bin/linux/${ARCH}/kubectl.sha256" 
echo "$(cat $DOWNLOAD_DIR/kubectl.sha256)  $DOWNLOAD_DIR/kubectl" | sha256sum --check  
sudo install -o root -g root -m 0755 $DOWNLOAD_DIR/kubectl $INSTALL_DIR/kubectl


# Download and install kubelet
curl -Lo $DOWNLOAD_DIR/kubelet "https://dl.k8s.io/release/${LATEST_KUBECTL_VERSION}/bin/linux/${ARCH}/kubelet"
curl -Lo $DOWNLOAD_DIR/kubelet.sha256 "https://dl.k8s.io/release/${LATEST_KUBECTL_VERSION}/bin/linux/${ARCH}/kubelet.sha256"
echo "$(cat $DOWNLOAD_DIR/kubelet.sha256)  $DOWNLOAD_DIR/kubelet" | sha256sum --check
sudo install -o root -g root -m 0755 $DOWNLOAD_DIR/kubelet $INSTALL_DIR/kubelet


# Download and install kubeadm
curl -Lo $DOWNLOAD_DIR/kubeadm "https://dl.k8s.io/release/${LATEST_KUBECTL_VERSION}/bin/linux/${ARCH}/kubeadm"
curl -Lo $DOWNLOAD_DIR/kubeadm.sha256 "https://dl.k8s.io/release/${LATEST_KUBECTL_VERSION}/bin/linux/${ARCH}/kubeadm.sha256"
echo "$(cat $DOWNLOAD_DIR/kubeadm.sha256)  $DOWNLOAD_DIR/kubeadm" | sha256sum --check
sudo install -o root -g root -m 0755 $DOWNLOAD_DIR/kubeadm $INSTALL_DIR/kubeadm

# Create systemd service for kubelet
RELEASE_VERSION="v0.16.2"
sudo wget -P $SERVICE_DIR https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubelet/kubelet.service
sudo mkdir -p $SERVICE_DIR/kubelet.service.d
sudo wget -P $SERVICE_DIR/kubelet.service.d https://raw.githubusercontent.com/kubernetes/release/${RELEASE_VERSION}/cmd/krel/templates/latest/kubeadm/10-kubeadm.conf
sudo sed -i 's|ExecStart=/usr/bin/kubelet|ExecStart=/usr/local/bin/kubelet|g' $SERVICE_DIR/kubelet.service
sudo sed -i 's|ExecStart=/usr/bin/kubelet|ExecStart=/usr/local/bin/kubelet|g' $SERVICE_DIR/kubelet.service.d/10-kubeadm.conf
sudo systemctl daemon-reload
sudo systemctl enable --now kubelet
sudo systemctl restart kubelet

echo "Kubernetes setup completed successfully!!!" 
 

# Troubleshooting
# nc 127.0.0.1 6443 -v                      # Check if the control plane is listening on port 6443
# sysctl net.ipv4.ip_forward                # Check the value of the net.ipv4.ip_forward sysctl parameter (should be 1) 
# cat /etc/containerd/config.toml            # Check the contents of the containerd configuration file
  
# cat /var/log/setup.log
# tail -f /var/log/setup.log

# kubeadm version
# kubectl version --client
# kubelet --version
 

# sudo systemctl status kubelet 
# journalctl -xeu kubelet
# sudo journalctl -u kubelet -f


# watch kubectl get pods -n calico-system
# kubectl get pods
# cat /usr/local/lib/systemd/system/containerd.service
# cat /usr/local/lib/systemd/system/kubelet.service
# cat /usr/local/lib/systemd/system/kubelet.service.d/10-kubeadm.conf 


