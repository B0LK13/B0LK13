# VPS Security Hardening & N8N Deployment Guide

This repository contains a comprehensive deployment solution for securing a VPS and deploying N8N with best practices.

## 🏗️ Architecture Overview

```
Internet → Cloudflare/DNS → Nginx (SSL Termination) → N8N Container
                                ↓
                           PostgreSQL Container
                                ↓
                           Monitoring Stack
```

## 📁 Project Structure

```
vps-deployment/
├── ansible/                    # Infrastructure as Code
│   ├── playbooks/
│   ├── roles/
│   └── inventory/
├── docker/                     # Container configurations
│   ├── docker-compose.yml
│   ├── n8n/
│   └── nginx/
├── security/                   # Security hardening scripts
│   ├── hardening.sh
│   ├── fail2ban/
│   └── firewall/
├── monitoring/                 # Monitoring and logging
│   ├── prometheus/
│   └── grafana/
├── backup/                     # Backup scripts and configs
└── docs/                      # Documentation
```

## 🚀 Quick Start

1. **Prepare your local environment:**
   ```bash
   # Install Ansible
   pip install ansible
   
   # Clone and configure
   cd vps-deployment
   cp ansible/inventory/hosts.example ansible/inventory/hosts
   # Edit hosts file with your server IP
   ```

2. **Run security hardening:**
   ```bash
   ansible-playbook -i ansible/inventory/hosts ansible/playbooks/security-hardening.yml
   ```

3. **Deploy N8N:**
   ```bash
   ansible-playbook -i ansible/inventory/hosts ansible/playbooks/n8n-deployment.yml
   ```

## 🔐 Security Features

- ✅ SSH key-based authentication
- ✅ Firewall configuration (UFW)
- ✅ Fail2ban intrusion prevention
- ✅ Automatic security updates
- ✅ SSL/TLS certificates (Let's Encrypt)
- ✅ Non-root user setup
- ✅ System hardening

## 📊 Monitoring

- Prometheus metrics collection
- Grafana dashboards
- Log aggregation
- Alerting rules

## 🔄 Backup Strategy

- Automated PostgreSQL backups
- N8N workflow exports
- Configuration backups
- Retention policies

## 📚 Documentation

See the `docs/` directory for detailed guides:
- [Security Hardening Guide](docs/security-hardening.md)
- [N8N Deployment Guide](docs/n8n-deployment.md)
- [Monitoring Setup](docs/monitoring.md)
- [Backup & Recovery](docs/backup-recovery.md)
- [Troubleshooting](docs/troubleshooting.md)

## ⚠️ Important Notes

- Replace all placeholder values with your actual configuration
- Review security settings before deployment
- Test backup and recovery procedures
- Monitor system resources and performance
