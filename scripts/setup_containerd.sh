#!/bin/bash

DOWNLOAD_DIR="/root/downloads" 
CONTAINERD_VERSION="2.0.0"
RUNC_VERSION="v1.2.5"
ARCH="amd64" 
CNI_PLUGINS_VERSION="1.6.2" 
NERDCTL_VERSION="2.0.3"
CRICTL_VERSION="1.32.0"
CONFIG_FILE="/etc/containerd/config.toml"
# Persist environment variables across reboots 
echo "DOWNLOAD_DIR=${DOWNLOAD_DIR}" | sudo tee -a /etc/environment
echo "CONTAINERD_VERSION=${CONTAINERD_VERSION}" | sudo tee -a /etc/environment
echo "RUNC_VERSION=${RUNC_VERSION}" | sudo tee -a /etc/environment
echo "ARCH=${ARCH}" | sudo tee -a /etc/environment
echo "CNI_PLUGINS_VERSION=${CNI_PLUGINS_VERSION}" | sudo tee -a /etc/environment
echo "NERDCTL_VERSION=${NERDCTL_VERSION}" | sudo tee -a /etc/environment
echo "CRICTL_VERSION=${CRICTL_VERSION}" | sudo tee -a /etc/environment
echo "CONFIG_FILE=${CONFIG_FILE}" | sudo tee -a /etc/environment
source /etc/environment

sudo mkdir -p $DOWNLOAD_DIR

sudo wget -P $DOWNLOAD_DIR https://github.com/containerd/containerd/releases/download/v${CONTAINERD_VERSION}/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz
sudo tar -C /usr/local -xvf $DOWNLOAD_DIR/containerd-${CONTAINERD_VERSION}-linux-${ARCH}.tar.gz

# Download and create containerd service 
sudo wget -P /usr/local/lib/systemd/system https://raw.githubusercontent.com/containerd/containerd/main/containerd.service 
sudo systemctl daemon-reload
sudo systemctl enable --now containerd
 
# Download and install runc
sudo wget -P $DOWNLOAD_DIR https://github.com/opencontainers/runc/releases/download/${RUNC_VERSION}/runc.${ARCH}  
sudo install -m 755 $DOWNLOAD_DIR/runc.${ARCH} /usr/local/sbin/runc

# Download and install cni-plugins
sudo wget -P $DOWNLOAD_DIR https://github.com/containernetworking/plugins/releases/download/v${CNI_PLUGINS_VERSION}/cni-plugins-linux-${ARCH}-v${CNI_PLUGINS_VERSION}.tgz
sudo mkdir -p /opt/cni/bin
sudo tar -C /opt/cni/bin -xvf $DOWNLOAD_DIR/cni-plugins-linux-${ARCH}-v${CNI_PLUGINS_VERSION}.tgz

# Configure containerd
sudo mkdir -p /etc/containerd/
sudo containerd config default | sudo tee $CONFIG_FILE
if grep -q "SystemdCgroup" "$CONFIG_FILE"; then
  echo "SystemdCgroup found. Replacing its value with true."
  sudo sed -i 's/^\s*SystemdCgroup\s*=.*/SystemdCgroup = true/' "$CONFIG_FILE"
else
  echo "SystemdCgroup not found. Inserting the block before [plugins] section."
  sudo sed -i "/tls_key_file = ''/a\\
    [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc]\\
      [plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]\\
        SystemdCgroup = true\\
              
" "$CONFIG_FILE"
fi 
sudo sed -i "/plugins.'io.containerd.grpc.v1.cri']/a\    sandbox_image = 'k8s.gcr.io/pause:3.10'" /etc/containerd/config.toml
# rm -rf $CONFIG_FILE
sudo systemctl restart containerd

# Download and install nerdctl  
sudo wget -P $DOWNLOAD_DIR https://github.com/containerd/nerdctl/releases/download/v${NERDCTL_VERSION}/nerdctl-${NERDCTL_VERSION}-linux-${ARCH}.tar.gz
sudo tar -C /usr/local/bin -xvf $DOWNLOAD_DIR/nerdctl-${NERDCTL_VERSION}-linux-${ARCH}.tar.gz


# Download and install crictl  
sudo wget -P $DOWNLOAD_DIR https://github.com/kubernetes-sigs/cri-tools/releases/download/v${CRICTL_VERSION}/crictl-v${CRICTL_VERSION}-linux-${ARCH}.tar.gz
sudo tar -C /usr/local/bin -xvf $DOWNLOAD_DIR/crictl-v${CRICTL_VERSION}-linux-${ARCH}.tar.gz

# Create crictl.yaml config file
sudo tee /etc/crictl.yaml > /dev/null <<EOF
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 2
debug: true
pull-image-on-create: false
EOF


# Troubleshooting
# sudo systemctl status containerd
# runc -v
# ctr -v
# nerdctl -v
# crictl -v 
