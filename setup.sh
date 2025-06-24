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

# Clean up any previous clone
cd /home/ec2-user
rm -rf word-reverser

# Clone the repo
REPO_URL="https://github.com/Conor9720/terraform-word-reverser.git"
git clone "$REPO_URL" word-reverser

cd word-reverser

# Install dependencies
pip3 install --upgrade pip
if [ -f requirements.txt ]; then
  pip3 install -r requirements.txt
else
  pip3 install fastapi uvicorn jinja2 python-multipart
fi

# Create systemd service
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

# Reload and start service
systemctl daemon-reexec
systemctl daemon-reload
systemctl enable wordreverser
systemctl start wordreverser
