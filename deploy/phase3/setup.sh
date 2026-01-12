#!/bin/bash

################################################################################
# Phase 3: Integration & Orchestration - Main Setup Script
#
# This script sets up multi-agent orchestration, dashboard, and governance.
#
# Duration: ~2-3 hours
# Prerequisites: Phase 1 and Phase 2 completed
#
# What this phase does:
# - Configure multi-agent orchestration
# - Deploy monitoring dashboard (React + Grafana)
# - Implement governance controls and audit trails
# - Set up human-in-the-loop workflows
#
# Expected output:
# - Collaborative multi-agent system
# - Real-time dashboard
# - MTTI under 5 minutes in tests
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
source "$DEPLOY_DIR/common/utils.sh"

trap_errors

main() {
    print_header "PHASE 3: INTEGRATION & ORCHESTRATION"
    
    log_info "Starting Phase 3 deployment..."
    log_info "This will integrate agents and deploy the monitoring dashboard"
    
    # Verify previous phases
    verify_prerequisites
    
    # Load configuration
    load_env "$DEPLOY_DIR/.env"
    
    # Run Phase 3 components
    print_header "Step 1: Setting up Multi-Agent Orchestration"
    "$SCRIPT_DIR/setup_orchestration.sh"
    
    print_header "Step 2: Deploying Dashboard"
    "$SCRIPT_DIR/deploy_dashboard.sh"
    
    print_header "Step 3: Configuring Governance Controls"
    "$SCRIPT_DIR/configure_governance.sh"
    
    # Success message
    print_completion "PHASE 3: INTEGRATION & ORCHESTRATION"
    
    log_info "Next steps:"
    log_info "1. Access dashboard at http://localhost:3000"
    log_info "2. Review orchestration logs"
    log_info "3. Proceed to Phase 4: cd ../phase4 && ./setup.sh"
    echo
}

verify_prerequisites() {
    log_info "Verifying Phase 1 and Phase 2 completion..."
    
    if [[ ! -d "$DEPLOY_DIR/agents" ]]; then
        log_error "Phase 2 not completed: Agents directory not found"
        exit 1
    fi
    
    if [[ ! -f "$DEPLOY_DIR/phase2/deploy_triage_agent.py" ]]; then
        log_error "Phase 2 not completed: Triage agent not found"
        exit 1
    fi
    
    log_success "Prerequisites verified"
}

main "$@"
