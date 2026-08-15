#!/bin/bash
# packer/install.sh
#
# Runs ONCE during Packer AMI build on a temporary EC2 instance
# Everything installed here is baked permanently into the resulting AMI
#
# Goal: pre-installed Docker + Compose + pull base Docker images
# So ASG instances only need to clone the repo and run docker compose up --build.
#
# Without this AMI: Docker install (3 min) + image pulls (3 min) + build (4 min) = 7-9 min
# With this AMI: git clone (15s) + docker compose --build (45s) = ~60s

set -euxo pipefail

echo "============================================"
echo "  Starting AMI provisioning."
echo "============================================"

# 1. Update system packages
apt-get update -y
apt-get upgrade -y -q

# 2. Install essential utilities
apt-get install -y \
    git \
    curl \
    wget \
    unzip \
    netcat-openbsd \
    ca-certificates \
    gnupg \
    lsb-release

# netcat-openbsd provides nc command used in user_data to wait for postgres

# 3. Install docker using official script
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh

systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# 4. Install docker compose v2
mkdir -p /usr/local/lib/docker/cli-plugins

COMPOSE_VERSION="v2.29.1"

curl -SL \
    "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-x86_64" \
    -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

docker compose version

# 5. Pre-pull Docker base images
echo "Pre-pulling Docker base images..."

docker pull python:3.11-slim
# This is FROM python:3.11-slim in the Dockerfile.
# When docker compose up --build runs later, Docker finds this in cache
# and skips the ~200MB download entirely.

docker pull nginx:1.25-alpine
# This is the nginx image in docker-compose.yml

echo "Images now cached in AMI:"
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"

# 6. Create app/api directory structure
mkdir -p /opt/todo-api
chown ubuntu:ubuntu /opt/todo-api

# /etc/todo-api/env will hold DATABASE_URL and JWT_SECRET_KEY.
# Written by user_data at instance boot (contains production secrets).
mkdir -p /etc/todo-api
chmod 700 /etc/todo-api

# 7. Write the systemd service template.
# The service definition is baked into the AMI.
# user_data will populate /opt/todo-api and /etc/todo-api/env, then start the service.
cat > /etc/systemd/system/todo-api.service << 'SVCEOF'
[Unit]
Description=Todo API Docker Compose Stack
After=docker.service network.target
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/todo-api
EnvironmentFile=/etc/todo-api/env
ExecStart=/usr/local/lib/docker/cli-plugins/docker-compose up -d
ExecStop=/usr/local/lib/docker/cli-plugins/docker-compose down
TimeoutStartSec=120

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable todo-api

# 8. Clean up to minimize AMI size
apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /tmp/get-docker.sh

# 9. Verification
echo ""
echo "================================="
echo " Verification"
echo "================================="
docker --version
docker compose version
git --version
nc -h 2>&1 | head -1
docker images --format "table {{.Repository}}\t{{.Tag}}\t{{.Size}}"
echo "================================="
echo " AMI Provisioning complete!"
echo "================================="