# 🚀 Quick Start Guide

This is a comprehensive VPS security hardening and N8N deployment solution for your server at **31.97.47.51**.

## ⚡ Super Quick Deployment (5 minutes)

```bash
# 1. Install Ansible (if not already installed)
pip install ansible

# 2. Run the setup script
./setup.sh

# 3. Deploy everything
./deploy.sh
```

That's it! Your secure N8N instance will be ready at `https://your-domain.com`

## 📋 What You Get

### 🔐 Security Features
- ✅ SSH key-based authentication (password auth disabled)
- ✅ UFW firewall configured (only SSH, HTTP, HTTPS allowed)
- ✅ Fail2ban intrusion prevention (3 attempts = 1-hour ban)
- ✅ Automatic security updates
- ✅ SSL/TLS certificates (Let's Encrypt auto-renewal)
- ✅ Non-root user setup with sudo access
- ✅ System hardening (kernel parameters, disabled protocols)

### 🏗️ N8N Infrastructure
- ✅ N8N latest version with Docker Compose
- ✅ PostgreSQL 15 database with automated backups
- ✅ Redis for queue management
- ✅ Nginx reverse proxy with SSL termination
- ✅ Health checks and auto-restart policies
- ✅ Resource limits and performance optimization

### 📊 Monitoring & Backup
- ✅ Prometheus metrics collection
- ✅ Grafana dashboards (optional)
- ✅ Daily automated backups (database + data + configs)
- ✅ S3 backup support (optional)
- ✅ Email alerts for backup status
- ✅ Log rotation and management

## 🎯 Prerequisites

1. **Domain Name**: Point your domain to `31.97.47.51`
2. **SSH Access**: Root access to the server
3. **Local Tools**: Ansible installed on your machine

## 🔧 Configuration Options

### Basic Configuration
The setup script will ask for:
- Domain name
- Email for SSL certificates
- Admin username (default: admin)
- SSH port (default: 22)

### Advanced Configuration
Edit these files for advanced options:
- `ansible/inventory/hosts` - Server and connection settings
- `ansible/group_vars/all/vault.yml` - Encrypted secrets
- `docker/.env` - Application environment variables

## 📁 Project Structure

```
vps-deployment/
├── 🚀 setup.sh                    # Quick setup script
├── 🚀 deploy.sh                   # Main deployment script
├── 📖 README.md                   # Comprehensive documentation
├── 📖 QUICK_START.md              # This file
├── 
├── ansible/                       # Infrastructure as Code
│   ├── ansible.cfg               # Ansible configuration
│   ├── inventory/
│   │   └── hosts.example         # Server inventory template
│   ├── group_vars/all/
│   │   └── vault.yml.example     # Encrypted variables template
│   └── playbooks/
│       ├── security-hardening.yml # Security configuration
│       └── n8n-deployment.yml    # N8N deployment
│
├── docker/                       # Container configurations
│   ├── docker-compose.yml       # Main compose file
│   ├── .env.example             # Environment variables template
│   └── nginx/                   # Nginx configuration
│       ├── nginx.conf           # Main nginx config
│       └── conf.d/
│           └── n8n.conf         # N8N-specific config
│
├── security/                     # Security hardening
│   └── hardening.sh             # Security hardening script
│
├── backup/                       # Backup system
│   └── backup.sh                # Comprehensive backup script
│
├── monitoring/                   # Monitoring configuration
│   └── prometheus/
│       └── prometheus.yml       # Metrics configuration
│
└── docs/                         # Documentation
    └── deployment-guide.md       # Detailed deployment guide
```

## 🎛️ Management Commands

### Deployment
```bash
./deploy.sh                      # Full deployment
./deploy.sh --skip-security      # Skip security (if already done)
./deploy.sh --skip-monitoring    # Skip monitoring setup
```

### Service Management
```bash
# SSH to server
ssh admin@31.97.47.51

# Check services
docker ps
docker-compose -f /opt/n8n/docker-compose.yml ps

# View logs
docker-compose -f /opt/n8n/docker-compose.yml logs -f n8n
docker-compose -f /opt/n8n/docker-compose.yml logs -f postgres

# Restart services
docker-compose -f /opt/n8n/docker-compose.yml restart
```

### Backup Management
```bash
# Manual backup
/opt/backups/scripts/backup.sh

# View backup logs
tail -f /opt/backups/backup.log

# List backups
ls -la /opt/backups/
```

## 🔐 Default Credentials

After deployment, check the `CREDENTIALS.txt` file for:
- N8N admin password
- Database passwords
- Monitoring passwords
- Vault encryption password

**⚠️ Important**: Delete `CREDENTIALS.txt` after noting the passwords!

## 🌐 Access URLs

- **N8N Interface**: `https://your-domain.com`
- **Monitoring** (if enabled): `https://monitoring.your-domain.com`
- **SSH Access**: `ssh admin@31.97.47.51`

## 🆘 Troubleshooting

### Common Issues

1. **Domain not accessible**:
   ```bash
   # Check DNS propagation
   nslookup your-domain.com
   
   # Check SSL certificate
   openssl s_client -connect your-domain.com:443
   ```

2. **Services not starting**:
   ```bash
   # Check Docker logs
   docker-compose -f /opt/n8n/docker-compose.yml logs
   
   # Check system resources
   df -h
   free -h
   ```

3. **SSL certificate issues**:
   ```bash
   # Manual certificate generation
   docker-compose -f /opt/n8n/docker-compose.yml run --rm certbot \
     certonly --webroot --webroot-path=/var/www/certbot \
     --email your-email@example.com --agree-tos --no-eff-email \
     -d your-domain.com
   ```

### Getting Help

1. Check the logs: `docker-compose logs [service]`
2. Review the documentation in `docs/`
3. Verify configuration files
4. Check system resources and connectivity

## 🔄 Updates & Maintenance

### Regular Tasks
- **Weekly**: Review security logs and backup status
- **Monthly**: Update Docker images and system packages
- **Quarterly**: Security audit and performance review

### Update Commands
```bash
# Update system packages (automatic updates are enabled)
sudo apt update && sudo apt upgrade -y

# Update Docker images
cd /opt/n8n
docker-compose pull
docker-compose up -d

# Renew SSL certificates (automatic renewal is configured)
docker-compose run --rm certbot renew
docker-compose exec nginx nginx -s reload
```

## 📞 Support

For issues:
1. Check this guide and the documentation in `docs/`
2. Review logs for error messages
3. Verify configuration and connectivity
4. Check the official N8N documentation

---

**🎉 Congratulations!** You now have a production-ready, secure N8N instance with comprehensive monitoring and backup systems!
