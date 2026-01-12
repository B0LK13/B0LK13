#!/bin/bash

################################################################################
# Common Utilities for AI Agentic SOC Deployment
# 
# This script provides shared functions used across all deployment phases.
# Source this file in other scripts: source ../common/utils.sh
################################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root. Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check system requirements
check_system_requirements() {
    log_info "Checking system requirements..."
    
    # Check OS
    if [[ ! -f /etc/os-release ]]; then
        log_error "Cannot detect OS. This script requires a Linux distribution."
        exit 1
    fi
    
    source /etc/os-release
    log_info "Detected OS: $NAME $VERSION"
    
    # Check RAM
    total_ram=$(free -g | awk '/^Mem:/{print $2}')
    if [[ $total_ram -lt 16 ]]; then
        log_warning "System has ${total_ram}GB RAM. Minimum 16GB recommended."
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        log_success "RAM check passed: ${total_ram}GB available"
    fi
    
    # Check disk space
    available_space=$(df -BG / | awk 'NR==2 {print $4}' | sed 's/G//')
    if [[ $available_space -lt 100 ]]; then
        log_warning "Available disk space: ${available_space}GB. Minimum 100GB recommended."
        read -p "Continue anyway? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        log_success "Disk space check passed: ${available_space}GB available"
    fi
}

# Install package based on distribution
install_package() {
    local package=$1
    
    if command_exists apt-get; then
        sudo apt-get install -y "$package"
    elif command_exists yum; then
        sudo yum install -y "$package"
    elif command_exists dnf; then
        sudo dnf install -y "$package"
    else
        log_error "Package manager not supported. Please install $package manually."
        return 1
    fi
}

# Check and install Python
check_python() {
    log_info "Checking Python installation..."
    
    if command_exists python3; then
        python_version=$(python3 --version | awk '{print $2}')
        log_info "Found Python $python_version"
        
        # Check if version is 3.9 or higher
        required_version="3.9"
        if [[ $(echo -e "$python_version\n$required_version" | sort -V | head -n1) == "$required_version" ]]; then
            log_success "Python version check passed"
            return 0
        else
            log_warning "Python version $python_version is below recommended 3.9+"
        fi
    fi
    
    log_info "Installing Python 3.9+..."
    install_package python3
    install_package python3-pip
    install_package python3-venv
}

# Create Python virtual environment
create_venv() {
    local venv_path=${1:-.venv}
    
    log_info "Creating Python virtual environment at $venv_path..."
    
    if [[ -d "$venv_path" ]]; then
        log_warning "Virtual environment already exists at $venv_path"
        read -p "Remove and recreate? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "$venv_path"
        else
            return 0
        fi
    fi
    
    python3 -m venv "$venv_path"
    log_success "Virtual environment created at $venv_path"
    
    # Activate and upgrade pip
    source "$venv_path/bin/activate"
    pip install --upgrade pip setuptools wheel
    log_success "Virtual environment activated and pip upgraded"
}

# Load environment variables
load_env() {
    local env_file=${1:-.env}
    
    if [[ -f "$env_file" ]]; then
        log_info "Loading environment variables from $env_file"
        set -a
        source "$env_file"
        set +a
        log_success "Environment variables loaded"
    else
        log_error "Environment file $env_file not found"
        log_info "Please copy config/.env.example to .env and configure it"
        exit 1
    fi
}

# Validate environment variables
validate_env_var() {
    local var_name=$1
    local var_value=${!var_name}
    
    if [[ -z "$var_value" ]]; then
        log_error "Required environment variable $var_name is not set"
        return 1
    fi
    
    log_success "Environment variable $var_name is set"
    return 0
}

# Create directory if it doesn't exist
ensure_directory() {
    local dir=$1
    
    if [[ ! -d "$dir" ]]; then
        log_info "Creating directory: $dir"
        mkdir -p "$dir"
        log_success "Directory created: $dir"
    fi
}

# Download file with retry
download_file() {
    local url=$1
    local output=$2
    local max_retries=${3:-3}
    local retry_count=0
    
    while [[ $retry_count -lt $max_retries ]]; do
        log_info "Downloading $url (attempt $((retry_count + 1))/$max_retries)..."
        
        if command_exists curl; then
            if curl -fsSL -o "$output" "$url"; then
                log_success "Downloaded $url to $output"
                return 0
            fi
        elif command_exists wget; then
            if wget -q -O "$output" "$url"; then
                log_success "Downloaded $url to $output"
                return 0
            fi
        else
            log_error "Neither curl nor wget is available"
            return 1
        fi
        
        retry_count=$((retry_count + 1))
        sleep 2
    done
    
    log_error "Failed to download $url after $max_retries attempts"
    return 1
}

# Check network connectivity
check_network() {
    log_info "Checking network connectivity..."
    
    if ping -c 1 8.8.8.8 >/dev/null 2>&1; then
        log_success "Network connectivity check passed"
        return 0
    else
        log_error "No network connectivity detected"
        return 1
    fi
}

# Verify API endpoint
verify_api_endpoint() {
    local endpoint=$1
    local auth_header=$2
    
    log_info "Verifying API endpoint: $endpoint"
    
    if [[ -n "$auth_header" ]]; then
        response=$(curl -s -o /dev/null -w "%{http_code}" -H "$auth_header" "$endpoint")
    else
        response=$(curl -s -o /dev/null -w "%{http_code}" "$endpoint")
    fi
    
    if [[ $response -eq 200 || $response -eq 401 ]]; then
        log_success "API endpoint is reachable: $endpoint (HTTP $response)"
        return 0
    else
        log_error "API endpoint returned HTTP $response: $endpoint"
        return 1
    fi
}

# Install Docker
install_docker() {
    if command_exists docker; then
        log_success "Docker is already installed"
        docker --version
        return 0
    fi
    
    log_info "Installing Docker..."
    
    # Install dependencies
    install_package apt-transport-https
    install_package ca-certificates
    install_package curl
    install_package gnupg
    install_package lsb-release
    
    # Add Docker's official GPG key
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    
    # Set up the stable repository
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    
    # Install Docker Engine
    sudo apt-get update
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    
    # Add current user to docker group
    sudo usermod -aG docker "$USER"
    
    log_success "Docker installed successfully"
    log_warning "Please log out and back in for group changes to take effect"
}

# Create log directory
setup_logging() {
    local log_dir="/var/log/agentic-soc"
    
    if [[ ! -d "$log_dir" ]]; then
        log_info "Creating log directory: $log_dir"
        sudo mkdir -p "$log_dir"
        sudo chown "$USER:$USER" "$log_dir"
        log_success "Log directory created: $log_dir"
    fi
}

# Cleanup temporary files
cleanup() {
    log_info "Cleaning up temporary files..."
    # Add cleanup logic as needed
    log_success "Cleanup completed"
}

# Trap errors and cleanup
trap_errors() {
    trap 'log_error "Script failed at line $LINENO"; cleanup; exit 1' ERR
    trap 'log_info "Script interrupted by user"; cleanup; exit 130' INT TERM
}

# Print section header
print_header() {
    local text=$1
    local width=80
    
    echo
    echo -e "${BLUE}$(printf '=%.0s' $(seq 1 $width))${NC}"
    echo -e "${BLUE}  $text${NC}"
    echo -e "${BLUE}$(printf '=%.0s' $(seq 1 $width))${NC}"
    echo
}

# Print script completion
print_completion() {
    local phase=$1
    
    echo
    log_success "═══════════════════════════════════════════════════════════════"
    log_success "  $phase COMPLETED SUCCESSFULLY"
    log_success "═══════════════════════════════════════════════════════════════"
    echo
}

# Export functions for use in other scripts
export -f log_info log_success log_warning log_error
export -f check_root command_exists check_system_requirements
export -f install_package check_python create_venv
export -f load_env validate_env_var ensure_directory
export -f download_file check_network verify_api_endpoint
export -f install_docker setup_logging cleanup trap_errors
export -f print_header print_completion
