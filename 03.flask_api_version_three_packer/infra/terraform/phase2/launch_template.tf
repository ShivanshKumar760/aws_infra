resource "aws_launch_template" "todo_api" {
  name_prefix   = "todo-api-"
  image_id      = var.ami_id
  instance_type = var.instance_type

  key_name                = data.aws_key_pair.mac_key.key_name
  vpc_security_group_ids  = [aws_security_group.ec2_sg.id]

  user_data = base64encode(<<-EOF
#!/bin/bash
set -euxo pipefail

# ── Install Docker ────────────────────────────────────────────────────
apt-get update -y
curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
sh /tmp/get-docker.sh
systemctl enable docker
systemctl start docker
usermod -aG docker ubuntu

# ── Install Docker Compose ────────────────────────────────────────────
mkdir -p /usr/local/lib/docker/cli-plugins
curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

# ── Clone the app repository ──────────────────────────────────────────
mkdir -p /opt/todo-api
git clone ${var.app_repo_url} /opt/todo-api
cd /opt/todo-api
git checkout ${var.app_repo_branch}

# ── Write the .env file ───────────────────────────────────────────────
# DATABASE_URL points at the PRIVATE IP of the Postgres EC2 instance.
# This IP is injected by Terraform at the time the launch template is created.
cat > /opt/todo-api/.env << 'ENVEOF'
DATABASE_URL=postgresql://${var.pg_username}:${var.pg_password}@${aws_instance.postgres.private_ip}:5432/${var.pg_database}
JWT_SECRET_KEY=${var.jwt_secret_key}
SQLALCHEMY_ECHO=False
ENVEOF
chmod 600 /opt/todo-api/.env

# ── Wait for Postgres to be ready before starting Flask ───────────────
# The Postgres EC2 may still be initialising when this instance boots.
# Retry connection for up to 5 minutes.
echo "Waiting for Postgres at ${aws_instance.postgres.private_ip}:5432..."
for i in $(seq 1 30); do
  if nc -z ${aws_instance.postgres.private_ip} 5432 2>/dev/null; then
    echo "Postgres is reachable (attempt $i)"
    break
  fi
  echo "Postgres not ready yet — waiting 10s (attempt $i/30)..."
  sleep 10
done

# ── Build and start Docker Compose ────────────────────────────────────
cd /opt/todo-api
# --build forces Docker to build the Flask image from Dockerfile (no ECR)
docker compose up --build -d

# ── Health check: verify the stack is up ─────────────────────────────
sleep 30
curl -f http://localhost/healthz || echo "Warning: health check failed on startup"

# ── Systemd service for auto-restart on instance reboot ───────────────
cat > /etc/systemd/system/todo-api.service << 'SVCEOF'
[Unit]
Description=Todo API Docker Compose Stack
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/todo-api
ExecStart=/usr/local/lib/docker/cli-plugins/docker-compose up -d
ExecStop=/usr/local/lib/docker/cli-plugins/docker-compose down
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
SVCEOF

systemctl daemon-reload
systemctl enable todo-api

echo "Todo API stack started on $(hostname)"
EOF
  )

  tag_specifications {
    resource_type = "instance"
    tags = {
      Name        = "todo-api-asg-instance"
      Environment = var.environment
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}