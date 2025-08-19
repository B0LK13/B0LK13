#!/bin/bash

# Deployment Script for cloud.bolk.vps
# This script deploys your optimized Next.js blog to your VPS

set -e

# Configuration
DOMAIN="vps.bolk.dev"
APP_NAME="bolk-blog"
VPS_USER="root"  # Change this to your VPS username
VPS_IP="31.97.47.51"  # Your VPS IP address

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO: $1${NC}"
}

# Check if VPS IP is set
check_config() {
    if [ "$VPS_IP" = "YOUR_VPS_IP" ]; then
        error "Please set your VPS IP address in the script (VPS_IP variable)"
    fi
    
    info "Deploying to: $VPS_USER@$VPS_IP"
    info "Domain: $DOMAIN"
}

# Test SSH connection
test_ssh() {
    log "Testing SSH connection to VPS..."
    
    if ssh -o ConnectTimeout=10 -o BatchMode=yes $VPS_USER@$VPS_IP exit 2>/dev/null; then
        log "SSH connection successful"
    else
        error "Cannot connect to VPS. Please check your SSH configuration and VPS IP."
    fi
}

# Upload files to VPS
upload_files() {
    log "Uploading files to VPS..."
    
    # Create directory on VPS
    ssh $VPS_USER@$VPS_IP "mkdir -p /opt/$APP_NAME"
    
    # Upload all files except node_modules and .git
    rsync -avz --progress \
        --exclude 'node_modules' \
        --exclude '.git' \
        --exclude '.next' \
        --exclude 'logs' \
        --exclude '*.log' \
        ./ $VPS_USER@$VPS_IP:/opt/$APP_NAME/
    
    log "Files uploaded successfully"
}

# Run deployment on VPS
deploy_on_vps() {
    log "Running deployment on VPS..."
    
    ssh $VPS_USER@$VPS_IP << 'ENDSSH'
        cd /opt/bolk-blog
        
        # Make scripts executable
        chmod +x deploy.sh
        chmod +x scripts/*.sh
        
        # Run system optimization (first time only)
        if [ ! -f "/opt/.system-optimized" ]; then
            echo "Running system optimization..."
            ./scripts/optimize-vps.sh
            touch /opt/.system-optimized
        fi
        
        # Deploy application
        ./deploy.sh production
        
        # Verify deployment
        ./scripts/verify-deployment.sh
ENDSSH
    
    if [ $? -eq 0 ]; then
        log "Deployment completed successfully!"
    else
        error "Deployment failed. Check the logs above."
    fi
}

# Setup SSL certificate
setup_ssl() {
    log "Setting up SSL certificate..."
    
    ssh $VPS_USER@$VPS_IP << ENDSSH
        cd /opt/$APP_NAME
        
        # Install certbot if not present
        if ! command -v certbot &> /dev/null; then
            apt update
            apt install -y certbot
        fi
        
        # Stop nginx temporarily
        docker-compose stop nginx
        
        # Get SSL certificate
        certbot certonly --standalone -d $DOMAIN --non-interactive --agree-tos --email admin@$DOMAIN
        
        # Copy certificates
        cp /etc/letsencrypt/live/$DOMAIN/fullchain.pem nginx/ssl/$DOMAIN.crt
        cp /etc/letsencrypt/live/$DOMAIN/privkey.pem nginx/ssl/$DOMAIN.key
        
        # Restart services
        docker-compose up -d
        
        # Setup auto-renewal
        (crontab -l 2>/dev/null; echo "0 12 * * * /usr/bin/certbot renew --quiet") | crontab -
ENDSSH
    
    log "SSL certificate setup completed"
}

# Test deployment
test_deployment() {
    log "Testing deployment..."
    
    # Wait for services to start
    sleep 30
    
    # Test health endpoint
    if curl -f -s https://$DOMAIN/health > /dev/null; then
        log "✅ Health check passed"
    else
        warn "❌ Health check failed"
    fi
    
    # Test main page
    if curl -f -s https://$DOMAIN > /dev/null; then
        log "✅ Main page accessible"
    else
        warn "❌ Main page not accessible"
    fi
    
    # Test SSL
    if curl -f -s -I https://$DOMAIN | grep -q "HTTP/2"; then
        log "✅ HTTP/2 enabled"
    else
        warn "❌ HTTP/2 not enabled"
    fi
}

# Show deployment info
show_info() {
    echo ""
    echo "🎉 Deployment Summary"
    echo "===================="
    echo "Domain: https://$DOMAIN"
    echo "Health Check: https://$DOMAIN/health"
    echo "Admin Panel: https://$DOMAIN/email-agent"
    echo ""
    echo "📊 Monitoring Commands (run on VPS):"
    echo "ssh $VPS_USER@$VPS_IP"
    echo "cd /opt/$APP_NAME"
    echo "./scripts/performance-monitor.sh"
    echo "./scripts/verify-deployment.sh"
    echo "docker-compose logs -f"
    echo ""
    echo "🔧 Management Commands:"
    echo "Restart: docker-compose restart"
    echo "Update: git pull && docker-compose up -d --build"
    echo "Backup: /opt/backup.sh"
    echo ""
}

# Main deployment function
main() {
    log "Starting deployment to vps.bolk.dev..."
    
    check_config
    test_ssh
    upload_files
    deploy_on_vps
    
    # Ask about SSL setup
    read -p "Do you want to setup SSL certificate with Let's Encrypt? (y/n): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        setup_ssl
    else
        warn "Skipping SSL setup. You can run it later manually."
    fi
    
    test_deployment
    show_info
    
    log "🚀 Deployment to vps.bolk.dev completed!"
}

# Show usage if no arguments
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0"
    echo ""
    echo "This script deploys your Next.js blog to vps.bolk.dev"
    echo ""
    echo "Before running:"
    echo "1. Set your VPS_IP in this script"
    echo "2. Ensure SSH key authentication is setup"
    echo "3. Point vps.bolk.dev to your VPS IP"
    echo ""
    echo "Options:"
    echo "  --help, -h    Show this help message"
    echo ""
    exit 0
fi

# Run main function
main "$@"
