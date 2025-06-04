#!/bin/bash

# Update and install necessary packages
yum update -y
yum install -y python3 nginx git

# Enable and start nginx
systemctl enable nginx
systemctl start nginx

# Install FastAPI, Uvicorn, and any requirements
pip3 install fastapi uvicorn

# Clean up any previous clone
rm -rf /home/ec2-user/word-reverser

# Clone your GitHub repo
cd /home/ec2-user
git clone https://github.com/Conor9720/terraform-word-reverser.git word-reverser

# Optional: Install dependencies if you have a requirements.txt
cd /home/ec2-user/word-reverser
if [ -f requirements.txt ]; then
    pip3 install -r requirements.txt
fi

# Run the FastAPI app with uvicorn in the background on port 8000
nohup uvicorn main:app --host 0.0.0.0 --port 8000 &


# Replace the default nginx HTML with your frontend (if included)
if [ -f /home/ec2-user/word-reverser/index.html ]; then
    cp /home/ec2-user/word-reverser/index.html /usr/share/nginx/html/index.html
fi

# Configure Nginx to reverse proxy to FastAPI
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

# Restart nginx to apply new config
systemctl restart nginx
