#!/bin/bash

################################################################################
# Phase 4: Production Deployment
#
# Prepares the system for production deployment.
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
source "$DEPLOY_DIR/common/utils.sh"

main() {
    log_info "Configuring production deployment..."
    
    # Create production configuration
    create_production_config
    
    # Set up systemd services
    create_systemd_services
    
    # Configure nginx reverse proxy
    configure_nginx
    
    # Set up backup and recovery
    setup_backup
    
    log_success "Production deployment configured"
}

create_production_config() {
    log_info "Creating production configuration..."
    
    cat > "$DEPLOY_DIR/config/production.yaml" << 'EOF'
# Production Configuration

environment: production

# Scaling
scaling:
  worker_processes: 8
  max_concurrent_agents: 20
  queue_workers: 4

# High Availability
ha:
  enabled: true
  health_check_interval: 30
  auto_restart: true
  max_restart_attempts: 3

# Performance
performance:
  cache_enabled: true
  cache_ttl: 3600
  connection_pool_size: 100
  request_timeout: 60

# Security
security:
  tls_enabled: true
  api_key_rotation_enabled: true
  rate_limiting_enabled: true
  ip_whitelist_enabled: false

# Monitoring
monitoring:
  metrics_enabled: true
  tracing_enabled: true
  log_level: INFO
  alert_on_errors: true

# Backup
backup:
  enabled: true
  interval_hours: 24
  retention_days: 30
  backup_database: true
  backup_configs: true
EOF
    
    log_success "Production configuration created"
}

create_systemd_services() {
    log_info "Creating systemd services..."
    
    # Celery worker service
    cat > /tmp/agentic-soc-worker.service << EOF
[Unit]
Description=AI Agentic SOC - Celery Worker
After=network.target redis.service postgresql.service

[Service]
Type=forking
User=$USER
Group=$USER
WorkingDirectory=$DEPLOY_DIR
Environment="PATH=$DEPLOY_DIR/.venv/bin:/usr/local/bin:/usr/bin:/bin"
ExecStart=$DEPLOY_DIR/.venv/bin/celery -A agents.orchestrator worker --loglevel=info --detach
ExecStop=$DEPLOY_DIR/.venv/bin/celery -A agents.orchestrator control shutdown
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    # Dashboard service
    cat > /tmp/agentic-soc-dashboard.service << EOF
[Unit]
Description=AI Agentic SOC - Dashboard
After=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=$DEPLOY_DIR/dashboard
ExecStart=/usr/bin/python3 -m http.server 3000
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    log_info "Systemd service files created in /tmp"
    log_info "To install, run:"
    log_info "  sudo cp /tmp/agentic-soc-*.service /etc/systemd/system/"
    log_info "  sudo systemctl daemon-reload"
    log_info "  sudo systemctl enable agentic-soc-worker agentic-soc-dashboard"
    log_info "  sudo systemctl start agentic-soc-worker agentic-soc-dashboard"
}

configure_nginx() {
    log_info "Creating nginx configuration..."
    
    cat > /tmp/agentic-soc-nginx.conf << 'EOF'
# AI Agentic SOC - Nginx Configuration

upstream dashboard {
    server 127.0.0.1:3000;
}

upstream grafana {
    server 127.0.0.1:3001;
}

server {
    listen 80;
    server_name agentic-soc.local;

    # Dashboard
    location / {
        proxy_pass http://dashboard;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # Grafana
    location /grafana/ {
        proxy_pass http://grafana/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # API endpoints (if needed)
    location /api/ {
        proxy_pass http://127.0.0.1:8000/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
}
EOF
    
    log_info "Nginx configuration created in /tmp/agentic-soc-nginx.conf"
    log_info "To install, copy to /etc/nginx/sites-available/ and enable"
}

setup_backup() {
    log_info "Setting up backup and recovery..."
    
    ensure_directory "$DEPLOY_DIR/backups"
    
    cat > "$DEPLOY_DIR/backup.sh" << 'EOF'
#!/bin/bash
# Backup script for AI Agentic SOC

BACKUP_DIR="./backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="agentic-soc-backup-$TIMESTAMP"

echo "Starting backup: $BACKUP_NAME"

# Create backup directory
mkdir -p "$BACKUP_DIR/$BACKUP_NAME"

# Backup database
echo "Backing up database..."
docker exec agentic-soc-db pg_dump -U soc_admin agentic_soc > "$BACKUP_DIR/$BACKUP_NAME/database.sql"

# Backup configuration
echo "Backing up configuration..."
cp -r config "$BACKUP_DIR/$BACKUP_NAME/"
cp .env "$BACKUP_DIR/$BACKUP_NAME/.env.backup" 2>/dev/null || true

# Backup data
echo "Backing up data..."
cp -r data/logs "$BACKUP_DIR/$BACKUP_NAME/" 2>/dev/null || true

# Create archive
echo "Creating archive..."
cd "$BACKUP_DIR"
tar -czf "$BACKUP_NAME.tar.gz" "$BACKUP_NAME"
rm -rf "$BACKUP_NAME"

echo "Backup completed: $BACKUP_DIR/$BACKUP_NAME.tar.gz"

# Cleanup old backups (keep last 30 days)
find "$BACKUP_DIR" -name "agentic-soc-backup-*.tar.gz" -mtime +30 -delete
EOF
    
    chmod +x "$DEPLOY_DIR/backup.sh"
    
    log_success "Backup script created"
    log_info "Run backups with: ./backup.sh"
    log_info "Consider adding to cron: 0 2 * * * /path/to/backup.sh"
}

main "$@"
