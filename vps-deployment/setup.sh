#!/bin/bash

# Quick Setup Script for VPS N8N Deployment
# This script helps you configure the deployment quickly

set -euo pipefail

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

log() {
    echo -e "${GREEN}[SETUP] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[SETUP] WARNING: $1${NC}"
}

info() {
    echo -e "${BLUE}[SETUP] INFO: $1${NC}"
}

error() {
    echo -e "${RED}[SETUP] ERROR: $1${NC}"
    exit 1
}

# Show banner
show_banner() {
    cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════════╗
║                        N8N VPS Deployment Setup                             ║
║                                                                              ║
║  This script will help you configure the deployment for your VPS            ║
║  Server IP: 31.97.47.51                                                     ║
║                                                                              ║
╚══════════════════════════════════════════════════════════════════════════════╝
EOF
}

# Check prerequisites
check_prerequisites() {
    log "Checking prerequisites..."
    
    # Check if we're in the right directory
    if [[ ! -f "$SCRIPT_DIR/deploy.sh" ]]; then
        error "This script must be run from the vps-deployment directory"
    fi
    
    # Check for required tools
    local missing_tools=()
    
    if ! command -v ansible >/dev/null 2>&1; then
        missing_tools+=("ansible")
    fi
    
    if ! command -v ssh-keygen >/dev/null 2>&1; then
        missing_tools+=("ssh-keygen")
    fi
    
    if ! command -v openssl >/dev/null 2>&1; then
        missing_tools+=("openssl")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        error "Missing required tools: ${missing_tools[*]}. Please install them first."
    fi
    
    log "Prerequisites check passed"
}

# Generate SSH key if needed
setup_ssh_key() {
    if [[ ! -f ~/.ssh/id_rsa ]]; then
        log "Generating SSH key pair..."
        read -p "Enter your email address: " email
        ssh-keygen -t rsa -b 4096 -C "$email" -f ~/.ssh/id_rsa -N ""
        log "SSH key generated successfully"
    else
        log "SSH key already exists"
    fi
    
    info "Your SSH public key:"
    cat ~/.ssh/id_rsa.pub
    echo
    warn "Please add this public key to your server's authorized_keys file"
}

# Configure inventory
setup_inventory() {
    log "Setting up Ansible inventory..."
    
    local inventory_file="$SCRIPT_DIR/ansible/inventory/hosts"
    
    if [[ ! -f "$inventory_file" ]]; then
        cp "$SCRIPT_DIR/ansible/inventory/hosts.example" "$inventory_file"
        log "Inventory file created from template"
    fi
    
    # Update server IP
    sed -i.bak 's/31\.97\.47\.51/31.97.47.51/g' "$inventory_file"
    
    # Get user input for configuration
    read -p "Enter admin username [admin]: " admin_user
    admin_user=${admin_user:-admin}
    
    read -p "Enter SSH port [22]: " ssh_port
    ssh_port=${ssh_port:-22}
    
    read -p "Enter your domain name: " domain_name
    if [[ -z "$domain_name" ]]; then
        error "Domain name is required"
    fi
    
    read -p "Enter your email for SSL certificates: " ssl_email
    if [[ -z "$ssl_email" ]]; then
        error "Email is required for SSL certificates"
    fi
    
    # Update inventory with user input
    sed -i.bak "s/vault_admin_user=admin/vault_admin_user=$admin_user/g" "$inventory_file"
    sed -i.bak "s/vault_ssh_port=22/vault_ssh_port=$ssh_port/g" "$inventory_file"
    sed -i.bak "s/vault_domain_name=your-domain.com/vault_domain_name=$domain_name/g" "$inventory_file"
    sed -i.bak "s/vault_ssl_email=your-email@example.com/vault_ssl_email=$ssl_email/g" "$inventory_file"
    
    # Add SSH public key
    if [[ -f ~/.ssh/id_rsa.pub ]]; then
        local ssh_key=$(cat ~/.ssh/id_rsa.pub)
        echo "vault_ssh_public_key=\"$ssh_key\"" >> "$inventory_file"
    fi
    
    log "Inventory configured successfully"
}

# Setup vault
setup_vault() {
    log "Setting up Ansible vault..."
    
    local vault_file="$SCRIPT_DIR/ansible/group_vars/all/vault.yml"
    
    if [[ ! -f "$vault_file" ]]; then
        cp "$SCRIPT_DIR/ansible/group_vars/all/vault.yml.example" "$vault_file"
        log "Vault file created from template"
    fi
    
    # Generate secure passwords
    local postgres_password=$(openssl rand -base64 32)
    local n8n_password=$(openssl rand -base64 16)
    local encryption_key=$(openssl rand -base64 32)
    local redis_password=$(openssl rand -base64 16)
    local monitoring_password=$(openssl rand -base64 16)
    
    # Update vault with generated passwords
    sed -i.bak "s/your_secure_postgres_password_here/$postgres_password/g" "$vault_file"
    sed -i.bak "s/your_secure_n8n_password_here/$n8n_password/g" "$vault_file"
    sed -i.bak "s/your_32_character_encryption_key_here/$encryption_key/g" "$vault_file"
    sed -i.bak "s/your_secure_redis_password_here/$redis_password/g" "$vault_file"
    sed -i.bak "s/your_secure_monitoring_password_here/$monitoring_password/g" "$vault_file"
    
    # Get domain and email from user
    read -p "Enter your domain name: " domain_name
    read -p "Enter your email: " email
    
    sed -i.bak "s/your-domain.com/$domain_name/g" "$vault_file"
    sed -i.bak "s/your-email@example.com/$email/g" "$vault_file"
    
    # Create vault password
    local vault_password=$(openssl rand -base64 16)
    echo "$vault_password" > "$SCRIPT_DIR/ansible/.vault_pass"
    chmod 600 "$SCRIPT_DIR/ansible/.vault_pass"
    
    # Encrypt vault file
    cd "$SCRIPT_DIR/ansible"
    ansible-vault encrypt group_vars/all/vault.yml --vault-password-file .vault_pass
    
    log "Vault configured and encrypted successfully"
    info "Vault password saved to ansible/.vault_pass"
    
    # Save credentials for user reference
    cat > "$SCRIPT_DIR/CREDENTIALS.txt" << EOF
N8N Deployment Credentials
=========================
Generated on: $(date)

N8N Login:
- Username: admin
- Password: $n8n_password

Database:
- Username: n8n_user
- Password: $postgres_password

Monitoring:
- Username: monitor
- Password: $monitoring_password

Vault Password: $vault_password

IMPORTANT: Keep this file secure and delete it after noting the credentials!
EOF
    
    warn "Credentials saved to CREDENTIALS.txt - please secure this file!"
}

# Setup Docker environment
setup_docker_env() {
    log "Setting up Docker environment..."
    
    local env_file="$SCRIPT_DIR/docker/.env"
    
    if [[ ! -f "$env_file" ]]; then
        cp "$SCRIPT_DIR/docker/.env.example" "$env_file"
        log "Docker environment file created from template"
    fi
    
    # Update with domain name
    read -p "Enter your domain name: " domain_name
    sed -i.bak "s/your-domain.com/$domain_name/g" "$env_file"
    
    log "Docker environment configured"
}

# Test connectivity
test_connectivity() {
    log "Testing server connectivity..."
    
    if ssh -o ConnectTimeout=10 -o BatchMode=yes root@31.97.47.51 "echo 'Connection successful'" >/dev/null 2>&1; then
        log "Server connectivity test passed"
    else
        warn "Cannot connect to server. Please ensure:"
        warn "1. Server is accessible"
        warn "2. SSH key is added to server"
        warn "3. Root access is available"
    fi
}

# Show summary
show_summary() {
    cat << EOF

╔══════════════════════════════════════════════════════════════════════════════╗
║                            SETUP COMPLETED                                  ║
╚══════════════════════════════════════════════════════════════════════════════╝

✅ Configuration files created and configured
✅ SSH key generated (if needed)
✅ Ansible vault encrypted
✅ Docker environment configured

📁 Files created/updated:
   • ansible/inventory/hosts
   • ansible/group_vars/all/vault.yml (encrypted)
   • ansible/.vault_pass
   • docker/.env
   • CREDENTIALS.txt

🚀 Next steps:
   1. Review the configuration files
   2. Ensure your domain DNS points to 31.97.47.51
   3. Run the deployment: ./deploy.sh

📖 Documentation:
   • Deployment Guide: docs/deployment-guide.md
   • README: README.md

⚠️  Security Notes:
   • Keep CREDENTIALS.txt secure and delete after use
   • The vault password is in ansible/.vault_pass
   • SSH key authentication is configured

EOF
}

# Main function
main() {
    show_banner
    
    check_prerequisites
    setup_ssh_key
    setup_inventory
    setup_vault
    setup_docker_env
    test_connectivity
    
    # Make scripts executable
    chmod +x "$SCRIPT_DIR/deploy.sh"
    chmod +x "$SCRIPT_DIR/backup/backup.sh"
    chmod +x "$SCRIPT_DIR/security/hardening.sh"
    
    show_summary
    
    log "Setup completed successfully!"
    info "Run './deploy.sh' to start the deployment"
}

# Run main function
main "$@"
