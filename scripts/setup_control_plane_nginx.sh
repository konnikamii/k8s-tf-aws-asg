#!/bin/bash

# Install and configure nginx to serve files from the $API_DIR directory
sudo apt-get update -y
sudo apt-get install -y nginx

cat <<EOF | sudo tee /etc/nginx/sites-available/api
server {
    listen 8080;
    server_name localhost;

    location / {
        root $API_DIR;
        autoindex on;
        allow all;
    }
}
EOF

sudo ln -s /etc/nginx/sites-available/api /etc/nginx/sites-enabled/
sudo systemctl enable nginx
sudo systemctl restart nginx 


# Health check script for nginx
cat <<EOF | sudo tee /usr/local/bin/check_nginx.sh
#!/bin/bash
if ! systemctl is-active --quiet nginx; then
  systemctl restart nginx
fi
EOF

sudo chmod +x /usr/local/bin/check_nginx.sh

# Health check service for nginx
cat <<EOF | sudo tee /etc/systemd/system/check_nginx.service
[Unit]
Description=Check Nginx Service

[Service]
ExecStart=/usr/local/bin/check_nginx.sh
EOF

cat <<EOF | sudo tee /etc/systemd/system/check_nginx.timer
[Unit]
Description=Run Check Nginx Service every minute

[Timer]
OnBootSec=1min
OnUnitActiveSec=1min
Unit=check_nginx.service

[Install]
WantedBy=timers.target
EOF
 
sudo systemctl daemon-reload
sudo systemctl enable check_nginx.timer
sudo systemctl start check_nginx.timer
