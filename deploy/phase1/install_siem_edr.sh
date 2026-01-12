#!/bin/bash

################################################################################
# Phase 1: Setup SIEM/EDR Integration
#
# Configures integration with SIEM and EDR platforms.
# Supports: Elastic, Splunk, CrowdStrike, SentinelOne
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
source "$DEPLOY_DIR/common/utils.sh"

main() {
    log_info "Setting up SIEM/EDR integration..."
    
    # Activate virtual environment
    source "$DEPLOY_DIR/.venv/bin/activate"
    
    # Install SIEM/EDR client libraries
    log_info "Installing SIEM client libraries..."
    
    # Elasticsearch/Elastic Stack
    pip install elasticsearch>=8.0.0
    pip install elastic-apm
    
    # Splunk
    pip install splunk-sdk
    
    # General API clients
    pip install requests
    pip install httpx
    
    # EDR specific libraries
    log_info "Installing EDR client libraries..."
    
    # CrowdStrike Falcon
    pip install crowdstrike-falconpy
    
    # Microsoft Defender
    pip install msgraph-core
    pip install azure-identity
    
    # Carbon Black
    pip install cbapi
    
    # Create integration config directory
    ensure_directory "$DEPLOY_DIR/config/integrations"
    
    # Create SIEM configuration template
    create_siem_config
    
    # Create EDR configuration template
    create_edr_config
    
    # Test API connections if credentials are available
    if [[ -f "$DEPLOY_DIR/.env" ]]; then
        log_info "Testing API connections..."
        test_api_connections
    else
        log_warning "No .env file found. Skipping API connection tests."
        log_info "Configure .env and run this script again to test connections"
    fi
    
    log_success "SIEM/EDR integration setup completed"
}

create_siem_config() {
    local config_file="$DEPLOY_DIR/config/integrations/siem_config.yaml"
    
    if [[ -f "$config_file" ]]; then
        log_warning "SIEM config already exists: $config_file"
        return
    fi
    
    log_info "Creating SIEM configuration template..."
    
    cat > "$config_file" << 'EOF'
# SIEM Platform Configuration

# Elastic/Elasticsearch
elastic:
  enabled: true
  hosts:
    - http://localhost:9200
  username: elastic
  password: changeme
  verify_certs: false
  index_pattern: "alerts-*"
  
# Splunk
splunk:
  enabled: false
  host: localhost
  port: 8089
  token: ""
  username: admin
  password: changeme
  scheme: https
  verify: false
  index: main
  
# IBM QRadar
qradar:
  enabled: false
  host: localhost
  token: ""
  verify: false
  
# Microsoft Sentinel
sentinel:
  enabled: false
  workspace_id: ""
  shared_key: ""
  log_type: "CustomSecurityLog"

# Query settings
query:
  max_results: 1000
  timeout: 30
  retry_count: 3
EOF
    
    log_success "Created SIEM config: $config_file"
}

create_edr_config() {
    local config_file="$DEPLOY_DIR/config/integrations/edr_config.yaml"
    
    if [[ -f "$config_file" ]]; then
        log_warning "EDR config already exists: $config_file"
        return
    fi
    
    log_info "Creating EDR configuration template..."
    
    cat > "$config_file" << 'EOF'
# EDR Platform Configuration

# CrowdStrike Falcon
crowdstrike:
  enabled: true
  client_id: ""
  client_secret: ""
  base_url: "https://api.crowdstrike.com"
  cloud: "us-1"  # us-1, us-2, eu-1
  
# SentinelOne
sentinelone:
  enabled: false
  api_token: ""
  base_url: ""
  site_id: ""
  
# Microsoft Defender for Endpoint
defender:
  enabled: false
  tenant_id: ""
  client_id: ""
  client_secret: ""
  
# Carbon Black
carbonblack:
  enabled: false
  url: ""
  api_id: ""
  api_key: ""
  org_key: ""

# Response settings
response:
  isolation_enabled: false  # Require manual approval for endpoint isolation
  auto_remediation: false   # Require manual approval for auto-remediation
  timeout: 300
EOF
    
    log_success "Created EDR config: $config_file"
}

test_api_connections() {
    log_info "Testing API connections (this may take a moment)..."
    
    # Create a simple Python script to test connections
    cat > /tmp/test_connections.py << 'EOF'
#!/usr/bin/env python3
import os
import sys

def test_openai():
    """Test OpenAI API connection"""
    try:
        import openai
        api_key = os.getenv('OPENAI_API_KEY')
        if not api_key or api_key == 'sk-your-openai-api-key-here':
            print("⚠ OpenAI: API key not configured")
            return False
        
        client = openai.OpenAI(api_key=api_key)
        # Try to list models
        models = client.models.list()
        print("✓ OpenAI: Connection successful")
        return True
    except Exception as e:
        print(f"✗ OpenAI: Connection failed - {str(e)}")
        return False

def test_elastic():
    """Test Elasticsearch connection"""
    try:
        from elasticsearch import Elasticsearch
        host = os.getenv('ELASTIC_HOST', 'localhost')
        port = os.getenv('ELASTIC_PORT', '9200')
        username = os.getenv('ELASTIC_USERNAME', 'elastic')
        password = os.getenv('ELASTIC_PASSWORD')
        
        if not password or password == 'changeme':
            print("⚠ Elasticsearch: Credentials not configured")
            return False
        
        es = Elasticsearch(
            f"http://{host}:{port}",
            basic_auth=(username, password),
            verify_certs=False
        )
        if es.ping():
            print("✓ Elasticsearch: Connection successful")
            return True
        else:
            print("✗ Elasticsearch: Ping failed")
            return False
    except Exception as e:
        print(f"⚠ Elasticsearch: {str(e)}")
        return False

def main():
    print("Testing API connections...\n")
    
    results = []
    results.append(test_openai())
    results.append(test_elastic())
    
    print(f"\nConnection test summary: {sum(results)}/{len(results)} successful")
    
    if not any(results):
        print("\nNote: Configure API keys in .env to enable connection tests")

if __name__ == "__main__":
    main()
EOF
    
    chmod +x /tmp/test_connections.py
    python /tmp/test_connections.py
    rm /tmp/test_connections.py
}

main "$@"
