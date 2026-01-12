#!/bin/bash

################################################################################
# Phase 1: Foundation Building - Main Setup Script
# 
# This script sets up the AI-ready infrastructure for an Agentic SOC.
# It orchestrates all Phase 1 components.
#
# Duration: ~30-60 minutes
# Prerequisites: Linux system with sudo privileges
#
# What this phase does:
# - Install core dependencies (Python, Docker, etc.)
# - Set up SIEM/EDR platform connections
# - Install AI frameworks (OpenAI SDK, CrewAI)
# - Prepare data directories and initial datasets
#
# Expected output:
# - AI-ready environment
# - Basic agent prototype
# - Configured SIEM/EDR API connections
################################################################################

set -e

# Get script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"

# Source common utilities
source "$DEPLOY_DIR/common/utils.sh"

# Set up error handling
trap_errors

# Main execution
main() {
    print_header "PHASE 1: FOUNDATION BUILDING"
    
    log_info "Starting Phase 1 deployment..."
    log_info "This will set up the AI-ready infrastructure for the Agentic SOC"
    
    # Check prerequisites
    check_root
    check_system_requirements
    check_network
    
    # Set up logging
    setup_logging
    
    # Load configuration
    if [[ -f "$DEPLOY_DIR/.env" ]]; then
        load_env "$DEPLOY_DIR/.env"
    else
        log_warning "No .env file found. Using defaults and prompting for required values."
        log_info "Consider creating .env from config/.env.example for automated setup"
    fi
    
    # Run Phase 1 components
    print_header "Step 1: Installing Core Dependencies"
    "$SCRIPT_DIR/install_core_deps.sh"
    
    print_header "Step 2: Installing AI Frameworks"
    "$SCRIPT_DIR/install_ai_frameworks.sh"
    
    print_header "Step 3: Setting up SIEM/EDR Integration"
    "$SCRIPT_DIR/install_siem_edr.sh"
    
    print_header "Step 4: Preparing Data Environment"
    "$SCRIPT_DIR/prepare_data.sh"
    
    # Validation
    print_header "Validating Phase 1 Installation"
    validate_phase1
    
    # Success message
    print_completion "PHASE 1: FOUNDATION BUILDING"
    
    log_info "Next steps:"
    log_info "1. Review the installation logs at /var/log/agentic-soc/phase1_foundation.log"
    log_info "2. Verify API connections to SIEM/EDR platforms"
    log_info "3. Proceed to Phase 2: cd ../phase2 && ./setup.sh"
    echo
}

# Validate Phase 1 installation
validate_phase1() {
    log_info "Running validation checks..."
    
    local errors=0
    
    # Check Python
    if ! command_exists python3; then
        log_error "Python 3 not found"
        errors=$((errors + 1))
    else
        log_success "✓ Python 3 installed"
    fi
    
    # Check Docker
    if ! command_exists docker; then
        log_error "Docker not found"
        errors=$((errors + 1))
    else
        log_success "✓ Docker installed"
    fi
    
    # Check virtual environment
    if [[ ! -d "$DEPLOY_DIR/.venv" ]]; then
        log_error "Python virtual environment not found"
        errors=$((errors + 1))
    else
        log_success "✓ Python virtual environment created"
    fi
    
    # Check if OpenAI package is installed
    if source "$DEPLOY_DIR/.venv/bin/activate" && python -c "import openai" 2>/dev/null; then
        log_success "✓ OpenAI package installed"
    else
        log_error "OpenAI package not found in virtual environment"
        errors=$((errors + 1))
    fi
    
    # Check data directories
    if [[ -d "$DEPLOY_DIR/data" ]]; then
        log_success "✓ Data directories created"
    else
        log_error "Data directories not found"
        errors=$((errors + 1))
    fi
    
    if [[ $errors -eq 0 ]]; then
        log_success "All validation checks passed!"
        return 0
    else
        log_error "$errors validation check(s) failed"
        return 1
    fi
}

# Run main function
main "$@"
