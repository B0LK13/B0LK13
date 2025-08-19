# VPS Optimization Guide for B0LK13 Blog

This guide provides comprehensive VPS optimization for your Next.js blog application at `vps.bolk.dev`.

## 🚀 Quick Start

1. **Clone and setup**:
   ```bash
   git clone <your-repo>
   cd <your-repo>
   cp .env.example .env
   # Edit .env with your configuration
   ```

2. **Deploy to VPS**:
   ```bash
   sudo ./deploy.sh production
   ```

## 📋 What's Been Optimized

### 🐳 Docker Configuration
- **Multi-stage build** for minimal production image
- **Alpine Linux** base for security and size
- **Non-root user** for security
- **Health checks** for reliability

### 🌐 Nginx Reverse Proxy
- **HTTP/2** support
- **Gzip compression** for faster loading
- **Rate limiting** to prevent abuse
- **Security headers** for protection
- **SSL/TLS** configuration
- **Static asset caching** for performance

### ⚡ Next.js Optimizations
- **Standalone output** for Docker
- **Image optimization** with WebP/AVIF
- **Bundle splitting** for faster loading
- **SWC minification** for smaller bundles
- **Security headers** built-in

### 🔧 Performance Features
- **Redis caching** for session storage
- **Health monitoring** endpoint
- **Automatic restarts** on failure
- **Log rotation** and monitoring
- **Memory optimization**

## 🛠️ Manual Setup Steps

### 1. Server Requirements
- Ubuntu 20.04+ or similar Linux distribution
- 2GB+ RAM recommended
- 20GB+ storage
- Root or sudo access

### 2. Domain Configuration
Point your domain `vps.bolk.dev` to your VPS IP address:
```bash
# A record
vps.bolk.dev -> YOUR_VPS_IP
```

### 3. SSL Certificate Setup
For production, replace self-signed certificates:
```bash
# Using Let's Encrypt (recommended)
sudo apt install certbot
sudo certbot certonly --standalone -d vps.bolk.dev
sudo cp /etc/letsencrypt/live/vps.bolk.dev/fullchain.pem nginx/ssl/vps.bolk.dev.crt
sudo cp /etc/letsencrypt/live/vps.bolk.dev/privkey.pem nginx/ssl/vps.bolk.dev.key
```

### 4. Environment Variables
Configure your `.env` file:
```bash
# Copy example and edit
cp .env.example .env
nano .env
```

## 🔍 Monitoring & Maintenance

### Health Checks
- Application: `https://vps.bolk.dev/health`
- Nginx status: `sudo systemctl status nginx`
- Docker containers: `docker-compose ps`

### Log Files
- Application logs: `docker-compose logs -f nextjs-app`
- Nginx logs: `tail -f logs/nginx/access.log`
- System logs: `/var/log/deploy.log`

### Performance Monitoring
```bash
# Check resource usage
docker stats

# Monitor disk space
df -h

# Check memory usage
free -h

# Network connections
netstat -tulpn
```

## 🔧 Troubleshooting

### Common Issues

1. **Port 80/443 already in use**:
   ```bash
   sudo lsof -i :80
   sudo lsof -i :443
   # Stop conflicting services
   ```

2. **SSL certificate errors**:
   ```bash
   # Check certificate validity
   openssl x509 -in nginx/ssl/vps.bolk.dev.crt -text -noout
   ```

3. **Container won't start**:
   ```bash
   # Check logs
   docker-compose logs nextjs-app
   
   # Rebuild without cache
   docker-compose build --no-cache
   ```

### Performance Tuning

1. **Increase Nginx worker processes**:
   Edit `nginx/nginx.conf` and set `worker_processes` to number of CPU cores.

2. **Optimize Redis memory**:
   ```bash
   # Edit docker-compose.yml
   command: redis-server --maxmemory 512mb --maxmemory-policy allkeys-lru
   ```

3. **Enable HTTP/3 (QUIC)**:
   Update Nginx to latest version and add HTTP/3 support.

## 🔐 Security Hardening

### Firewall Configuration
```bash
# UFW setup
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80
sudo ufw allow 443
sudo ufw enable
```

### Fail2Ban Setup
```bash
sudo apt install fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

### Regular Updates
```bash
# System updates
sudo apt update && sudo apt upgrade -y

# Docker image updates
docker-compose pull
docker-compose up -d
```

## 📊 Performance Benchmarks

Expected performance improvements:
- **Load time**: 40-60% faster with caching
- **TTFB**: Reduced by 30-50% with optimization
- **Bundle size**: 20-30% smaller with compression
- **Memory usage**: Optimized container footprint

## 🆘 Support

For issues or questions:
1. Check logs: `docker-compose logs`
2. Verify health: `curl https://vps.bolk.dev/health`
3. Monitor resources: `docker stats`

## 📝 Next Steps

1. Set up automated backups
2. Configure monitoring alerts
3. Implement CI/CD pipeline
4. Add database if needed
5. Set up CDN for global performance
