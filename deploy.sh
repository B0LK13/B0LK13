#!/bin/bash

# VPS Deployment Script for B0LK13 Blog
# Usage: ./deploy.sh [environment]

set -e

# Configuration
ENVIRONMENT=${1:-production}
APP_NAME="bolk-blog"
BACKUP_DIR="/opt/backups"
LOG_FILE="/var/log/deploy.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a $LOG_FILE
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a $LOG_FILE
    exit 1
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a $LOG_FILE
}

# Check if running as root or with sudo
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root or with sudo"
    fi
}

# Install Docker and Docker Compose if not present
install_docker() {
    if ! command -v docker &> /dev/null; then
        log "Installing Docker..."
        curl -fsSL https://get.docker.com -o get-docker.sh
        sh get-docker.sh
        systemctl enable docker
        systemctl start docker
        rm get-docker.sh
    fi

    if ! command -v docker-compose &> /dev/null; then
        log "Installing Docker Compose..."
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
}

# Create backup
create_backup() {
    if [ -d "/opt/$APP_NAME" ]; then
        log "Creating backup..."
        mkdir -p $BACKUP_DIR
        tar -czf "$BACKUP_DIR/${APP_NAME}_$(date +%Y%m%d_%H%M%S).tar.gz" -C /opt $APP_NAME
        log "Backup created successfully"
    fi
}

# Setup SSL certificates
setup_ssl() {
    log "Setting up SSL certificates..."
    mkdir -p nginx/ssl
    
    if [ ! -f "nginx/ssl/vps.bolk.dev.crt" ]; then
        warn "SSL certificates not found. Generating self-signed certificates..."
        openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
            -keyout nginx/ssl/vps.bolk.dev.key \
            -out nginx/ssl/vps.bolk.dev.crt \
            -subj "/C=US/ST=State/L=City/O=Organization/CN=vps.bolk.dev"
        warn "Please replace with proper SSL certificates from a CA"
    fi
}

# Deploy application
deploy() {
    log "Starting deployment for $ENVIRONMENT environment..."
    
    # Stop existing containers
    if docker-compose ps | grep -q "Up"; then
        log "Stopping existing containers..."
        docker-compose down
    fi
    
    # Build and start new containers
    log "Building and starting containers..."
    docker-compose up -d --build
    
    # Wait for services to be ready
    log "Waiting for services to be ready..."
    sleep 30
    
    # Health check
    if curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
        log "Health check passed"
    else
        error "Health check failed"
    fi
}

# Setup monitoring
setup_monitoring() {
    log "Setting up monitoring..."
    
    # Create monitoring script
    cat > /opt/monitor.sh << 'EOF'
#!/bin/bash
# Simple monitoring script
LOGFILE="/var/log/app-monitor.log"
WEBHOOK_URL="${WEBHOOK_URL:-}"

check_service() {
    if ! curl -f http://localhost:3000/api/health > /dev/null 2>&1; then
        echo "$(date): Service is down" >> $LOGFILE
        if [ ! -z "$WEBHOOK_URL" ]; then
            curl -X POST -H 'Content-type: application/json' \
                --data '{"text":"🚨 VPS.BOLK.DEV is down!"}' \
                "$WEBHOOK_URL"
        fi
        # Restart service
        cd /opt/bolk-blog && docker-compose restart
    fi
}

check_service
EOF
    
    chmod +x /opt/monitor.sh
    
    # Add to crontab
    (crontab -l 2>/dev/null; echo "*/5 * * * * /opt/monitor.sh") | crontab -
}

# Main deployment process
main() {
    log "Starting VPS optimization and deployment..."
    
    check_permissions
    install_docker
    create_backup
    setup_ssl
    deploy
    setup_monitoring
    
    log "Deployment completed successfully!"
    log "Your application is now running at https://vps.bolk.dev"
    log "Health check: curl https://vps.bolk.dev/health"
}

# Run main function
main "$@"
