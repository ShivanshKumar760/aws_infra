# #!/bin/bash
# # setup.sh
# # Run this on the EC2 instance after SSH-ing in.
# # This is the manual setup step from the blog — what gets baked into the AMI.
# set -euxo pipefail

# # ── Update system ─────────────────────────────────────────────────────────────
# sudo yum update -y

# # ── Install Python 3 ──────────────────────────────────────────────────────────
# sudo yum install -y python3 python3-pip git

# # ── Install Nginx ─────────────────────────────────────────────────────────────
# sudo amazon-linux-extras install nginx1.12 -y

# # ── Clone the app ─────────────────────────────────────────────────────────────
# cd /home/ec2-user
# git clone https://github.com/youruser/todo-api.git
# cd todo-api

# # ── Create virtualenv and install dependencies ────────────────────────────────
# python3 -m venv .venv
# source .venv/bin/activate
# pip install -r requirements.txt


# # ── Set environment variables ─────────────────────────────────────────────────
# # In production, these come from AWS Parameter Store or Secrets Manager.
# # For this demo we write them to a file that the systemd service reads.
# sudo tee /etc/todo-api.env > /dev/null << 'EOF'
# JWT_SECRET_KEY=replace-with-a-very-long-random-string-in-production
# DB_PATH=/home/ec2-user/todo-api/todos.db
# EOF
# sudo chmod 600 /etc/todo-api.env



# sudo tee /etc/systemd/system/gunicorn.service > /dev/null << 'EOF'
# [Unit]
# Description=Gunicorn daemon for JWT Todo API
# After=network.target

# [Service]
# User=ec2-user
# Group=nginx
# WorkingDirectory=/home/ec2-user/todo-api
# EnvironmentFile=/etc/todo-api.env
# ExecStart=/home/ec2-user/todo-api/.venv/bin/gunicorn \
#     --workers 3 \
#     --bind unix:/home/ec2-user/todo-api/todo-api.sock \
#     --access-logfile /var/log/gunicorn-access.log \
#     --error-logfile /var/log/gunicorn-error.log \
#     wsgi:app

# [Install]
# WantedBy=multi-user.target
# EOF

# sudo systemctl daemon-reload
# sudo systemctl enable gunicorn
# sudo systemctl start gunicorn

# # Verify it started
# sudo systemctl status gunicorn

# # ── Configure Nginx as reverse proxy ──────────────────────────────────────────
# # Nginx sits in front of Gunicorn.
# # It receives HTTP requests and forwards them through the Unix socket to Gunicorn.
# sudo tee /etc/nginx/conf.d/todo-api.conf > /dev/null << 'EOF'
# server {
#     listen 80;
#     server_name _;

#     location /healthz {
#         proxy_set_header Host              $http_host;
#         proxy_set_header X-Real-IP         $remote_addr;
#         proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
#         proxy_set_header X-Forwarded-Proto $scheme;
#         proxy_pass http://unix:/home/ec2-user/todo-api/todo-api.sock;
#     }

#     location / {
#         proxy_set_header Host              $http_host;
#         proxy_set_header X-Real-IP         $remote_addr;
#         proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
#         proxy_set_header X-Forwarded-Proto $scheme;
#         proxy_pass http://unix:/home/ec2-user/todo-api/todo-api.sock;
#     }
# }
# EOF

# # Add ec2-user to nginx group (so nginx can access the socket file)
# sudo usermod -a -G ec2-user nginx
# chmod 710 /home/ec2-user

# # Test config and start Nginx
# sudo nginx -t
# sudo systemctl enable nginx
# sudo systemctl start nginx
# sudo systemctl status nginx

# echo "Setup complete! Test with: curl http://localhost/healthz"


#!/bin/bash
# setup.sh
set -euxo pipefail

# ── Update system ─────────────────────────────────────────────────────────────
sudo yum update -y

# ── Install Python 3 ──────────────────────────────────────────────────────────
sudo yum install -y python3 python3-pip git

# ── Install Nginx (FIXED for Amazon Linux 2023) ────────────────────────────────
sudo yum install -y nginx

# ── Use current folder instead of dynamic git clone ───────────────────────────
# We navigate into the folder you already uploaded
cd /home/ec2-user/tempflask-backend

# ── Create virtualenv and install dependencies ────────────────────────────────
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt

# ── Set environment variables ─────────────────────────────────────────────────
sudo tee /etc/todo-api.env > /dev/null << 'EOF'
JWT_SECRET_KEY=replace-with-a-very-long-random-string-in-production
DB_PATH=/home/ec2-user/tempflask-backend/todos.db
EOF
sudo chmod 600 /etc/todo-api.env

# ── Setup Gunicorn Service File ───────────────────────────────────────────────
sudo tee /etc/systemd/system/gunicorn.service > /dev/null << 'EOF'
[Unit]
Description=Gunicorn daemon for JWT Todo API
After=network.target

[Service]
User=ec2-user
Group=nginx
WorkingDirectory=/home/ec2-user/tempflask-backend
EnvironmentFile=/etc/todo-api.env
ExecStart=/home/ec2-user/tempflask-backend/.venv/bin/gunicorn \
    --workers 3 \
    --bind unix:/home/ec2-user/tempflask-backend/todo-api.sock \
    --access-logfile /var/log/gunicorn-access.log \
    --error-logfile /var/log/gunicorn-error.log \
    wsgi:app

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable gunicorn
sudo systemctl start gunicorn

# ── Configure Nginx as Reverse Proxy ──────────────────────────────────────────
sudo tee /etc/nginx/conf.d/todo-api.conf > /dev/null << 'EOF'
server {
    listen 80;
    server_name _;

    location / {
        proxy_set_header Host              $http_host;
        proxy_set_header X-Real-IP         $remote_addr;
        proxy_set_header X-Forwarded-For   $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_pass http://unix:/home/ec2-user/tempflask-backend/todo-api.sock;
    }
}
EOF

# Add nginx to the ec2-user group so it can read your socket file path
sudo usermod -a -G ec2-user nginx
chmod 710 /home/ec2-user

# Test config and start Nginx
sudo nginx -t
sudo systemctl enable nginx
sudo systemctl start nginx

echo "Setup complete! Test with: curl http://localhost/healthz"
