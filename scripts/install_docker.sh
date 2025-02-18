#!/bin/bash
 
# Remove any existing Docker-related packages (Official Docker installation instructions)
for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do 
  sudo apt-get remove -y $pkg
done
 
# Add Docker's official GPG key: 
sudo apt-get update -y
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings 
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update -y
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 



# # V2
# # Install necessary packages for Docker
# sudo apt-get install -y apt-transport-https ca-certificates curl gnupg-agent software-properties-common
 
# # Add Docker's official GPG key
# curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# # Add Docker's official APT repository
# sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# # Update the package list again
# sudo apt-get update -y

# # Install Docker
# sudo apt-get install -y docker-ce docker-ce-cli containerd.io

# # Add the 'ubuntu' user to the 'docker' group
# sudo usermod -aG docker ubuntu
# sudo usermod -aG docker konnik

