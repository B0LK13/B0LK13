#!/bin/bash

# VPS Security Hardening & N8N Deployment Script
# This script automates the entire deployment process

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ANSIBLE_DIR="$SCRIPT_DIR/ansible"
DOCKER_DIR="$SCRIPT_DIR/docker"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Logging
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
    exit 1
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Display banner
show_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                    VPS Security Hardening & N8N Deployment                  ║
║                                                                              ║
║  This script will:                                                           ║
║  • Harden your VPS security                                                  ║
║  • Deploy N8N with Docker Compose                                            ║
║  • Configure SSL certificates                                                ║
║  • Set up monitoring and backups                                             ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if Ansible is installed
    if ! command -v ansible >/dev/null 2>&1; then
        error "Ansible is not installed. Please install Ansible first."
    fi
    
    # Check if SSH key exists
    if [[ ! -f ~/.ssh/id_rsa.pub ]]; then
        warn "SSH public key not found. Generating new SSH key pair..."
        ssh-keygen -t rsa -b 4096 -C "$(whoami)@$(hostname)" -f ~/.ssh/id_rsa -N ""
        log "SSH key pair generated successfully"
    fi
    
    # Check if configuration files exist
    if [[ ! -f "$ANSIBLE_DIR/inventory/hosts" ]]; then
        error "Ansible inventory file not found. Please copy and configure hosts.example"
    fi
    
    if [[ ! -f "$ANSIBLE_DIR/group_vars/all/vault.yml" ]]; then
        error "Ansible vault file not found. Please copy and configure vault.yml.example"
    fi
    
    if [[ ! -f "$DOCKER_DIR/.env" ]]; then
        error "Docker environment file not found. Please copy and configure .env.example"
    fi
    
    log "Prerequisites check completed"
}

# Validate configuration
validate_configuration() {
    log "Validating configuration..."
    
    # Test Ansible connectivity
    cd "$ANSIBLE_DIR"
    if ! ansible vps_servers -m ping >/dev/null 2>&1; then
        error "Cannot connect to VPS servers. Please check your inventory configuration and SSH access."
    fi
    
    # Check if vault is encrypted
    if grep -q "vault_" "$ANSIBLE_DIR/group_vars/all/vault.yml" 2>/dev/null; then
        if ! grep -q "\$ANSIBLE_VAULT" "$ANSIBLE_DIR/group_vars/all/vault.yml"; then
            warn "Vault file is not encrypted. Consider encrypting it with: ansible-vault encrypt group_vars/all/vault.yml"
        fi
    fi
    
    log "Configuration validation completed"
}

# Deploy security hardening
deploy_security() {
    log "Starting security hardening deployment..."
    
    cd "$ANSIBLE_DIR"
    
    # Run security hardening playbook
    if ansible-playbook -i inventory/hosts playbooks/security-hardening.yml; then
        log "Security hardening completed successfully"
    else
        error "Security hardening failed"
    fi
    
    # Test SSH connection with new user
    local admin_user=$(ansible-inventory -i inventory/hosts --list | jq -r '.vps_servers.vars.vault_admin_user // "admin"')
    local server_ip=$(ansible-inventory -i inventory/hosts --list | jq -r '._meta.hostvars | to_entries[0].value.ansible_host')
    
    info "Testing SSH connection with user: $admin_user"
    if ssh -o ConnectTimeout=10 -o BatchMode=yes "$admin_user@$server_ip" "echo 'SSH connection successful'" >/dev/null 2>&1; then
        log "SSH connection test successful"
    else
        warn "SSH connection test failed. Please verify SSH key configuration."
    fi
}

# Deploy N8N
deploy_n8n() {
    log "Starting N8N deployment..."
    
    cd "$ANSIBLE_DIR"
    
    # Run N8N deployment playbook
    if ansible-playbook -i inventory/hosts playbooks/n8n-deployment.yml; then
        log "N8N deployment completed successfully"
    else
        error "N8N deployment failed"
    fi
    
    # Wait for services to be ready
    info "Waiting for services to be ready..."
    sleep 30
    
    # Test N8N accessibility
    local domain_name=$(ansible-inventory -i inventory/hosts --list | jq -r '.vps_servers.vars.vault_domain_name // "localhost"')
    
    if curl -k -s "https://$domain_name/healthz" >/dev/null 2>&1; then
        log "N8N is accessible at https://$domain_name"
    else
        warn "N8N health check failed. Please check the deployment logs."
    fi
}

# Setup monitoring
setup_monitoring() {
    log "Setting up monitoring..."
    
    cd "$ANSIBLE_DIR"
    
    # Deploy monitoring stack
    if ansible-playbook -i inventory/hosts playbooks/n8n-deployment.yml --tags monitoring; then
        log "Monitoring setup completed"
    else
        warn "Monitoring setup failed"
    fi
}

# Configure backups
configure_backups() {
    log "Configuring backup system..."
    
    cd "$ANSIBLE_DIR"
    
    # Test backup script
    local server_ip=$(ansible-inventory -i inventory/hosts --list | jq -r '._meta.hostvars | to_entries[0].value.ansible_host')
    local admin_user=$(ansible-inventory -i inventory/hosts --list | jq -r '.vps_servers.vars.vault_admin_user // "admin"')
    
    if ssh "$admin_user@$server_ip" "test -f /opt/backups/scripts/backup.sh"; then
        log "Backup script is installed"
        
        # Test backup execution
        info "Testing backup script..."
        if ssh "$admin_user@$server_ip" "/opt/backups/scripts/backup.sh" >/dev/null 2>&1; then
            log "Backup test completed successfully"
        else
            warn "Backup test failed. Please check the backup configuration."
        fi
    else
        warn "Backup script not found"
    fi
}

# Display deployment summary
show_summary() {
    local domain_name=$(cd "$ANSIBLE_DIR" && ansible-inventory -i inventory/hosts --list | jq -r '.vps_servers.vars.vault_domain_name // "your-domain.com"')
    local admin_user=$(cd "$ANSIBLE_DIR" && ansible-inventory -i inventory/hosts --list | jq -r '.vps_servers.vars.vault_admin_user // "admin"')
    local server_ip=$(cd "$ANSIBLE_DIR" && ansible-inventory -i inventory/hosts --list | jq -r '._meta.hostvars | to_entries[0].value.ansible_host')
    
    cat << EOF

╔══════════════════════════════════════════════════════════════════════════════╗
║                           DEPLOYMENT COMPLETED                              ║
╚══════════════════════════════════════════════════════════════════════════════╝

🎉 Your N8N instance has been successfully deployed!

📍 Access Information:
   • N8N Web Interface: https://$domain_name
   • Monitoring Dashboard: https://monitoring.$domain_name (if enabled)
   • Server IP: $server_ip
   • SSH Access: ssh $admin_user@$server_ip

🔐 Security Features Enabled:
   ✅ SSH key-based authentication
   ✅ Firewall (UFW) configured
   ✅ Fail2ban intrusion prevention
   ✅ Automatic security updates
   ✅ SSL/TLS certificates (Let's Encrypt)
   ✅ System hardening applied

🗄️ Database & Storage:
   ✅ PostgreSQL database configured
   ✅ Automated daily backups
   ✅ Data persistence with Docker volumes

📊 Monitoring & Logging:
   ✅ Prometheus metrics collection
   ✅ Grafana dashboards (if enabled)
   ✅ Log rotation configured
   ✅ Health checks enabled

🔄 Maintenance:
   ✅ Automatic SSL certificate renewal
   ✅ Daily backup schedule (2:00 AM)
   ✅ Log rotation configured
   ✅ System update automation

📚 Next Steps:
   1. Configure your domain DNS to point to $server_ip
   2. Access N8N at https://$domain_name and complete setup
   3. Review and customize security settings as needed
   4. Test backup and restore procedures
   5. Set up monitoring alerts (if using monitoring stack)

📖 Documentation:
   • Deployment Guide: docs/deployment-guide.md
   • Security Guide: docs/security-hardening.md
   • Backup Guide: docs/backup-recovery.md
   • Troubleshooting: docs/troubleshooting.md

⚠️  Important Notes:
   • Keep your vault password secure
   • Regularly update system packages
   • Monitor system resources and performance
   • Test disaster recovery procedures periodically

EOF
}

# Main deployment function
main() {
    show_banner
    
    # Parse command line arguments
    local skip_security=false
    local skip_n8n=false
    local skip_monitoring=false
    local skip_backups=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            --skip-security)
                skip_security=true
                shift
                ;;
            --skip-n8n)
                skip_n8n=true
                shift
                ;;
            --skip-monitoring)
                skip_monitoring=true
                shift
                ;;
            --skip-backups)
                skip_backups=true
                shift
                ;;
            --help|-h)
                cat << EOF
Usage: $0 [OPTIONS]

Options:
    --skip-security     Skip security hardening
    --skip-n8n         Skip N8N deployment
    --skip-monitoring  Skip monitoring setup
    --skip-backups     Skip backup configuration
    --help, -h         Show this help message

Examples:
    $0                 # Full deployment
    $0 --skip-security # Deploy N8N only (security already configured)
    $0 --skip-monitoring --skip-backups # Deploy without monitoring and backups
EOF
                exit 0
                ;;
            *)
                error "Unknown option: $1"
                ;;
        esac
    done
    
    # Run deployment steps
    check_prerequisites
    validate_configuration
    
    if [[ "$skip_security" != true ]]; then
        deploy_security
    else
        info "Skipping security hardening"
    fi
    
    if [[ "$skip_n8n" != true ]]; then
        deploy_n8n
    else
        info "Skipping N8N deployment"
    fi
    
    if [[ "$skip_monitoring" != true ]]; then
        setup_monitoring
    else
        info "Skipping monitoring setup"
    fi
    
    if [[ "$skip_backups" != true ]]; then
        configure_backups
    else
        info "Skipping backup configuration"
    fi
    
    show_summary
    
    log "Deployment completed successfully!"
}

# Run main function with all arguments
main "$@"
