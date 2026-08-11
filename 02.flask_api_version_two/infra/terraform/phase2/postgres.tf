# terraform/phase2/postgres.tf
# Dedicated EC2 instance running PostgreSQL inside Docker.
# This is a single t3.micro instance — not in the ASG.
# All Flask app instances connect to this one Postgres instance.
#
# Note: For production, consider Amazon RDS instead — it handles backups,
# failover, and patching automatically. This Docker-on-EC2 approach is for
# learning/demo purposes.

resource "aws_instance" "postgres" {
  ami           = var.ami_id             # Ubuntu 22.04 LTS, ap-south-1
  instance_type = var.postgres_instance_type  # t3.micro
  key_name      = data.aws_key_pair.mac_key.key_name

  # Attach Postgres security group
  vpc_security_group_ids = [aws_security_group.pg_sg.id]

  # Place in a specific subnet (ap-south-1a) with a predictable private IP
  subnet_id = data.aws_subnet.pg_subnet.id

  # user_data: install Docker, run PostgreSQL in Docker
  user_data = base64encode(<<-EOF
    #!/bin/bash
    set -euxo pipefail

    # Update system
    apt-get update -y

    # Install Docker
    curl -fsSL https://get.docker.com -o /tmp/get-docker.sh
    sh /tmp/get-docker.sh
    systemctl enable docker
    systemctl start docker
    usermod -aG docker ubuntu

    # Install Docker Compose
    mkdir -p /usr/local/lib/docker/cli-plugins
    curl -SL https://github.com/docker/compose/releases/latest/download/docker-compose-linux-x86_64 \
      -o /usr/local/lib/docker/cli-plugins/docker-compose
    chmod +x /usr/local/lib/docker/cli-plugins/docker-compose

    # Create the Postgres Docker Compose file
    mkdir -p /opt/postgres
    cat > /opt/postgres/docker-compose.yml << 'PGEOF'
version: "3.9"
services:
  postgres:
    image: postgres:15-alpine
    container_name: todo-postgres
    environment:
      POSTGRES_USER: ${var.pg_username}
      POSTGRES_PASSWORD: ${var.pg_password}
      POSTGRES_DB: ${var.pg_database}
    ports:
      - "5432:5432"
    volumes:
      - pg_data:/var/lib/postgresql/data
    restart: unless-stopped
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${var.pg_username} -d ${var.pg_database}"]
      interval: 10s
      timeout: 5s
      retries: 5
      start_period: 30s

volumes:
  pg_data:
    driver: local
PGEOF

    # Start PostgreSQL
    cd /opt/postgres
    docker compose up -d

    # Wait for Postgres to be ready
    sleep 20

    # Verify Postgres is running
    docker compose ps

    # Create a systemd service so Postgres restarts on instance reboot
    cat > /etc/systemd/system/todo-postgres.service << 'SVCEOF'
[Unit]
Description=Todo Postgres Docker Compose
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/postgres
ExecStart=/usr/local/lib/docker/cli-plugins/docker-compose up -d
ExecStop=/usr/local/lib/docker/cli-plugins/docker-compose down
TimeoutStartSec=300

[Install]
WantedBy=multi-user.target
SVCEOF

    systemctl daemon-reload
    systemctl enable todo-postgres

    echo "PostgreSQL setup complete on $(hostname)"
  EOF
  )

  tags = {
    Name        = "todo-api-postgres"
    Environment = var.environment
    Role        = "database"
  }
}

# Output the private IP so we know what to put in DATABASE_URL
output "postgres_private_ip" {
  value       = aws_instance.postgres.private_ip
  description = "Private IP of the Postgres EC2 — used in DATABASE_URL by Flask instances"
}