#!/bin/bash

# Deployment Verification Script
# This script verifies that your VPS deployment is working correctly

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Counters
PASSED=0
FAILED=0

log_pass() {
    echo -e "${GREEN}✅ PASS: $1${NC}"
    ((PASSED++))
}

log_fail() {
    echo -e "${RED}❌ FAIL: $1${NC}"
    ((FAILED++))
}

log_warn() {
    echo -e "${YELLOW}⚠️  WARN: $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  INFO: $1${NC}"
}

# Test Docker installation
test_docker() {
    log_info "Testing Docker installation..."
    
    if command -v docker &> /dev/null; then
        log_pass "Docker is installed"
        
        if docker --version &> /dev/null; then
            log_pass "Docker is running"
        else
            log_fail "Docker is not running"
        fi
    else
        log_fail "Docker is not installed"
    fi
    
    if command -v docker-compose &> /dev/null; then
        log_pass "Docker Compose is installed"
    else
        log_fail "Docker Compose is not installed"
    fi
}

# Test container status
test_containers() {
    log_info "Testing container status..."
    
    if docker-compose ps | grep -q "Up"; then
        log_pass "Containers are running"
        
        # Check specific containers
        if docker-compose ps | grep -q "bolk-blog.*Up"; then
            log_pass "Next.js application container is running"
        else
            log_fail "Next.js application container is not running"
        fi
        
        if docker-compose ps | grep -q "bolk-nginx.*Up"; then
            log_pass "Nginx container is running"
        else
            log_fail "Nginx container is not running"
        fi
        
        if docker-compose ps | grep -q "bolk-redis.*Up"; then
            log_pass "Redis container is running"
        else
            log_fail "Redis container is not running"
        fi
    else
        log_fail "No containers are running"
    fi
}

# Test application health
test_application() {
    log_info "Testing application health..."
    
    # Test local health endpoint
    if curl -f -s http://localhost:3000/api/health > /dev/null; then
        log_pass "Application health check passes (local)"
    else
        log_fail "Application health check fails (local)"
    fi
    
    # Test response time
    local start_time=$(date +%s%3N)
    curl -s http://localhost:3000/api/health > /dev/null
    local end_time=$(date +%s%3N)
    local response_time=$((end_time - start_time))
    
    if [ "$response_time" -lt 2000 ]; then
        log_pass "Response time is good (${response_time}ms)"
    else
        log_warn "Response time is slow (${response_time}ms)"
    fi
}

# Test Nginx configuration
test_nginx() {
    log_info "Testing Nginx configuration..."
    
    # Test Nginx config syntax
    if docker-compose exec nginx nginx -t &> /dev/null; then
        log_pass "Nginx configuration is valid"
    else
        log_fail "Nginx configuration has errors"
    fi
    
    # Test HTTP redirect
    local http_response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost)
    if [ "$http_response" = "301" ] || [ "$http_response" = "302" ]; then
        log_pass "HTTP to HTTPS redirect is working"
    else
        log_warn "HTTP to HTTPS redirect may not be configured"
    fi
}

# Test SSL certificate
test_ssl() {
    log_info "Testing SSL certificate..."
    
    if [ -f "nginx/ssl/vps.bolk.dev.crt" ]; then
        log_pass "SSL certificate file exists"

        # Check certificate validity
        local expiry_date=$(openssl x509 -enddate -noout -in nginx/ssl/vps.bolk.dev.crt 2>/dev/null | cut -d= -f2)
        if [ ! -z "$expiry_date" ]; then
            local expiry_timestamp=$(date -d "$expiry_date" +%s 2>/dev/null)
            local current_timestamp=$(date +%s)
            local days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
            
            if [ "$days_until_expiry" -gt 30 ]; then
                log_pass "SSL certificate is valid for $days_until_expiry days"
            elif [ "$days_until_expiry" -gt 0 ]; then
                log_warn "SSL certificate expires in $days_until_expiry days"
            else
                log_fail "SSL certificate has expired"
            fi
        fi
    else
        log_fail "SSL certificate file not found"
    fi
    
    if [ -f "nginx/ssl/vps.bolk.dev.key" ]; then
        log_pass "SSL private key file exists"
    else
        log_fail "SSL private key file not found"
    fi
}

# Test system resources
test_resources() {
    log_info "Testing system resources..."
    
    # Check memory usage
    local memory_usage=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
    if [ "$memory_usage" -lt 80 ]; then
        log_pass "Memory usage is acceptable (${memory_usage}%)"
    else
        log_warn "Memory usage is high (${memory_usage}%)"
    fi
    
    # Check disk usage
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    if [ "$disk_usage" -lt 80 ]; then
        log_pass "Disk usage is acceptable (${disk_usage}%)"
    else
        log_warn "Disk usage is high (${disk_usage}%)"
    fi
    
    # Check load average
    local load_avg=$(uptime | awk -F'load average:' '{print $2}' | awk '{print $1}' | sed 's/,//')
    local cpu_count=$(nproc)
    local load_percentage=$(echo "$load_avg * 100 / $cpu_count" | bc -l | cut -d. -f1)
    
    if [ "$load_percentage" -lt 70 ]; then
        log_pass "System load is acceptable (${load_avg})"
    else
        log_warn "System load is high (${load_avg})"
    fi
}

# Test security
test_security() {
    log_info "Testing security configuration..."
    
    # Check if fail2ban is running
    if systemctl is-active --quiet fail2ban; then
        log_pass "Fail2Ban is active"
    else
        log_warn "Fail2Ban is not active"
    fi
    
    # Check firewall status
    if command -v ufw &> /dev/null; then
        if ufw status | grep -q "Status: active"; then
            log_pass "UFW firewall is active"
        else
            log_warn "UFW firewall is not active"
        fi
    else
        log_warn "UFW firewall is not installed"
    fi
}

# Test monitoring
test_monitoring() {
    log_info "Testing monitoring setup..."
    
    if [ -f "scripts/performance-monitor.sh" ]; then
        log_pass "Performance monitoring script exists"
        
        if [ -x "scripts/performance-monitor.sh" ]; then
            log_pass "Performance monitoring script is executable"
        else
            log_fail "Performance monitoring script is not executable"
        fi
    else
        log_fail "Performance monitoring script not found"
    fi
    
    # Check if monitoring is in crontab
    if crontab -l 2>/dev/null | grep -q "performance-monitor.sh"; then
        log_pass "Performance monitoring is scheduled in crontab"
    else
        log_warn "Performance monitoring is not scheduled in crontab"
    fi
}

# Main verification function
main() {
    echo "🔍 VPS Deployment Verification"
    echo "=============================="
    echo ""
    
    test_docker
    echo ""
    test_containers
    echo ""
    test_application
    echo ""
    test_nginx
    echo ""
    test_ssl
    echo ""
    test_resources
    echo ""
    test_security
    echo ""
    test_monitoring
    echo ""
    
    echo "=============================="
    echo "📊 Verification Summary"
    echo "=============================="
    echo -e "${GREEN}Passed: $PASSED${NC}"
    echo -e "${RED}Failed: $FAILED${NC}"
    echo ""
    
    if [ "$FAILED" -eq 0 ]; then
        echo -e "${GREEN}🎉 All tests passed! Your VPS deployment is working correctly.${NC}"
        exit 0
    else
        echo -e "${YELLOW}⚠️  Some tests failed. Please review the issues above.${NC}"
        exit 1
    fi
}

# Run verification
main "$@"
