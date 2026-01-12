# 🚀 VPS Deployment Checklist for vps.bolk.dev

## Pre-Deployment Checklist

### ✅ Prerequisites
- [ ] VPS server with Ubuntu 20.04+ and root access
- [ ] Domain `vps.bolk.dev` pointing to your VPS IP address
- [ ] SSH key-based authentication configured
- [ ] VPS has at least 2GB RAM and 20GB storage
- [ ] Git installed on your local machine

### ✅ DNS Configuration
Before deployment, ensure your domain is properly configured:

```bash
# Test DNS resolution
nslookup vps.bolk.dev
dig vps.bolk.dev

# Should return your VPS IP address
```

### ✅ SSH Access Test
```bash
# Test SSH connection (replace with your VPS IP)
ssh root@YOUR_VPS_IP
# or if using a different user:
ssh your_username@YOUR_VPS_IP
```

## Deployment Options

### Option 1: Automated Deployment (Recommended)

#### Step 1: Configure Deployment Script
```bash
# Edit the deployment script
nano deploy-vps-bolk-dev.sh

# Update line 12 with your actual VPS IP:
VPS_IP="YOUR_ACTUAL_VPS_IP"

# If not using root, update line 11:
VPS_USER="your_username"
```

#### Step 2: Make Script Executable
```bash
chmod +x deploy-vps-bolk-dev.sh
```

#### Step 3: Run Automated Deployment
```bash
./deploy-vps-bolk-dev.sh
```

The script will:
- ✅ Test SSH connection
- ✅ Upload all files to VPS
- ✅ Run system optimization
- ✅ Deploy Docker containers
- ✅ Setup SSL certificates
- ✅ Verify deployment

### Option 2: Manual Deployment

If the automated script fails, follow these manual steps:

#### Step 1: Connect to VPS
```bash
ssh root@YOUR_VPS_IP
```

#### Step 2: Clone Repository
```bash
cd /opt
git clone https://github.com/B0LK13/B0LK13.git bolk-blog
cd bolk-blog
```

#### Step 3: Configure Environment
```bash
cp .env.example .env
nano .env
```

Set these variables in .env:
```env
NODE_ENV=production
BLOG_NAME=B0LK13 Blog
BLOG_TITLE=B0LK13's Tech Blog
GITHUB_USERNAME=B0LK13
OPENAI_API_KEY=your_openai_key_here
```

#### Step 4: Make Scripts Executable
```bash
chmod +x deploy.sh
chmod +x scripts/*.sh
```

#### Step 5: Run System Optimization
```bash
sudo ./scripts/optimize-vps.sh
```

#### Step 6: Deploy Application
```bash
sudo ./deploy.sh production
```

#### Step 7: Setup SSL Certificate
```bash
# Install Certbot
sudo apt install -y certbot

# Stop nginx temporarily
sudo docker-compose stop nginx

# Get SSL certificate
sudo certbot certonly --standalone -d vps.bolk.dev --non-interactive --agree-tos --email admin@vps.bolk.dev

# Copy certificates
sudo cp /etc/letsencrypt/live/vps.bolk.dev/fullchain.pem nginx/ssl/vps.bolk.dev.crt
sudo cp /etc/letsencrypt/live/vps.bolk.dev/privkey.pem nginx/ssl/vps.bolk.dev.key

# Restart services
sudo docker-compose up -d
```

#### Step 8: Verify Deployment
```bash
./scripts/verify-deployment.sh
```

## Post-Deployment Verification

### ✅ Test Application
```bash
# Test health endpoint
curl https://vps.bolk.dev/health

# Test main page
curl -I https://vps.bolk.dev

# Check SSL certificate
openssl s_client -connect vps.bolk.dev:443 -servername vps.bolk.dev
```

### ✅ Check Container Status
```bash
docker-compose ps
```

Expected output:
```
    Name                   Command               State                    Ports
-----------------------------------------------------------------------------------------
bolk-blog      docker-entrypoint.sh node ...   Up      3000/tcp
bolk-nginx     /docker-entrypoint.sh ngin ...   Up      0.0.0.0:443->443/tcp, 0.0.0.0:80->80/tcp
bolk-redis     docker-entrypoint.sh redis ...   Up      6379/tcp
```

### ✅ Performance Check
```bash
# Run performance monitoring
./scripts/performance-monitor.sh

# Generate performance report
./scripts/performance-monitor.sh --report
```

## Troubleshooting

### Common Issues and Solutions

#### 1. SSH Connection Failed
```bash
# Check if SSH service is running
sudo systemctl status ssh

# Check firewall
sudo ufw status

# Ensure port 22 is open
sudo ufw allow ssh
```

#### 2. Domain Not Resolving
```bash
# Check DNS propagation
nslookup vps.bolk.dev
dig vps.bolk.dev

# Wait for DNS propagation (can take up to 48 hours)
```

#### 3. Docker Installation Failed
```bash
# Manual Docker installation
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo systemctl enable docker
sudo systemctl start docker

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
```

#### 4. SSL Certificate Issues
```bash
# Check if port 80 is free
sudo lsof -i :80

# Stop any conflicting services
sudo systemctl stop apache2  # if Apache is running
sudo systemctl stop nginx    # if Nginx is running

# Try SSL setup again
sudo certbot certonly --standalone -d vps.bolk.dev
```

#### 5. Application Not Starting
```bash
# Check logs
docker-compose logs nextjs-app

# Rebuild containers
docker-compose down
docker-compose up -d --build

# Check disk space
df -h

# Check memory
free -h
```

#### 6. Port 80/443 Already in Use
```bash
# Find what's using the ports
sudo lsof -i :80
sudo lsof -i :443

# Stop conflicting services
sudo systemctl stop apache2
sudo systemctl stop nginx
sudo systemctl disable apache2
sudo systemctl disable nginx
```

## Success Indicators

### ✅ Deployment Successful When:
- [ ] All containers are running (`docker-compose ps`)
- [ ] Health check returns 200 (`curl https://vps.bolk.dev/health`)
- [ ] Main site loads (`curl https://vps.bolk.dev`)
- [ ] SSL certificate is valid (A+ rating on SSL Labs)
- [ ] Performance monitoring shows good metrics
- [ ] No errors in container logs

### ✅ Expected Performance:
- **Load Time**: < 2 seconds
- **TTFB**: < 500ms
- **SSL Rating**: A+
- **HTTP/2**: Enabled
- **Compression**: Active

## Monitoring Commands

After successful deployment, use these commands for ongoing monitoring:

```bash
# Check application status
docker-compose ps

# View logs
docker-compose logs -f nextjs-app

# Monitor performance
./scripts/performance-monitor.sh

# System information
sysinfo

# Container resource usage
docker stats

# Check SSL certificate expiry
openssl x509 -enddate -noout -in nginx/ssl/vps.bolk.dev.crt
```

## Maintenance

### Daily
- Automated backups run at 2 AM
- Performance monitoring every 5 minutes
- Security updates (automatic)

### Weekly
- Review performance reports
- Check log files
- Verify SSL certificate status

### Monthly
- Update Docker images
- Clean old backups
- Security audit

## Support

If you encounter issues:
1. Check logs: `docker-compose logs`
2. Run health check: `curl https://vps.bolk.dev/health`
3. Check system resources: `sysinfo`
4. Review monitoring reports: `./scripts/performance-monitor.sh --report`

Your optimized VPS deployment is ready! 🚀
