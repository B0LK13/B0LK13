# VPS Security Hardening & N8N Deployment Guide

This guide provides step-by-step instructions for deploying a secure N8N instance on your VPS at 31.97.47.51.

## 📋 Prerequisites

### Local Environment Setup

1. **Install Ansible:**
   ```bash
   # Ubuntu/Debian
   sudo apt update && sudo apt install ansible
   
   # macOS
   brew install ansible
   
   # Python pip
   pip install ansible
   ```

2. **Install required tools:**
   ```bash
   # SSH key generation (if needed)
   ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
   
   # AWS CLI (for S3 backups - optional)
   pip install awscli
   ```

3. **Domain Configuration:**
   - Point your domain DNS A record to `31.97.47.51`
   - Ensure domain propagation is complete

## 🚀 Quick Deployment

### Step 1: Configuration Setup

1. **Clone and configure the project:**
   ```bash
   cd vps-deployment
   
   # Copy configuration templates
   cp ansible/inventory/hosts.example ansible/inventory/hosts
   cp ansible/group_vars/all/vault.yml.example ansible/group_vars/all/vault.yml
   cp docker/.env.example docker/.env
   ```

2. **Update inventory file:**
   ```bash
   vim ansible/inventory/hosts
   ```
   
   Replace `31.97.47.51` with your actual server IP and update SSH configuration.

3. **Create encrypted vault:**
   ```bash
   # Create vault password file
   echo "your_vault_password" > ansible/.vault_pass
   chmod 600 ansible/.vault_pass
   
   # Encrypt the vault file
   ansible-vault encrypt ansible/group_vars/all/vault.yml
   ```

4. **Update vault variables:**
   ```bash
   ansible-vault edit ansible/group_vars/all/vault.yml
   ```
   
   Update all placeholder values with your actual configuration.

### Step 2: Security Hardening

1. **Test connectivity:**
   ```bash
   cd ansible
   ansible vps_servers -m ping
   ```

2. **Run security hardening:**
   ```bash
   ansible-playbook -i inventory/hosts playbooks/security-hardening.yml
   ```

3. **Verify SSH access with new user:**
   ```bash
   ssh admin@31.97.47.51 -p 22
   ```

### Step 3: N8N Deployment

1. **Deploy N8N stack:**
   ```bash
   ansible-playbook -i inventory/hosts playbooks/n8n-deployment.yml
   ```

2. **Verify deployment:**
   ```bash
   # Check services
   ssh admin@31.97.47.51 "docker ps"
   
   # Check logs
   ssh admin@31.97.47.51 "cd /opt/n8n && docker-compose logs -f"
   ```

## 🔧 Manual Deployment (Alternative)

If you prefer manual deployment or need to troubleshoot:

### Step 1: Security Hardening

1. **Connect to your server:**
   ```bash
   ssh root@31.97.47.51
   ```

2. **Run hardening script:**
   ```bash
   # Upload and run the hardening script
   wget https://raw.githubusercontent.com/your-repo/vps-deployment/main/security/hardening.sh
   chmod +x hardening.sh
   
   # Set environment variables
   export ADMIN_USER=admin
   export SSH_PORT=22
   export ALLOWED_USERS=admin
   
   # Run the script
   ./hardening.sh
   ```

3. **Add your SSH key:**
   ```bash
   # Add your public key to the admin user
   mkdir -p /home/admin/.ssh
   echo "your-ssh-public-key" >> /home/admin/.ssh/authorized_keys
   chmod 600 /home/admin/.ssh/authorized_keys
   chown -R admin:admin /home/admin/.ssh
   ```

### Step 2: Docker Installation

1. **Install Docker:**
   ```bash
   # Update system
   apt update && apt upgrade -y
   
   # Install Docker
   curl -fsSL https://get.docker.com -o get-docker.sh
   sh get-docker.sh
   
   # Add user to docker group
   usermod -aG docker admin
   
   # Install Docker Compose
   pip install docker-compose
   ```

### Step 3: N8N Deployment

1. **Create directory structure:**
   ```bash
   sudo mkdir -p /opt/n8n
   sudo chown admin:admin /opt/n8n
   cd /opt/n8n
   ```

2. **Upload configuration files:**
   ```bash
   # Upload docker-compose.yml and .env files
   # Update domain names in nginx configuration
   ```

3. **Generate SSL certificate:**
   ```bash
   # Start nginx for initial certificate
   docker-compose up -d nginx
   
   # Get certificate
   docker-compose run --rm certbot certonly --webroot \
     --webroot-path=/var/www/certbot \
     --email your-email@example.com \
     --agree-tos --no-eff-email \
     -d your-domain.com
   ```

4. **Start all services:**
   ```bash
   docker-compose up -d
   ```

## 🔐 Security Configuration

### SSH Key Setup

1. **Generate SSH key pair (if needed):**
   ```bash
   ssh-keygen -t rsa -b 4096 -C "your-email@example.com"
   ```

2. **Copy public key to server:**
   ```bash
   ssh-copy-id admin@31.97.47.51
   ```

### Firewall Configuration

The deployment automatically configures UFW with these rules:
- SSH (port 22): Allow
- HTTP (port 80): Allow (for Let's Encrypt)
- HTTPS (port 443): Allow
- All other incoming: Deny

### Fail2ban Configuration

Fail2ban is configured to protect:
- SSH (3 attempts, 1-hour ban)
- Nginx HTTP auth (3 attempts, 1-hour ban)
- Nginx rate limiting (3 attempts, 1-hour ban)

## 🗄️ Database Configuration

### PostgreSQL Setup

The deployment includes:
- PostgreSQL 15 with Alpine Linux
- Dedicated database and user for N8N
- Automated backups
- Health checks
- Resource limits

### Database Access

```bash
# Connect to database
docker exec -it n8n_postgres psql -U n8n_user -d n8n

# View database size
docker exec n8n_postgres psql -U n8n_user -d n8n -c "SELECT pg_size_pretty(pg_database_size('n8n'));"
```

## 🔄 Backup & Recovery

### Automated Backups

Daily backups are configured for:
- PostgreSQL database
- N8N workflow data
- Configuration files

### Manual Backup

```bash
# Run backup script manually
/opt/backups/scripts/backup.sh

# View backup status
tail -f /opt/backups/backup.log
```

### Restore Procedures

1. **Database restore:**
   ```bash
   # Stop N8N
   docker-compose stop n8n
   
   # Restore database
   gunzip -c /opt/backups/postgres/postgres_YYYYMMDD_HHMMSS.sql.gz | \
   docker exec -i n8n_postgres psql -U n8n_user -d n8n
   
   # Start N8N
   docker-compose start n8n
   ```

2. **Data restore:**
   ```bash
   # Stop services
   docker-compose down
   
   # Restore data
   docker run --rm -v n8n_n8n_data:/data -v /opt/backups/n8n:/backup alpine \
     tar xzf /backup/n8n_data_YYYYMMDD_HHMMSS.tar.gz -C /data
   
   # Start services
   docker-compose up -d
   ```

## 📊 Monitoring

### Access Monitoring

- **Grafana Dashboard:** https://monitoring.your-domain.com
- **Prometheus Metrics:** Internal access only
- **System Logs:** `/var/log/` and Docker logs

### Key Metrics

- System resource usage (CPU, Memory, Disk)
- Container health and performance
- N8N workflow execution metrics
- Database performance
- Network traffic and security events

## 🔧 Maintenance

### Regular Tasks

1. **Weekly:**
   - Review security logs
   - Check backup integrity
   - Monitor resource usage

2. **Monthly:**
   - Update system packages
   - Review and rotate logs
   - Test disaster recovery procedures

3. **Quarterly:**
   - Security audit
   - Performance optimization
   - Update Docker images

### Update Procedures

1. **System updates:**
   ```bash
   # Automatic updates are enabled
   # Manual update if needed:
   sudo apt update && sudo apt upgrade -y
   ```

2. **Docker image updates:**
   ```bash
   cd /opt/n8n
   docker-compose pull
   docker-compose up -d
   ```

3. **SSL certificate renewal:**
   ```bash
   # Automatic renewal is configured
   # Manual renewal if needed:
   docker-compose run --rm certbot renew
   docker-compose exec nginx nginx -s reload
   ```

## 🚨 Troubleshooting

### Common Issues

1. **SSL certificate issues:**
   ```bash
   # Check certificate status
   docker-compose logs certbot
   
   # Manual certificate generation
   docker-compose run --rm certbot certonly --webroot \
     --webroot-path=/var/www/certbot \
     --email your-email@example.com \
     --agree-tos --no-eff-email \
     -d your-domain.com
   ```

2. **Database connection issues:**
   ```bash
   # Check database logs
   docker-compose logs postgres
   
   # Test database connection
   docker exec n8n_postgres pg_isready -U n8n_user -d n8n
   ```

3. **N8N not accessible:**
   ```bash
   # Check all services
   docker-compose ps
   
   # Check nginx logs
   docker-compose logs nginx
   
   # Check N8N logs
   docker-compose logs n8n
   ```

### Log Locations

- **System logs:** `/var/log/`
- **Docker logs:** `docker-compose logs [service]`
- **N8N logs:** `/opt/n8n/logs/`
- **Nginx logs:** `/opt/n8n/docker/nginx/logs/`
- **Backup logs:** `/opt/backups/backup.log`

## 📞 Support

For issues and questions:
1. Check the troubleshooting section
2. Review logs for error messages
3. Consult the official N8N documentation
4. Check Docker and system status

## 🔒 Security Best Practices

1. **Regular Updates:** Keep all components updated
2. **Strong Passwords:** Use complex, unique passwords
3. **SSH Keys:** Always use SSH key authentication
4. **Monitoring:** Regularly review logs and metrics
5. **Backups:** Test backup and restore procedures
6. **Access Control:** Limit access to necessary users only
7. **Network Security:** Use VPN for administrative access when possible
