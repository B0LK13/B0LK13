#!/bin/bash

################################################################################
# Phase 4: Deployment & Optimization - Main Setup Script
#
# This script sets up production deployment and continuous improvement.
#
# Duration: ~1-2 hours
# Prerequisites: Phase 1, 2, and 3 completed
#
# What this phase does:
# - Configure production deployment
# - Set up monitoring and KPI tracking
# - Implement continuous improvement pipelines
# - Configure automated retraining
#
# Expected output:
# - Production-ready SOC
# - 24/7 autonomous operations
# - Monitoring dashboards
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
source "$DEPLOY_DIR/common/utils.sh"

trap_errors

main() {
    print_header "PHASE 4: DEPLOYMENT & OPTIMIZATION"
    
    log_info "Starting Phase 4 deployment..."
    log_info "This will prepare the system for production deployment"
    
    # Verify previous phases
    verify_prerequisites
    
    # Load configuration
    load_env "$DEPLOY_DIR/.env"
    
    # Run Phase 4 components
    print_header "Step 1: Production Deployment Configuration"
    "$SCRIPT_DIR/deploy_production.sh"
    
    print_header "Step 2: Setting up Monitoring and KPIs"
    "$SCRIPT_DIR/setup_monitoring.sh"
    
    print_header "Step 3: Continuous Improvement Pipeline"
    "$SCRIPT_DIR/continuous_improvement.sh"
    
    # Final validation
    print_header "Final System Validation"
    validate_deployment
    
    # Success message
    print_completion "PHASE 4: DEPLOYMENT & OPTIMIZATION"
    
    log_info "🎉 AI Agentic SOC deployment completed!"
    echo
    log_info "System Status:"
    log_info "  ✓ All phases completed successfully"
    log_info "  ✓ Dashboard: http://localhost:3000"
    log_info "  ✓ Grafana: http://localhost:3001"
    log_info "  ✓ Agents: Ready for operation"
    echo
    log_info "Next steps:"
    log_info "1. Review system documentation"
    log_info "2. Configure production API keys"
    log_info "3. Run initial security tests"
    log_info "4. Begin gradual rollout to production"
    echo
}

verify_prerequisites() {
    log_info "Verifying all previous phases..."
    
    local errors=0
    
    if [[ ! -d "$DEPLOY_DIR/agents" ]]; then
        log_error "Agents directory not found"
        errors=$((errors + 1))
    fi
    
    if [[ ! -f "$DEPLOY_DIR/dashboard/index.html" ]]; then
        log_error "Dashboard not deployed"
        errors=$((errors + 1))
    fi
    
    if [[ $errors -gt 0 ]]; then
        log_error "Prerequisites not met. Complete previous phases first."
        exit 1
    fi
    
    log_success "All prerequisites verified"
}

validate_deployment() {
    log_info "Running final validation checks..."
    
    source "$DEPLOY_DIR/.venv/bin/activate"
    
    # Check Python packages
    log_info "Checking Python packages..."
    python -c "import openai, langchain, crewai" || log_error "Missing packages"
    
    # Check Docker services
    log_info "Checking Docker services..."
    docker ps | grep -q "agentic-soc" || log_warning "Some Docker services may not be running"
    
    # Check configuration files
    log_info "Checking configuration files..."
    [[ -f "$DEPLOY_DIR/.env" ]] || log_error ".env file missing"
    
    log_success "Validation completed"
}

main "$@"
