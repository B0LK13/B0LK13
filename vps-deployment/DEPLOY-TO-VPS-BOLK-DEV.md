# 🚀 Deploy to vps.bolk.dev

This guide will help you deploy your optimized Next.js blog to your VPS at `vps.bolk.dev`.

## 📋 Prerequisites

1. **VPS Server** with Ubuntu 20.04+ and root access
2. **Domain Setup**: Point `vps.bolk.dev` to your VPS IP address
3. **SSH Access** configured with key-based authentication
4. **Git** installed on your local machine

## 🔧 Quick Deployment (Automated)

### Option 1: Automated Deployment Script

1. **Edit the deployment script**:
   ```bash
   nano deploy-vps-bolk-dev.sh
   ```
   
   Update the VPS_IP variable:
   ```bash
   VPS_IP="YOUR_ACTUAL_VPS_IP"  # Replace with your VPS IP
   ```

2. **Run the automated deployment**:
   ```bash
   ./deploy-vps-bolk-dev.sh
   ```

This script will:
- Test SSH connection
- Upload all files to your VPS
- Run system optimization
- Deploy the application
- Setup SSL certificate (optional)
- Verify the deployment

## 🖥️ Manual Deployment Steps

### Step 1: Connect to Your VPS
```bash
ssh root@YOUR_VPS_IP
```

### Step 2: Clone Repository
```bash
cd /opt
git clone https://github.com/B0LK13/B0LK13.git bolk-blog
cd bolk-blog
```

### Step 3: Configure Environment
```bash
cp .env.example .env
nano .env
```

Set your configuration:
```env
NODE_ENV=production
BLOG_NAME=B0LK13 Blog
BLOG_TITLE=B0LK13's Tech Blog
BLOG_FOOTER_TEXT=© 2024 B0LK13. All rights reserved.
GITHUB_USERNAME=B0LK13
OPENAI_API_KEY=your_openai_key_here
```

### Step 4: Run System Optimization
```bash
chmod +x scripts/*.sh deploy.sh
sudo ./scripts/optimize-vps.sh
```

### Step 5: Deploy Application
```bash
sudo ./deploy.sh production
```

### Step 6: Setup SSL Certificate
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

### Step 7: Verify Deployment
```bash
./scripts/verify-deployment.sh
```

## 🔍 Testing Your Deployment

### Health Checks
```bash
# Test health endpoint
curl https://vps.bolk.dev/health

# Test main page
curl -I https://vps.bolk.dev

# Check SSL certificate
openssl s_client -connect vps.bolk.dev:443 -servername vps.bolk.dev
```

### Performance Tests
```bash
# Run performance monitoring
./scripts/performance-monitor.sh

# Generate performance report
./scripts/performance-monitor.sh --report

# Check container status
docker-compose ps
```

## 📊 Expected Results

After successful deployment, you should have:

### ✅ Working Services
- **Next.js Application**: Running on port 3000
- **Nginx Reverse Proxy**: Running on ports 80/443
- **Redis Cache**: Running on port 6379
- **SSL Certificate**: Valid and auto-renewing

### ✅ Performance Features
- **Load Time**: < 2 seconds
- **HTTP/2**: Enabled
- **Gzip Compression**: Active
- **Static Asset Caching**: Configured
- **Image Optimization**: WebP/AVIF support

### ✅ Security Features
- **SSL/TLS**: A+ rating
- **Security Headers**: Implemented
- **Rate Limiting**: Active
- **Fail2Ban**: Monitoring for intrusions
- **Firewall**: UFW configured

### ✅ Monitoring & Maintenance
- **Health Checks**: Every 30 seconds
- **Performance Monitoring**: Every 5 minutes
- **Automated Backups**: Daily at 2 AM
- **Log Rotation**: Configured
- **Auto-restart**: On failure

## 🔧 Post-Deployment Management

### Daily Operations
```bash
# Check application status
docker-compose ps

# View logs
docker-compose logs -f nextjs-app

# Monitor performance
./scripts/performance-monitor.sh

# Check system resources
sysinfo
```

### Maintenance Commands
```bash
# Update application
git pull
docker-compose up -d --build

# Restart services
docker-compose restart

# Manual backup
/opt/backup.sh

# Check SSL certificate expiry
openssl x509 -enddate -noout -in nginx/ssl/vps.bolk.dev.crt
```

### Monitoring URLs
- **Main Site**: https://vps.bolk.dev
- **Health Check**: https://vps.bolk.dev/health
- **Email Agent**: https://vps.bolk.dev/email-agent

## 🚨 Troubleshooting

### Common Issues

1. **Domain not resolving**:
   ```bash
   # Check DNS
   nslookup vps.bolk.dev
   dig vps.bolk.dev
   ```

2. **SSL certificate issues**:
   ```bash
   # Check certificate
   openssl x509 -in nginx/ssl/vps.bolk.dev.crt -text -noout
   
   # Renew certificate
   sudo certbot renew
   ```

3. **Application not starting**:
   ```bash
   # Check logs
   docker-compose logs nextjs-app
   
   # Rebuild containers
   docker-compose down
   docker-compose up -d --build
   ```

4. **High resource usage**:
   ```bash
   # Check resources
   docker stats
   free -h
   df -h
   
   # Restart if needed
   docker-compose restart
   ```

## 📞 Support Commands

```bash
# System information
sysinfo

# Container status
docker-compose ps

# Application logs
docker-compose logs -f

# Performance report
./scripts/performance-monitor.sh --report

# Deployment verification
./scripts/verify-deployment.sh
```

## 🎉 Success!

Once deployed, your blog will be available at:
- **https://vps.bolk.dev** - Main blog
- **https://vps.bolk.dev/health** - Health check
- **https://vps.bolk.dev/email-agent** - Email agent interface

Your VPS is now optimized with:
- ⚡ High-performance caching
- 🔒 Enterprise-grade security
- 📊 Comprehensive monitoring
- 🔄 Automated maintenance
- 📱 Mobile-optimized delivery

Enjoy your blazing-fast, secure, and reliable blog! 🚀
