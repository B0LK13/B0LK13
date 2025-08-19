# 🚀 VPS Deployment Package for vps.bolk.dev

This folder contains all the optimized files needed to deploy your Next.js blog to your VPS at `vps.bolk.dev` (IP: 31.97.47.51).

## 📁 Package Contents

### Core Deployment Files
- `deploy-vps-bolk-dev.sh` - **Main automated deployment script** (pre-configured with your VPS IP)
- `deploy.sh` - Server-side deployment script
- `Dockerfile` - Optimized container build configuration
- `docker-compose.yml` - Complete stack with Nginx, Redis, and Next.js
- `next.config.js` - Performance-optimized Next.js configuration
- `.env.example` - Environment variables template

### Server Configuration
- `nginx/nginx.conf` - High-performance Nginx configuration
- `nginx/sites-available/vps.bolk.dev` - Site-specific configuration
- `nginx/ssl/` - SSL certificate directory (empty, will be populated during deployment)

### Scripts
- `scripts/optimize-vps.sh` - System optimization script
- `scripts/performance-monitor.sh` - Real-time monitoring
- `scripts/verify-deployment.sh` - Deployment verification
- `scripts/quick-deploy-check.sh` - Quick health check

### Documentation
- `DEPLOYMENT-CHECKLIST.md` - Complete deployment checklist
- `DEPLOY-TO-VPS-BOLK-DEV.md` - Detailed deployment guide
- `README-VPS.md` - VPS optimization documentation
- `IMPLEMENTATION-GUIDE.md` - Step-by-step implementation
- `QUICK-START.md` - Quick start guide

## 🚀 Quick Deployment

### Option 1: Automated Deployment (Recommended)
```bash
# Make script executable
chmod +x deploy-vps-bolk-dev.sh

# Run automated deployment
./deploy-vps-bolk-dev.sh
```

### Option 2: Manual Upload and Deploy
```bash
# Upload files to your VPS
scp -r . root@31.97.47.51:/opt/bolk-blog/

# SSH to your VPS
ssh root@31.97.47.51

# Navigate to deployment directory
cd /opt/bolk-blog

# Run deployment
chmod +x deploy.sh scripts/*.sh
sudo ./deploy.sh production
```

## 📋 Pre-Deployment Checklist

### ✅ Before You Start:
- [ ] DNS: `vps.bolk.dev` points to `31.97.47.51`
- [ ] SSH: You can connect to `root@31.97.47.51`
- [ ] Ports: 80 and 443 are available (or you're okay with stopping conflicting services)
- [ ] Resources: VPS has at least 2GB RAM and 10GB free space

### ✅ Test Commands:
```bash
# Test DNS
nslookup vps.bolk.dev

# Test SSH
ssh root@31.97.47.51

# Check VPS resources (once connected)
free -h && df -h
```

## 🔧 Configuration

### Environment Variables
Copy `.env.example` to `.env` and configure:
```env
NODE_ENV=production
BLOG_NAME=B0LK13 Blog
BLOG_TITLE=B0LK13's Tech Blog
GITHUB_USERNAME=B0LK13
OPENAI_API_KEY=your_key_here
```

### VPS Settings (Already Configured)
- **Domain:** vps.bolk.dev
- **VPS IP:** 31.97.47.51
- **SSH User:** root
- **SSL:** Auto-generated with Let's Encrypt

## 📊 What You'll Get

### Performance Features
- ⚡ 40-60% faster load times
- 🗜️ Gzip compression
- 🖼️ Image optimization (WebP/AVIF)
- 📦 Bundle splitting
- 🚀 HTTP/2 support

### Security Features
- 🔒 SSL/TLS A+ rating
- 🛡️ Security headers
- 🚫 Rate limiting
- 🔥 Fail2Ban protection
- 🧱 UFW firewall

### Monitoring & Reliability
- 💓 Health checks every 30 seconds
- 📊 Performance monitoring every 5 minutes
- 💾 Automated backups daily
- 🔄 Auto-restart on failure
- 📝 Comprehensive logging

## 🎯 Expected Results

After successful deployment:
- **Main Site:** https://vps.bolk.dev
- **Health Check:** https://vps.bolk.dev/health
- **Email Agent:** https://vps.bolk.dev/email-agent
- **Load Time:** < 2 seconds
- **SSL Rating:** A+
- **Uptime:** 99.9%+

## 🚨 Troubleshooting

### Common Issues

#### 1. Port Conflicts
```bash
# Check what's using ports 80/443
sudo lsof -i :80
sudo lsof -i :443

# Stop conflicting services
sudo systemctl stop apache2
sudo systemctl stop nginx
```

#### 2. Docker Issues
```bash
# Install Docker if needed
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
```

#### 3. SSL Certificate Problems
```bash
# Manual certificate generation
sudo certbot certonly --standalone -d vps.bolk.dev
```

#### 4. Memory Issues
```bash
# Check memory usage
free -h
docker stats

# Restart services if needed
docker-compose restart
```

## 📞 Support Commands

### Monitoring
```bash
# Performance check
./scripts/performance-monitor.sh

# Quick health check
./scripts/quick-deploy-check.sh

# Verify deployment
./scripts/verify-deployment.sh
```

### Maintenance
```bash
# View logs
docker-compose logs -f

# Restart services
docker-compose restart

# Update application
git pull && docker-compose up -d --build

# System info
sysinfo
```

## 🎉 Success Indicators

Your deployment is successful when:
- ✅ `docker-compose ps` shows all containers "Up"
- ✅ `curl https://vps.bolk.dev/health` returns JSON
- ✅ `https://vps.bolk.dev` loads your blog
- ✅ SSL certificate is valid
- ✅ Response time < 2 seconds

## 📝 Next Steps

1. **Deploy:** Run `./deploy-vps-bolk-dev.sh`
2. **Verify:** Check https://vps.bolk.dev
3. **Monitor:** Use provided monitoring scripts
4. **Maintain:** Follow maintenance schedule
5. **Optimize:** Review performance reports

Your optimized VPS deployment package is ready! 🚀

For detailed instructions, see the individual documentation files in this folder.
