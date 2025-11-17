#!/bin/bash

# Performance Monitoring Script for VPS.BOLK.DEV
# This script monitors system performance and sends alerts

# Configuration
ALERT_EMAIL="${ALERT_EMAIL:-admin@bolk.dev}"
WEBHOOK_URL="${WEBHOOK_URL:-}"
LOG_FILE="/var/log/performance-monitor.log"
THRESHOLD_CPU=80
THRESHOLD_MEMORY=85
THRESHOLD_DISK=90
THRESHOLD_RESPONSE_TIME=5000

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Logging function
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}" | tee -a $LOG_FILE
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}" | tee -a $LOG_FILE
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" | tee -a $LOG_FILE
}

# Send alert function
send_alert() {
    local message="$1"
    local severity="$2"
    
    # Send to webhook if configured
    if [ ! -z "$WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
            --data "{\"text\":\"🚨 VPS Alert [$severity]: $message\"}" \
            "$WEBHOOK_URL" 2>/dev/null
    fi
    
    # Log the alert
    case $severity in
        "CRITICAL") error "$message" ;;
        "WARNING") warn "$message" ;;
        *) log "$message" ;;
    esac
}

# Check CPU usage
check_cpu() {
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F'%' '{print $1}')
    cpu_usage=${cpu_usage%.*}  # Remove decimal part
    
    if [ "$cpu_usage" -gt "$THRESHOLD_CPU" ]; then
        send_alert "High CPU usage: ${cpu_usage}%" "WARNING"
        return 1
    fi
    
    log "CPU usage: ${cpu_usage}% (OK)"
    return 0
}

# Check memory usage
check_memory() {
    local memory_usage=$(free | grep Mem | awk '{printf("%.0f", $3/$2 * 100.0)}')
    
    if [ "$memory_usage" -gt "$THRESHOLD_MEMORY" ]; then
        send_alert "High memory usage: ${memory_usage}%" "WARNING"
        return 1
    fi
    
    log "Memory usage: ${memory_usage}% (OK)"
    return 0
}

# Check disk usage
check_disk() {
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    
    if [ "$disk_usage" -gt "$THRESHOLD_DISK" ]; then
        send_alert "High disk usage: ${disk_usage}%" "CRITICAL"
        return 1
    fi
    
    log "Disk usage: ${disk_usage}% (OK)"
    return 0
}

# Check application response time
check_response_time() {
    local start_time=$(date +%s%3N)
    local response=$(curl -s -o /dev/null -w "%{http_code}" http://localhost:3000/api/health)
    local end_time=$(date +%s%3N)
    local response_time=$((end_time - start_time))
    
    if [ "$response" != "200" ]; then
        send_alert "Application not responding (HTTP $response)" "CRITICAL"
        return 1
    fi
    
    if [ "$response_time" -gt "$THRESHOLD_RESPONSE_TIME" ]; then
        send_alert "Slow response time: ${response_time}ms" "WARNING"
        return 1
    fi
    
    log "Response time: ${response_time}ms (OK)"
    return 0
}

# Check Docker containers
check_containers() {
    local unhealthy_containers=$(docker ps --filter "health=unhealthy" --format "table {{.Names}}" | tail -n +2)
    
    if [ ! -z "$unhealthy_containers" ]; then
        send_alert "Unhealthy containers: $unhealthy_containers" "CRITICAL"
        return 1
    fi
    
    local stopped_containers=$(docker ps -a --filter "status=exited" --format "table {{.Names}}" | tail -n +2)
    
    if [ ! -z "$stopped_containers" ]; then
        send_alert "Stopped containers: $stopped_containers" "WARNING"
        return 1
    fi
    
    log "All containers healthy (OK)"
    return 0
}

# Check SSL certificate expiration
check_ssl_expiry() {
    local cert_file="nginx/ssl/vps.bolk.dev.crt"
    
    if [ -f "$cert_file" ]; then
        local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" | cut -d= -f2)
        local expiry_timestamp=$(date -d "$expiry_date" +%s)
        local current_timestamp=$(date +%s)
        local days_until_expiry=$(( (expiry_timestamp - current_timestamp) / 86400 ))
        
        if [ "$days_until_expiry" -lt 30 ]; then
            send_alert "SSL certificate expires in $days_until_expiry days" "WARNING"
            return 1
        fi
        
        log "SSL certificate expires in $days_until_expiry days (OK)"
    fi
    
    return 0
}

# Generate performance report
generate_report() {
    local report_file="/tmp/performance-report-$(date +%Y%m%d-%H%M%S).txt"
    
    {
        echo "=== VPS Performance Report ==="
        echo "Generated: $(date)"
        echo ""
        
        echo "=== System Information ==="
        uname -a
        echo ""
        
        echo "=== CPU Information ==="
        lscpu | grep -E "Model name|CPU\(s\)|Thread"
        echo ""
        
        echo "=== Memory Usage ==="
        free -h
        echo ""
        
        echo "=== Disk Usage ==="
        df -h
        echo ""
        
        echo "=== Network Connections ==="
        netstat -tuln | head -20
        echo ""
        
        echo "=== Docker Containers ==="
        docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"
        echo ""
        
        echo "=== Recent Logs ==="
        tail -20 $LOG_FILE
        
    } > "$report_file"
    
    log "Performance report generated: $report_file"
}

# Main monitoring function
main() {
    log "Starting performance monitoring check..."
    
    local issues=0
    
    check_cpu || ((issues++))
    check_memory || ((issues++))
    check_disk || ((issues++))
    check_response_time || ((issues++))
    check_containers || ((issues++))
    check_ssl_expiry || ((issues++))
    
    if [ "$issues" -eq 0 ]; then
        log "All systems operational ✅"
    else
        warn "Found $issues issue(s) during monitoring"
    fi
    
    # Generate report if requested
    if [ "$1" = "--report" ]; then
        generate_report
    fi
    
    log "Monitoring check completed"
}

# Create log directory if it doesn't exist
mkdir -p "$(dirname "$LOG_FILE")"

# Run main function
main "$@"
