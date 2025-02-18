#!/bin/bash 
 
sudo hostnamectl set-hostname workernode
 
echo "CONTROL_PLANE_IP=${CONTROL_PLANE_IP}" | sudo tee -a /etc/environment
source /etc/environment
   
# Fetch the join command from the control plane node
while true; do
  curl -O http://$CONTROL_PLANE_IP:8080/join-command.sh
  if [ -f "join-command.sh" ]; then
    echo "Successfully fetched join-command.sh from $CONTROL_PLANE_IP"
    break
  else
    echo "Failed to fetch join-command.sh, retrying in 10 seconds..."
    sleep 10
  fi
done


# Make the join command script executable
chmod +x join-command.sh

# Execute the join command script
sudo ./join-command.sh