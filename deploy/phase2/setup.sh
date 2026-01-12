#!/bin/bash

################################################################################
# Phase 2: Agent Development & Automation - Main Setup Script
#
# This script sets up the agent development environment and deploys
# specialized AI agents for security operations.
#
# Duration: ~1-2 hours
# Prerequisites: Phase 1 completed
#
# What this phase does:
# - Create Python virtual environment for agent development
# - Install LangChain, CrewAI, and dependencies
# - Deploy example triage agent
# - Set up testing sandbox with Atomic Red Team
# - Integrate SOAR capabilities
#
# Expected output:
# - Functional triage agent
# - Testing environment
# - 50% automation of alert handling
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
source "$DEPLOY_DIR/common/utils.sh"

trap_errors

main() {
    print_header "PHASE 2: AGENT DEVELOPMENT & AUTOMATION"
    
    log_info "Starting Phase 2 deployment..."
    log_info "This will build and deploy AI agents for security automation"
    
    # Verify Phase 1 completion
    verify_phase1
    
    # Load configuration
    load_env "$DEPLOY_DIR/.env"
    
    # Run Phase 2 components
    print_header "Step 1: Setting up Agent Development Environment"
    "$SCRIPT_DIR/setup_agent_env.sh"
    
    print_header "Step 2: Installing LangChain and CrewAI"
    "$SCRIPT_DIR/install_langchain.sh"
    
    print_header "Step 3: Deploying Triage Agent"
    source "$DEPLOY_DIR/.venv/bin/activate"
    python "$SCRIPT_DIR/deploy_triage_agent.py"
    
    print_header "Step 4: Setting up Testing Sandbox"
    "$SCRIPT_DIR/setup_sandbox.sh"
    
    print_header "Step 5: Testing Agent Functionality"
    test_agents
    
    # Success message
    print_completion "PHASE 2: AGENT DEVELOPMENT & AUTOMATION"
    
    log_info "Next steps:"
    log_info "1. Review agent logs at /var/log/agentic-soc/phase2_agents.log"
    log_info "2. Test the triage agent with sample alerts"
    log_info "3. Proceed to Phase 3: cd ../phase3 && ./setup.sh"
    echo
}

verify_phase1() {
    log_info "Verifying Phase 1 prerequisites..."
    
    if [[ ! -d "$DEPLOY_DIR/.venv" ]]; then
        log_error "Phase 1 not completed: Virtual environment not found"
        exit 1
    fi
    
    if [[ ! -f "$DEPLOY_DIR/.env" ]]; then
        log_error "Configuration file .env not found"
        log_info "Copy config/.env.example to .env and configure it"
        exit 1
    fi
    
    log_success "Phase 1 prerequisites verified"
}

test_agents() {
    log_info "Testing agent functionality..."
    
    source "$DEPLOY_DIR/.venv/bin/activate"
    
    # Run agent tests
    python "$SCRIPT_DIR/test_triage_agent.py"
    
    log_success "Agent tests completed"
}

main "$@"
