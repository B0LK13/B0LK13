# 🚀 START HERE - VPS Deployment Instructions

## 📦 Welcome to Your VPS Deployment Package!

This folder contains everything needed to deploy your optimized Next.js blog to `vps.bolk.dev` (IP: 31.97.47.51).

## ⚡ Quick Start (3 Steps)

### Step 1: Test Connection
```bash
# Test SSH connection to your VPS
ssh root@31.97.47.51
```
**Expected:** You should be able to log into your VPS.

### Step 2: Deploy
```bash
# Make deployment script executable
chmod +x deploy-vps-bolk-dev.sh

# Run automated deployment
./deploy-vps-bolk-dev.sh
```
**Expected:** Script will deploy everything automatically in ~10-15 minutes.

### Step 3: Verify
```bash
# Quick health check
./scripts/quick-deploy-check.sh
```
**Expected:** All tests should pass, and your site should be live at https://vps.bolk.dev

## 📋 What's Included

### 🔧 Core Files
- `deploy-vps-bolk-dev.sh` - **Main deployment script** (pre-configured with your VPS IP)
- `Dockerfile` - Optimized container build
- `docker-compose.yml` - Complete stack (Nginx + Redis + Next.js)
- `nginx/` - High-performance web server configuration
- `scripts/` - Monitoring and optimization tools

### 📚 Documentation
- `README.md` - Complete documentation
- `DEPLOYMENT-SUMMARY.md` - Package overview
- `QUICK-START.md` - Quick start guide
- `DEPLOYMENT-CHECKLIST.md` - Detailed checklist

## 🎯 What You'll Get

After deployment, your VPS will have:

### ⚡ Performance
- **Load time:** < 2 seconds
- **HTTP/2** enabled
- **Gzip compression** active
- **Image optimization** (WebP/AVIF)
- **Static asset caching**

### 🔒 Security
- **SSL/TLS A+ rating**
- **Security headers**
- **Rate limiting**
- **Fail2Ban protection**
- **UFW firewall**

### 📊 Monitoring
- **Health checks** every 30 seconds
- **Performance monitoring** every 5 minutes
- **Automated backups** daily
- **Resource monitoring**
- **Auto-restart** on failure

## 🚨 Before You Start

### ✅ Prerequisites Check
- [ ] You can SSH to your VPS: `ssh root@31.97.47.51`
- [ ] DNS is configured: `nslookup vps.bolk.dev` returns `31.97.47.51`
- [ ] VPS has 2GB+ RAM and 10GB+ free space

### ⚠️ Important Notes
- The deployment will install Docker if not present
- Ports 80 and 443 will be used (existing services may be stopped)
- SSL certificates will be auto-generated with Let's Encrypt
- All data will be stored in `/opt/bolk-blog` on your VPS

## 🔄 Deployment Process

When you run `./deploy-vps-bolk-dev.sh`, it will:

1. **Test SSH connection** to your VPS
2. **Upload all files** to `/opt/bolk-blog`
3. **Install Docker** and dependencies
4. **Run system optimization** (firewall, security, performance)
5. **Build and start containers** (Next.js, Nginx, Redis)
6. **Generate SSL certificates** with Let's Encrypt
7. **Verify deployment** and run health checks

## 🎉 Success Indicators

Your deployment is successful when:
- ✅ https://vps.bolk.dev loads your blog
- ✅ https://vps.bolk.dev/health returns JSON health data
- ✅ SSL certificate shows as valid in browser
- ✅ `docker-compose ps` shows all containers "Up"

## 🛠️ Alternative Deployment Methods

### Method 1: Automated (Recommended)
```bash
./deploy-vps-bolk-dev.sh
```

### Method 2: Manual Upload
```bash
scp -r . root@31.97.47.51:/opt/bolk-blog/
ssh root@31.97.47.51
cd /opt/bolk-blog
sudo ./deploy.sh production
```

### Method 3: Git Clone on VPS
```bash
ssh root@31.97.47.51
cd /opt
git clone https://github.com/B0LK13/B0LK13.git bolk-blog
cd bolk-blog
# Then copy files from this package and run deployment
```

## 🚨 Troubleshooting

### Common Issues

#### SSH Connection Failed
```bash
# Check if SSH service is running
ssh -v root@31.97.47.51
```

#### Port Conflicts
```bash
# Check what's using ports 80/443
sudo lsof -i :80
sudo lsof -i :443
```

#### Docker Issues
```bash
# Manual Docker installation
curl -fsSL https://get.docker.com | sh
```

#### SSL Certificate Problems
```bash
# Manual certificate generation
sudo certbot certonly --standalone -d vps.bolk.dev
```

## 📞 Post-Deployment Commands

### Monitoring
```bash
# Performance monitoring
./scripts/performance-monitor.sh

# Quick health check
./scripts/quick-deploy-check.sh

# Deployment verification
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

# System information
sysinfo
```

## 📧 Support

If you need help:
1. **Check logs:** `docker-compose logs`
2. **Run health check:** `./scripts/quick-deploy-check.sh`
3. **Review documentation:** See other .md files in this folder
4. **Check system resources:** `free -h && df -h`

## 🎯 Ready to Deploy?

1. **Open terminal** in this folder
2. **Test SSH:** `ssh root@31.97.47.51`
3. **Run deployment:** `./deploy-vps-bolk-dev.sh`
4. **Wait 10-15 minutes** for completion
5. **Visit:** https://vps.bolk.dev

---

**🚀 Your optimized VPS deployment is ready to go!**

Everything is pre-configured for your VPS. Just run the deployment script and your high-performance blog will be live!
