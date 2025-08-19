#!/bin/bash

# VPS System Optimization Script
# This script optimizes your VPS for better performance

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%H:%M:%S')] INFO: $1${NC}"
}

# Check if running as root
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Update system packages
update_system() {
    log "Updating system packages..."
    apt update && apt upgrade -y
    apt autoremove -y
    apt autoclean
}

# Optimize kernel parameters
optimize_kernel() {
    log "Optimizing kernel parameters..."
    
    cat >> /etc/sysctl.conf << 'EOF'

# VPS Optimization Settings
# Network optimizations
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216
net.ipv4.tcp_rmem = 4096 65536 16777216
net.ipv4.tcp_wmem = 4096 65536 16777216
net.ipv4.tcp_congestion_control = bbr
net.core.default_qdisc = fq

# File system optimizations
fs.file-max = 2097152
vm.swappiness = 10
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Security optimizations
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.tcp_syncookies = 1
EOF

    sysctl -p
}

# Optimize limits
optimize_limits() {
    log "Optimizing system limits..."
    
    cat >> /etc/security/limits.conf << 'EOF'

# VPS Optimization Limits
* soft nofile 65536
* hard nofile 65536
* soft nproc 32768
* hard nproc 32768
root soft nofile 65536
root hard nofile 65536
EOF
}

# Install and configure fail2ban
setup_fail2ban() {
    log "Setting up Fail2Ban..."
    
    apt install -y fail2ban
    
    cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600
findtime = 600
maxretry = 3
backend = systemd

[sshd]
enabled = true
port = ssh
logpath = %(sshd_log)s
backend = %(sshd_backend)s

[nginx-http-auth]
enabled = true
filter = nginx-http-auth
port = http,https
logpath = /var/log/nginx/error.log

[nginx-limit-req]
enabled = true
filter = nginx-limit-req
port = http,https
logpath = /var/log/nginx/error.log
maxretry = 10
EOF

    systemctl enable fail2ban
    systemctl restart fail2ban
}

# Configure automatic security updates
setup_auto_updates() {
    log "Configuring automatic security updates..."
    
    apt install -y unattended-upgrades
    
    cat > /etc/apt/apt.conf.d/50unattended-upgrades << 'EOF'
Unattended-Upgrade::Allowed-Origins {
    "${distro_id}:${distro_codename}-security";
    "${distro_id}ESMApps:${distro_codename}-apps-security";
    "${distro_id}ESM:${distro_codename}-infra-security";
};

Unattended-Upgrade::AutoFixInterruptedDpkg "true";
Unattended-Upgrade::MinimalSteps "true";
Unattended-Upgrade::Remove-Unused-Dependencies "true";
Unattended-Upgrade::Automatic-Reboot "false";
EOF

    systemctl enable unattended-upgrades
}

# Optimize Docker
optimize_docker() {
    log "Optimizing Docker configuration..."
    
    mkdir -p /etc/docker
    cat > /etc/docker/daemon.json << 'EOF'
{
    "log-driver": "json-file",
    "log-opts": {
        "max-size": "10m",
        "max-file": "3"
    },
    "storage-driver": "overlay2",
    "live-restore": true,
    "userland-proxy": false,
    "experimental": false,
    "metrics-addr": "127.0.0.1:9323",
    "default-ulimits": {
        "nofile": {
            "Name": "nofile",
            "Hard": 64000,
            "Soft": 64000
        }
    }
}
EOF

    systemctl restart docker
}

# Setup log rotation
setup_logrotate() {
    log "Setting up log rotation..."
    
    cat > /etc/logrotate.d/vps-blog << 'EOF'
/var/log/deploy.log
/var/log/performance-monitor.log
/var/log/app-monitor.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 root root
}
EOF
}

# Install monitoring tools
install_monitoring() {
    log "Installing monitoring tools..."
    
    apt install -y htop iotop nethogs ncdu tree curl wget
    
    # Install ctop for container monitoring
    wget https://github.com/bcicen/ctop/releases/download/v0.7.7/ctop-0.7.7-linux-amd64 -O /usr/local/bin/ctop
    chmod +x /usr/local/bin/ctop
}

# Setup backup script
setup_backup() {
    log "Setting up backup system..."
    
    mkdir -p /opt/backups
    
    cat > /opt/backup.sh << 'EOF'
#!/bin/bash
# Automated backup script

BACKUP_DIR="/opt/backups"
APP_DIR="/opt/bolk-blog"
DATE=$(date +%Y%m%d_%H%M%S)

# Create backup
tar -czf "$BACKUP_DIR/app_backup_$DATE.tar.gz" -C /opt bolk-blog

# Keep only last 7 backups
find $BACKUP_DIR -name "app_backup_*.tar.gz" -mtime +7 -delete

# Log backup
echo "$(date): Backup completed - app_backup_$DATE.tar.gz" >> /var/log/backup.log
EOF

    chmod +x /opt/backup.sh
    
    # Add to crontab (daily at 2 AM)
    (crontab -l 2>/dev/null; echo "0 2 * * * /opt/backup.sh") | crontab -
}

# Create system info script
create_sysinfo() {
    log "Creating system info script..."
    
    cat > /usr/local/bin/sysinfo << 'EOF'
#!/bin/bash
# System information display

echo "=== VPS System Information ==="
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime -p)"
echo "Load Average: $(uptime | awk -F'load average:' '{print $2}')"
echo ""

echo "=== CPU Information ==="
lscpu | grep -E "Model name|CPU\(s\):|Thread"
echo ""

echo "=== Memory Usage ==="
free -h
echo ""

echo "=== Disk Usage ==="
df -h | grep -E "Filesystem|/dev/"
echo ""

echo "=== Network Interfaces ==="
ip -4 addr show | grep -E "inet|^[0-9]"
echo ""

echo "=== Docker Status ==="
if command -v docker &> /dev/null; then
    docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
else
    echo "Docker not installed"
fi
echo ""

echo "=== Active Services ==="
systemctl list-units --type=service --state=active | head -10
EOF

    chmod +x /usr/local/bin/sysinfo
}

# Main optimization function
main() {
    log "Starting VPS optimization..."
    
    check_root
    update_system
    optimize_kernel
    optimize_limits
    setup_fail2ban
    setup_auto_updates
    optimize_docker
    setup_logrotate
    install_monitoring
    setup_backup
    create_sysinfo
    
    log "VPS optimization completed!"
    info "Reboot recommended to apply all changes: sudo reboot"
    info "Run 'sysinfo' to view system information"
    info "Run '/opt/backup.sh' to test backup system"
}

# Run main function
main "$@"
