#!/bin/bash

# Update and install necessary packages
yum update -y
yum install -y python3 nginx git

# Enable and start nginx
systemctl enable nginx
systemctl start nginx

# Install FastAPI and Uvicorn
pip3 install fastapi uvicorn

# Set up the backend FastAPI app
mkdir -p /home/ec2-user/word-reverser
cat <<EOF > /home/ec2-user/word-reverser/app.py
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel

app = FastAPI()

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

class Word(BaseModel):
    word: str

@app.get("/")
def read_root():
    return {"message": "OK"}

@app.post("/reverse")
def reverse_word(data: Word):
    return {"reversed_word": data.word[::-1]}
EOF

# Run the app with uvicorn in the background on port 8000
nohup uvicorn /home/ec2-user/word-reverser/app:app --host 0.0.0.0 --port 8000 &

# Create the frontend HTML
cat <<EOF > /usr/share/nginx/html/index.html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Word Reverser</title>
</head>
<body>
    <h1>Word Reverser</h1>
    <form id="wordForm">
        <label for="word">Enter a word:</label>
        <input type="text" id="word" name="word">
        <button type="submit">Reverse</button>
    </form>

    <p id="reversedWord"></p>

    <script>
        const form = document.getElementById('wordForm');
    
        form.addEventListener('submit', async (event) => {
            event.preventDefault();
    
            const word = document.getElementById('word').value;
    
            const response = await fetch('/reverse', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                body: JSON.stringify({ word })
            });
    
            const data = await response.json();
            document.getElementById('reversedWord').textContent = \`Reversed Word: \${data.reversed_word}\`;
        });
    </script>   
</body>
</html>
EOF

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

# Restart nginx to apply config
systemctl restart nginx
