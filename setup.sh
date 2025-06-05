#!/bin/bash

# Exit script on any error
set -e

# Update and install necessary packages
yum update -y
yum install -y python3 nginx git

# Enable and start nginx
systemctl enable nginx
systemctl start nginx

# Clean up any previous clone
rm -rf /home/ec2-user/word-reverser

# Clone public repo
cd /home/ec2-user
git clone https://github.com/Conor9720/terraform-word-reverser.git word-reverser

# Install dependencies
cd /home/ec2-user/word-reverser
pip3 install fastapi uvicorn
if [ -f requirements.txt ]; then
    pip3 install -r requirements.txt
fi

# Create a systemd service to ensure uvicorn starts and restarts reliably
cat <<EOF > /etc/systemd/system/wordreverser.service
[Unit]
Description=Word Reverser FastAPI App
After=network.target

[Service]
User=ec2-user
WorkingDirectory=/home/ec2-user/word-reverser
ExecStart=/usr/bin/python3 -m uvicorn main:app --host 0.0.0.0 --port 8000
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Start the app via systemd
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable wordreverser
systemctl start wordreverser

# Replace default nginx HTML with frontend
if [ -f /home/ec2-user/word-reverser/index.html ]; then
    cp /home/ec2-user/word-reverser/index.html /usr/share/nginx/html/index.html
fi

# Configure nginx as reverse proxy
cat <<EOF > /etc/nginx/conf.d/word-reverser.conf
server {
    listen 80;

    location / {
        root /usr/share/nginx/html;
        index index.html;
    }

    location /reverse {
        proxy_pass http://127.0.0.1:8000/reverse;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
    }
}
EOF

# Restart nginx to apply config
systemctl restart nginx
