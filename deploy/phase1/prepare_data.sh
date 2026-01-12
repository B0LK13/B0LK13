#!/bin/bash

################################################################################
# Phase 1: Prepare Data Environment
#
# Sets up data directories, downloads sample datasets, and prepares
# the environment for AI agent training and operation.
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
source "$DEPLOY_DIR/common/utils.sh"

main() {
    log_info "Preparing data environment..."
    
    # Create directory structure
    create_directory_structure
    
    # Create sample data
    create_sample_data
    
    # Set up database
    setup_database
    
    # Create initial configuration
    create_initial_config
    
    log_success "Data environment prepared successfully"
}

create_directory_structure() {
    log_info "Creating directory structure..."
    
    # Main data directory
    ensure_directory "$DEPLOY_DIR/data"
    
    # Subdirectories
    ensure_directory "$DEPLOY_DIR/data/alerts"
    ensure_directory "$DEPLOY_DIR/data/investigations"
    ensure_directory "$DEPLOY_DIR/data/models"
    ensure_directory "$DEPLOY_DIR/data/logs"
    ensure_directory "$DEPLOY_DIR/data/exports"
    ensure_directory "$DEPLOY_DIR/data/backup"
    
    # Agent working directories
    ensure_directory "$DEPLOY_DIR/agents"
    ensure_directory "$DEPLOY_DIR/agents/triage"
    ensure_directory "$DEPLOY_DIR/agents/investigation"
    ensure_directory "$DEPLOY_DIR/agents/response"
    
    # Temporary and cache
    ensure_directory "$DEPLOY_DIR/.cache"
    ensure_directory "$DEPLOY_DIR/.tmp"
    
    log_success "Directory structure created"
}

create_sample_data() {
    log_info "Creating sample alert data..."
    
    # Activate virtual environment
    source "$DEPLOY_DIR/.venv/bin/activate"
    
    # Create Python script to generate sample data
    cat > /tmp/generate_sample_data.py << 'EOF'
#!/usr/bin/env python3
import json
import os
from datetime import datetime, timedelta
import random

def generate_sample_alerts(count=100):
    """Generate sample security alerts for testing"""
    
    alert_types = [
        "Suspicious Login",
        "Malware Detection",
        "Port Scan",
        "SQL Injection Attempt",
        "Privilege Escalation",
        "Data Exfiltration",
        "Brute Force Attack",
        "Phishing Email"
    ]
    
    severities = ["low", "medium", "high", "critical"]
    sources = ["SIEM", "EDR", "Firewall", "IDS", "Email Gateway"]
    statuses = ["new", "in_progress", "resolved", "false_positive"]
    
    alerts = []
    base_time = datetime.now()
    
    for i in range(count):
        alert = {
            "id": f"ALERT-{i+1:05d}",
            "timestamp": (base_time - timedelta(hours=random.randint(0, 72))).isoformat(),
            "type": random.choice(alert_types),
            "severity": random.choice(severities),
            "source": random.choice(sources),
            "status": random.choice(statuses),
            "source_ip": f"{random.randint(1,255)}.{random.randint(1,255)}.{random.randint(1,255)}.{random.randint(1,255)}",
            "destination_ip": f"10.0.{random.randint(1,255)}.{random.randint(1,255)}",
            "user": f"user{random.randint(1,100)}",
            "description": f"Sample alert for testing - {random.choice(alert_types)}",
            "metadata": {
                "confidence": random.uniform(0.5, 1.0),
                "false_positive_likelihood": random.uniform(0, 0.5)
            }
        }
        alerts.append(alert)
    
    return alerts

def main():
    # Generate sample alerts
    alerts = generate_sample_alerts(100)
    
    # Save to file
    output_dir = os.path.join(os.path.dirname(os.path.abspath(__file__)), '..', 'data', 'alerts')
    os.makedirs(output_dir, exist_ok=True)
    
    output_file = os.path.join(output_dir, 'sample_alerts.json')
    with open(output_file, 'w') as f:
        json.dump(alerts, f, indent=2)
    
    print(f"Generated {len(alerts)} sample alerts")
    print(f"Saved to: {output_file}")
    
    # Create summary
    severity_counts = {}
    for alert in alerts:
        severity = alert['severity']
        severity_counts[severity] = severity_counts.get(severity, 0) + 1
    
    print("\nSummary by severity:")
    for severity, count in sorted(severity_counts.items()):
        print(f"  {severity}: {count}")

if __name__ == "__main__":
    main()
EOF
    
    cd "$SCRIPT_DIR"
    python /tmp/generate_sample_data.py
    rm /tmp/generate_sample_data.py
    
    log_success "Sample data created"
}

setup_database() {
    log_info "Setting up database with Docker..."
    
    # Create docker-compose file for database
    cat > "$DEPLOY_DIR/docker-compose.db.yml" << 'EOF'
version: '3.8'

services:
  postgres:
    image: postgres:15-alpine
    container_name: agentic-soc-db
    environment:
      POSTGRES_DB: agentic_soc
      POSTGRES_USER: soc_admin
      POSTGRES_PASSWORD: changeme
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
    restart: unless-stopped
    
  redis:
    image: redis:7-alpine
    container_name: agentic-soc-redis
    ports:
      - "6379:6379"
    volumes:
      - redis_data:/data
    restart: unless-stopped

volumes:
  postgres_data:
  redis_data:
EOF
    
    log_info "Starting database containers..."
    cd "$DEPLOY_DIR"
    docker-compose -f docker-compose.db.yml up -d
    
    # Wait for database to be ready
    log_info "Waiting for database to be ready..."
    sleep 10
    
    # Create initial database schema
    create_database_schema
    
    log_success "Database setup completed"
}

create_database_schema() {
    log_info "Creating database schema..."
    
    # Create SQL schema file
    cat > "$DEPLOY_DIR/data/schema.sql" << 'EOF'
-- AI Agentic SOC Database Schema

-- Alerts table
CREATE TABLE IF NOT EXISTS alerts (
    id SERIAL PRIMARY KEY,
    alert_id VARCHAR(255) UNIQUE NOT NULL,
    timestamp TIMESTAMP NOT NULL,
    type VARCHAR(100) NOT NULL,
    severity VARCHAR(20) NOT NULL,
    source VARCHAR(100) NOT NULL,
    status VARCHAR(50) DEFAULT 'new',
    source_ip INET,
    destination_ip INET,
    user_account VARCHAR(255),
    description TEXT,
    raw_data JSONB,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Agent actions table (audit trail)
CREATE TABLE IF NOT EXISTS agent_actions (
    id SERIAL PRIMARY KEY,
    agent_name VARCHAR(100) NOT NULL,
    action_type VARCHAR(100) NOT NULL,
    alert_id VARCHAR(255),
    input_data JSONB,
    output_data JSONB,
    status VARCHAR(50),
    execution_time_ms INTEGER,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Investigations table
CREATE TABLE IF NOT EXISTS investigations (
    id SERIAL PRIMARY KEY,
    investigation_id VARCHAR(255) UNIQUE NOT NULL,
    alert_id VARCHAR(255) NOT NULL,
    status VARCHAR(50) DEFAULT 'open',
    assigned_agent VARCHAR(100),
    findings TEXT,
    recommendation TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    closed_at TIMESTAMP
);

-- Create indexes
CREATE INDEX IF NOT EXISTS idx_alerts_timestamp ON alerts(timestamp);
CREATE INDEX IF NOT EXISTS idx_alerts_severity ON alerts(severity);
CREATE INDEX IF NOT EXISTS idx_alerts_status ON alerts(status);
CREATE INDEX IF NOT EXISTS idx_agent_actions_agent ON agent_actions(agent_name);
CREATE INDEX IF NOT EXISTS idx_agent_actions_alert ON agent_actions(alert_id);
CREATE INDEX IF NOT EXISTS idx_investigations_status ON investigations(status);
EOF
    
    # Apply schema
    docker exec -i agentic-soc-db psql -U soc_admin -d agentic_soc < "$DEPLOY_DIR/data/schema.sql"
    
    log_success "Database schema created"
}

create_initial_config() {
    log_info "Creating initial agent configuration..."
    
    cat > "$DEPLOY_DIR/config/agent_config.yaml" << 'EOF'
# AI Agent Configuration

# Triage Agent
triage_agent:
  enabled: true
  model: gpt-4o
  temperature: 0.2
  max_tokens: 2000
  system_prompt: |
    You are a security triage agent. Your role is to analyze security alerts
    and prioritize them based on severity, context, and potential impact.
    Provide clear recommendations for next steps.

# Investigation Agent
investigation_agent:
  enabled: true
  model: gpt-4o
  temperature: 0.3
  max_tokens: 4000
  system_prompt: |
    You are a security investigation agent. Your role is to gather context,
    enrich data, and provide detailed analysis of security incidents.

# Response Agent
response_agent:
  enabled: false  # Disabled by default for safety
  model: gpt-4o
  temperature: 0.1
  max_tokens: 2000
  system_prompt: |
    You are a security response agent. Your role is to recommend and execute
    response actions for security incidents. Always require human approval
    for critical actions.

# Shared settings
shared:
  max_iterations: 5
  timeout: 300
  retry_count: 3
  human_in_loop_threshold: high
EOF
    
    log_success "Initial configuration created"
}

main "$@"
