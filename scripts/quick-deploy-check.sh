#!/bin/bash

# Quick Deployment Check for vps.bolk.dev
# Run this script to verify your deployment is working correctly

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DOMAIN="vps.bolk.dev"
PASSED=0
FAILED=0

log_pass() {
    echo -e "${GREEN}✅ $1${NC}"
    ((PASSED++))
}

log_fail() {
    echo -e "${RED}❌ $1${NC}"
    ((FAILED++))
}

log_warn() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

echo "🔍 Quick Deployment Check for $DOMAIN"
echo "======================================"
echo ""

# Test 1: DNS Resolution
log_info "Testing DNS resolution..."
if nslookup $DOMAIN > /dev/null 2>&1; then
    log_pass "DNS resolution working"
else
    log_fail "DNS resolution failed"
fi

# Test 2: HTTP Response
log_info "Testing HTTP response..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://$DOMAIN 2>/dev/null)
if [ "$HTTP_CODE" = "301" ] || [ "$HTTP_CODE" = "302" ]; then
    log_pass "HTTP redirect working (redirects to HTTPS)"
elif [ "$HTTP_CODE" = "200" ]; then
    log_warn "HTTP returns 200 (should redirect to HTTPS)"
else
    log_fail "HTTP not responding correctly (code: $HTTP_CODE)"
fi

# Test 3: HTTPS Response
log_info "Testing HTTPS response..."
HTTPS_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN 2>/dev/null)
if [ "$HTTPS_CODE" = "200" ]; then
    log_pass "HTTPS working correctly"
else
    log_fail "HTTPS not working (code: $HTTPS_CODE)"
fi

# Test 4: Health Endpoint
log_info "Testing health endpoint..."
HEALTH_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/health 2>/dev/null)
if [ "$HEALTH_CODE" = "200" ]; then
    log_pass "Health endpoint working"
else
    log_fail "Health endpoint not working (code: $HEALTH_CODE)"
fi

# Test 5: SSL Certificate
log_info "Testing SSL certificate..."
SSL_EXPIRY=$(echo | openssl s_client -servername $DOMAIN -connect $DOMAIN:443 2>/dev/null | openssl x509 -noout -dates 2>/dev/null | grep notAfter | cut -d= -f2)
if [ ! -z "$SSL_EXPIRY" ]; then
    log_pass "SSL certificate valid (expires: $SSL_EXPIRY)"
else
    log_fail "SSL certificate invalid or not found"
fi

# Test 6: HTTP/2 Support
log_info "Testing HTTP/2 support..."
if curl -s -I --http2 https://$DOMAIN 2>/dev/null | grep -q "HTTP/2"; then
    log_pass "HTTP/2 enabled"
else
    log_warn "HTTP/2 not detected"
fi

# Test 7: Compression
log_info "Testing compression..."
if curl -s -H "Accept-Encoding: gzip" -I https://$DOMAIN 2>/dev/null | grep -q "gzip"; then
    log_pass "Gzip compression enabled"
else
    log_warn "Gzip compression not detected"
fi

# Test 8: Response Time
log_info "Testing response time..."
RESPONSE_TIME=$(curl -s -o /dev/null -w "%{time_total}" https://$DOMAIN 2>/dev/null)
RESPONSE_MS=$(echo "$RESPONSE_TIME * 1000" | bc -l | cut -d. -f1)

if [ "$RESPONSE_MS" -lt 2000 ]; then
    log_pass "Response time good (${RESPONSE_MS}ms)"
elif [ "$RESPONSE_MS" -lt 5000 ]; then
    log_warn "Response time acceptable (${RESPONSE_MS}ms)"
else
    log_fail "Response time slow (${RESPONSE_MS}ms)"
fi

# Test 9: Security Headers
log_info "Testing security headers..."
HEADERS=$(curl -s -I https://$DOMAIN 2>/dev/null)
SECURITY_SCORE=0

if echo "$HEADERS" | grep -q "Strict-Transport-Security"; then
    ((SECURITY_SCORE++))
fi
if echo "$HEADERS" | grep -q "X-Frame-Options"; then
    ((SECURITY_SCORE++))
fi
if echo "$HEADERS" | grep -q "X-Content-Type-Options"; then
    ((SECURITY_SCORE++))
fi
if echo "$HEADERS" | grep -q "X-XSS-Protection"; then
    ((SECURITY_SCORE++))
fi

if [ "$SECURITY_SCORE" -ge 3 ]; then
    log_pass "Security headers present ($SECURITY_SCORE/4)"
elif [ "$SECURITY_SCORE" -ge 2 ]; then
    log_warn "Some security headers missing ($SECURITY_SCORE/4)"
else
    log_fail "Security headers mostly missing ($SECURITY_SCORE/4)"
fi

# Test 10: Email Agent Page
log_info "Testing email agent page..."
EMAIL_AGENT_CODE=$(curl -s -o /dev/null -w "%{http_code}" https://$DOMAIN/email-agent 2>/dev/null)
if [ "$EMAIL_AGENT_CODE" = "200" ]; then
    log_pass "Email agent page accessible"
else
    log_warn "Email agent page not accessible (code: $EMAIL_AGENT_CODE)"
fi

echo ""
echo "======================================"
echo "📊 Test Results Summary"
echo "======================================"
echo -e "${GREEN}Passed: $PASSED${NC}"
echo -e "${RED}Failed: $FAILED${NC}"
echo ""

if [ "$FAILED" -eq 0 ]; then
    echo -e "${GREEN}🎉 All critical tests passed! Your deployment is working correctly.${NC}"
    echo ""
    echo "🌐 Your site is live at: https://$DOMAIN"
    echo "🏥 Health check: https://$DOMAIN/health"
    echo "📧 Email agent: https://$DOMAIN/email-agent"
    echo ""
    echo "🔧 Next steps:"
    echo "- Monitor performance: ./scripts/performance-monitor.sh"
    echo "- Check logs: docker-compose logs -f"
    echo "- System info: sysinfo"
    exit 0
else
    echo -e "${YELLOW}⚠️  Some tests failed. Please review the issues above.${NC}"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "- Check container status: docker-compose ps"
    echo "- View logs: docker-compose logs"
    echo "- Verify DNS: nslookup $DOMAIN"
    echo "- Check SSL: openssl s_client -connect $DOMAIN:443"
    exit 1
fi
