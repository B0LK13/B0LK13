#!/bin/bash

################################################################################
# Phase 2: Setup Testing Sandbox
#
# Creates a safe testing environment for agents using Atomic Red Team.
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
source "$DEPLOY_DIR/common/utils.sh"

main() {
    log_info "Setting up testing sandbox..."
    
    # Create sandbox directory
    ensure_directory "$DEPLOY_DIR/sandbox"
    
    # Install Atomic Red Team (optional, for advanced testing)
    setup_atomic_red_team
    
    # Create test data
    create_test_scenarios
    
    # Set up isolated Docker network
    setup_sandbox_network
    
    log_success "Testing sandbox setup completed"
}

setup_atomic_red_team() {
    log_info "Setting up Atomic Red Team for security testing..."
    
    local art_path="/opt/atomic-red-team"
    
    if [[ -d "$art_path" ]]; then
        log_warning "Atomic Red Team already installed at $art_path"
        return
    fi
    
    log_warning "Atomic Red Team setup requires administrative privileges"
    read -p "Install Atomic Red Team? (y/n): " -n 1 -r
    echo
    
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log_info "Skipping Atomic Red Team installation"
        return
    fi
    
    log_info "Cloning Atomic Red Team repository..."
    sudo mkdir -p /opt
    sudo git clone https://github.com/redcanaryco/atomic-red-team.git "$art_path" || true
    
    log_success "Atomic Red Team cloned to $art_path"
    log_info "Note: Use Atomic Red Team responsibly and only in authorized test environments"
}

create_test_scenarios() {
    log_info "Creating test scenarios..."
    
    cat > "$DEPLOY_DIR/sandbox/test_scenarios.json" << 'EOF'
{
  "scenarios": [
    {
      "id": "scenario-001",
      "name": "Suspicious Login Test",
      "description": "Test triage agent response to suspicious login alerts",
      "alerts": [
        {
          "id": "TEST-001",
          "type": "Suspicious Login",
          "severity": "high",
          "source": "SIEM",
          "source_ip": "185.220.101.45",
          "destination_ip": "10.0.1.100",
          "user": "admin",
          "description": "Login from unusual location (Russia) with 15 failed attempts",
          "timestamp": "2026-01-12T23:00:00Z"
        }
      ],
      "expected_priority": "high",
      "expected_actions": ["investigate", "block_ip", "notify_admin"]
    },
    {
      "id": "scenario-002",
      "name": "Malware Detection Test",
      "description": "Test agent response to malware detection",
      "alerts": [
        {
          "id": "TEST-002",
          "type": "Malware Detection",
          "severity": "critical",
          "source": "EDR",
          "source_ip": "10.0.2.50",
          "destination_ip": "0.0.0.0",
          "user": "user123",
          "description": "Trojan detected: Win32/Emotet",
          "timestamp": "2026-01-12T22:30:00Z"
        }
      ],
      "expected_priority": "critical",
      "expected_actions": ["isolate_endpoint", "quarantine_file", "investigate"]
    },
    {
      "id": "scenario-003",
      "name": "Port Scan Test",
      "description": "Test agent response to port scanning activity",
      "alerts": [
        {
          "id": "TEST-003",
          "type": "Port Scan",
          "severity": "medium",
          "source": "Firewall",
          "source_ip": "192.168.1.100",
          "destination_ip": "10.0.0.0/24",
          "user": "N/A",
          "description": "Port scan detected from internal host",
          "timestamp": "2026-01-12T21:00:00Z"
        }
      ],
      "expected_priority": "medium",
      "expected_actions": ["investigate", "check_asset"]
    }
  ]
}
EOF
    
    log_success "Test scenarios created"
}

setup_sandbox_network() {
    log_info "Setting up isolated Docker network for sandbox..."
    
    # Create isolated network
    if ! docker network ls | grep -q "agentic-soc-sandbox"; then
        docker network create --driver bridge \
            --subnet=172.20.0.0/16 \
            --opt com.docker.network.bridge.enable_icc=false \
            agentic-soc-sandbox
        log_success "Sandbox network created"
    else
        log_warning "Sandbox network already exists"
    fi
    
    # Create sandbox docker-compose
    cat > "$DEPLOY_DIR/sandbox/docker-compose.sandbox.yml" << 'EOF'
version: '3.8'

services:
  # Isolated test SIEM
  test-siem:
    image: elasticsearch:8.11.0
    container_name: sandbox-siem
    environment:
      - discovery.type=single-node
      - xpack.security.enabled=false
      - "ES_JAVA_OPTS=-Xms512m -Xmx512m"
    networks:
      - sandbox
    ports:
      - "9201:9200"
    volumes:
      - test_siem_data:/usr/share/elasticsearch/data
  
  # Test agent runner
  test-agent:
    image: python:3.11-slim
    container_name: sandbox-agent
    working_dir: /app
    volumes:
      - ../:/app
    networks:
      - sandbox
    command: sleep infinity

networks:
  sandbox:
    external: true
    name: agentic-soc-sandbox

volumes:
  test_siem_data:
EOF
    
    log_success "Sandbox Docker Compose configuration created"
    log_info "Start sandbox with: cd sandbox && docker-compose -f docker-compose.sandbox.yml up -d"
}

main "$@"
