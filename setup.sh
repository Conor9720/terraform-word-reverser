#!/bin/bash
exec > /var/log/user-data.log 2>&1
set -xe

echo "✅ Running setup.sh..."

# Wait for yum lock to clear
while sudo fuser /var/run/yum.pid >/dev/null 2>&1; do
  echo "⏳ Waiting for yum lock..."
  sleep 5
done

# Update and install necessary packages
yum update -y
yum install -y python3 git

# Install nginx via Amazon Linux Extras
amazon-linux-extras install -y nginx1

# Enable and start nginx
systemctl enable nginx
systemctl start nginx

# Clean up any previous clone
cd /home/ec2-user
rm -rf word-reverser

# Retry loop for cloning the repo (handles timing/network issues)
REPO_URL="https://github.com/Conor9720/terraform-word-reverser.git"
CLONE_DIR="word-reverser"

for i in {1..5}; do
    echo "Attempting to clone repo (try $i)..."
    if git clone "$REPO_URL" "$CLONE_DIR"; then
        echo "✅ Clone successful."
        break
    else
        echo "⚠️ Clone failed. Retrying in 5 seconds..."
        sleep 5
    fi
done

# Exit early if clone still failed
if [ ! -d "$CLONE_DIR" ]; then
    echo "❌ ERROR: Failed to clone repo after multiple attempts."
    exit 1
fi

# Install dependencies
cd /home/ec2-user/word-reverser
pip3 install fastapi uvicorn --break-system-packages
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
