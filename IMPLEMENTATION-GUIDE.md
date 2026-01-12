# 🚀 VPS Implementation Guide for vps.bolk.dev

This guide will walk you through implementing all optimizations on your cloud VPS.

## 📋 Prerequisites

- Ubuntu 20.04+ VPS with root access
- Domain `vps.bolk.dev` pointing to your VPS IP
- At least 2GB RAM and 20GB storage
- SSH access to your VPS

## 🔧 Step-by-Step Implementation

### Step 1: Connect to Your VPS
```bash
ssh root@YOUR_VPS_IP
# or
ssh your_user@YOUR_VPS_IP
```

### Step 2: Update System and Install Git
```bash
sudo apt update && sudo apt upgrade -y
sudo apt install -y git curl wget
```

### Step 3: Clone Your Repository
```bash
cd /opt
sudo git clone https://github.com/B0LK13/B0LK13.git bolk-blog
cd bolk-blog
sudo chown -R $USER:$USER /opt/bolk-blog
```

### Step 4: Configure Environment
```bash
# Copy and edit environment file
cp .env.example .env
nano .env

# Set your configuration:
# BLOG_NAME=B0LK13 Blog
# BLOG_TITLE=B0LK13's Tech Blog
# GITHUB_USERNAME=B0LK13
# OPENAI_API_KEY=your_key_here
# etc.
```

### Step 5: Run System Optimization
```bash
sudo ./scripts/optimize-vps.sh
```

This will:
- Update system packages
- Optimize kernel parameters
- Install and configure Fail2Ban
- Setup automatic security updates
- Configure Docker optimizations
- Install monitoring tools
- Setup backup system

### Step 6: Deploy Application
```bash
sudo ./deploy.sh production
```

This will:
- Install Docker and Docker Compose
- Create SSL certificates (self-signed initially)
- Build and start all containers
- Setup monitoring and health checks

### Step 7: Verify Deployment
```bash
# Check container status
docker-compose ps

# Check application health
curl http://localhost:3000/api/health

# Check logs
docker-compose logs -f nextjs-app
```

### Step 8: Setup SSL Certificate (Production)
```bash
# Install Certbot
sudo apt install -y certbot

# Stop nginx temporarily
sudo docker-compose stop nginx

# Get SSL certificate
sudo certbot certonly --standalone -d vps.bolk.dev

# Copy certificates
sudo cp /etc/letsencrypt/live/vps.bolk.dev/fullchain.pem nginx/ssl/vps.bolk.dev.crt
sudo cp /etc/letsencrypt/live/vps.bolk.dev/privkey.pem nginx/ssl/vps.bolk.dev.key

# Restart services
sudo docker-compose up -d
```

### Step 9: Configure Firewall
```bash
# Setup UFW firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

### Step 10: Setup Monitoring
```bash
# Test performance monitoring
./scripts/performance-monitor.sh

# Add to crontab for regular monitoring
(crontab -l 2>/dev/null; echo "*/5 * * * * /opt/bolk-blog/scripts/performance-monitor.sh") | crontab -

# Generate performance report
./scripts/performance-monitor.sh --report
```

## 🔍 Verification Checklist

### ✅ Application Status
- [ ] Containers are running: `docker-compose ps`
- [ ] Health check passes: `curl https://vps.bolk.dev/health`
- [ ] Website loads: `curl https://vps.bolk.dev`
- [ ] SSL certificate valid: `openssl s_client -connect vps.bolk.dev:443`

### ✅ Performance
- [ ] Response time < 2 seconds
- [ ] Gzip compression enabled
- [ ] Static assets cached
- [ ] HTTP/2 enabled

### ✅ Security
- [ ] Fail2Ban active: `sudo systemctl status fail2ban`
- [ ] Firewall configured: `sudo ufw status`
- [ ] SSL/TLS configured properly
- [ ] Security headers present

### ✅ Monitoring
- [ ] Performance monitoring script works
- [ ] Log rotation configured
- [ ] Backup system functional
- [ ] Health checks responding

## 🛠️ Useful Commands

### Container Management
```bash
# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Update and rebuild
git pull && docker-compose up -d --build

# Stop all services
docker-compose down
```

### Monitoring
```bash
# System info
sysinfo

# Performance monitoring
npm run vps:monitor

# Generate report
npm run vps:report

# Container stats
docker stats
```

### Maintenance
```bash
# Manual backup
/opt/backup.sh

# Check disk space
df -h

# Check memory usage
free -h

# View system logs
journalctl -f
```

## 🚨 Troubleshooting

### Common Issues

1. **Port 80/443 already in use**:
   ```bash
   sudo lsof -i :80
   sudo lsof -i :443
   # Stop conflicting services
   ```

2. **Docker permission denied**:
   ```bash
   sudo usermod -aG docker $USER
   # Logout and login again
   ```

3. **SSL certificate issues**:
   ```bash
   # Check certificate
   openssl x509 -in nginx/ssl/vps.bolk.dev.crt -text -noout
   ```

4. **Application not responding**:
   ```bash
   # Check logs
   docker-compose logs nextjs-app
   
   # Restart application
   docker-compose restart nextjs-app
   ```

## 📊 Performance Expectations

After implementation, you should see:
- **Load time**: 1-3 seconds (down from 3-8 seconds)
- **TTFB**: < 500ms (down from 1-2 seconds)
- **Lighthouse score**: 90+ (up from 60-80)
- **Uptime**: 99.9%+ with monitoring

## 🔄 Maintenance Schedule

### Daily
- Automated backups (2 AM)
- Performance monitoring (every 5 minutes)
- Security updates (automatic)

### Weekly
- Review performance reports
- Check log files
- Verify SSL certificate status

### Monthly
- Update Docker images
- Review and clean old backups
- Security audit

## 📞 Support

If you encounter issues:
1. Check logs: `docker-compose logs`
2. Run health check: `curl https://vps.bolk.dev/health`
3. Check system resources: `sysinfo`
4. Review monitoring reports

Your VPS optimization is now complete! 🎉
