#!/bin/bash

################################################################################
# Phase 1: Install Core Dependencies
#
# Installs essential system packages and tools required for the Agentic SOC.
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
source "$DEPLOY_DIR/common/utils.sh"

main() {
    log_info "Installing core system dependencies..."
    
    # Update package lists
    log_info "Updating package lists..."
    sudo apt-get update
    
    # Essential build tools
    log_info "Installing build essentials..."
    install_package build-essential
    install_package git
    install_package curl
    install_package wget
    install_package vim
    install_package jq
    
    # Python and dependencies
    log_info "Installing Python and development tools..."
    check_python
    install_package python3-dev
    install_package python3-pip
    install_package python3-venv
    
    # Upgrade pip
    log_info "Upgrading pip..."
    python3 -m pip install --upgrade pip
    
    # Docker
    log_info "Installing Docker..."
    install_docker
    
    # Docker Compose
    if ! command_exists docker-compose; then
        log_info "Installing Docker Compose..."
        sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        sudo chmod +x /usr/local/bin/docker-compose
        log_success "Docker Compose installed"
    else
        log_success "Docker Compose already installed"
    fi
    
    # PostgreSQL client (for database management)
    log_info "Installing PostgreSQL client..."
    install_package postgresql-client
    
    # Redis CLI (for queue management)
    log_info "Installing Redis tools..."
    install_package redis-tools
    
    # Network tools
    log_info "Installing network utilities..."
    install_package net-tools
    install_package netcat
    install_package nmap
    
    # Security tools
    log_info "Installing security utilities..."
    install_package openssl
    install_package gnupg
    
    # Monitoring tools
    log_info "Installing monitoring utilities..."
    install_package htop
    install_package iotop
    install_package iftop
    
    # Create virtual environment
    log_info "Creating Python virtual environment..."
    cd "$DEPLOY_DIR"
    create_venv ".venv"
    
    # Install base Python packages
    log_info "Installing base Python packages..."
    source "$DEPLOY_DIR/.venv/bin/activate"
    pip install --upgrade pip setuptools wheel
    pip install pyyaml python-dotenv requests
    
    log_success "Core dependencies installed successfully"
}

main "$@"
