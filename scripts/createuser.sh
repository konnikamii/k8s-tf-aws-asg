#!/bin/bash  

# Redirect output to log file
exec > >(tee -i /var/log/setup.log)
exec 2>&1

# Remove the restrictive options from the root's authorized_keys file
sed -i 's/no-port-forwarding,no-agent-forwarding,no-X11-forwarding,command="echo.*exit 142" //' /root/.ssh/authorized_keys

# Add a new user 'konnik' without setting a password
adduser --disabled-password --gecos "" konnik

# Create .ssh directory for 'konnik'
mkdir -p /home/konnik/.ssh
chmod 700 /home/konnik/.ssh

# Copy the authorized_keys from 'ubuntu' to 'konnik'
cp /home/ubuntu/.ssh/authorized_keys /home/konnik/.ssh/authorized_keys
chmod 600 /home/konnik/.ssh/authorized_keys
chown -R konnik:konnik /home/konnik/.ssh

# Give root privileges to the new user 'konnik'
usermod -aG sudo konnik