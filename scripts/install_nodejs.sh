#!/bin/bash

# Install Node.js & npm
sudo apt-get install -y curl
curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
sudo apt-get install -y nodejs
# sudo apt install npm -y
sudo npm update npm -g

# Check
node -v
npm -v