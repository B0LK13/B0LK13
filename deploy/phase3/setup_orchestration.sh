#!/bin/bash

################################################################################
# Phase 3: Setup Multi-Agent Orchestration
#
# Configures the orchestration layer for multi-agent collaboration.
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
source "$DEPLOY_DIR/common/utils.sh"

main() {
    log_info "Setting up multi-agent orchestration..."
    
    # Activate virtual environment
    source "$DEPLOY_DIR/.venv/bin/activate"
    
    # Install orchestration dependencies
    log_info "Installing orchestration frameworks..."
    pip install celery redis flower  # Task queue and monitoring
    pip install dramatiq  # Alternative task queue
    
    # Create orchestration configuration
    create_orchestration_config
    
    # Create orchestrator service
    create_orchestrator_service
    
    # Set up message queue
    setup_message_queue
    
    log_success "Multi-agent orchestration setup completed"
}

create_orchestration_config() {
    log_info "Creating orchestration configuration..."
    
    cat > "$DEPLOY_DIR/config/orchestration_config.yaml" << 'EOF'
# Multi-Agent Orchestration Configuration

orchestration:
  # Execution mode
  mode: sequential  # sequential, parallel, hybrid
  
  # Agent workflow
  workflow:
    - name: triage
      agent: triage_agent
      timeout: 60
      required: true
      
    - name: investigation
      agent: investigation_agent
      timeout: 300
      required: false
      condition: "priority >= high"
      
    - name: response
      agent: response_agent
      timeout: 120
      required: false
      condition: "priority == critical and auto_response_enabled"
  
  # Retry policy
  retry:
    max_attempts: 3
    backoff: exponential
    max_backoff_seconds: 300
  
  # Concurrency limits
  concurrency:
    max_concurrent_workflows: 10
    max_agents_per_workflow: 5
  
  # Queue configuration
  queue:
    broker: redis://localhost:6379/0
    backend: redis://localhost:6379/1
    result_expires: 3600

# Agent communication
communication:
  protocol: message_queue  # message_queue, http, grpc
  message_format: json
  compression: false
  encryption: false

# Monitoring
monitoring:
  enabled: true
  metrics_port: 9090
  health_check_interval: 30
EOF
    
    log_success "Orchestration config created"
}

create_orchestrator_service() {
    log_info "Creating orchestrator service..."
    
    cat > "$DEPLOY_DIR/agents/orchestrator.py" << 'EOF'
#!/usr/bin/env python3
"""
Multi-Agent Orchestrator

Coordinates multiple AI agents to handle security incidents.
"""

import os
import sys
import json
import logging
from typing import Dict, List, Any
from pathlib import Path
from datetime import datetime

from celery import Celery
import yaml

# Set up logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Initialize Celery
app = Celery('agentic_soc')
app.config_from_object('celeryconfig')


class Orchestrator:
    """Orchestrates multiple AI agents for incident handling"""
    
    def __init__(self, config_path: str = None):
        """Initialize orchestrator"""
        self.config = self._load_config(config_path)
        logger.info("Orchestrator initialized")
    
    def _load_config(self, config_path: str = None) -> Dict[str, Any]:
        """Load orchestration configuration"""
        if not config_path:
            config_path = Path(__file__).parent.parent / "config" / "orchestration_config.yaml"
        
        with open(config_path) as f:
            return yaml.safe_load(f)
    
    def orchestrate_incident_response(self, alert: Dict[str, Any]) -> Dict[str, Any]:
        """
        Orchestrate multi-agent response to an incident.
        
        Args:
            alert: Security alert data
            
        Returns:
            Combined results from all agents
        """
        logger.info(f"Orchestrating response for alert: {alert.get('id')}")
        
        workflow = self.config['orchestration']['workflow']
        results = {
            'alert_id': alert.get('id'),
            'timestamp': datetime.now().isoformat(),
            'workflow_results': []
        }
        
        # Execute workflow steps
        for step in workflow:
            if self._should_execute_step(step, results):
                logger.info(f"Executing step: {step['name']}")
                
                try:
                    step_result = self._execute_agent(
                        step['agent'],
                        alert,
                        timeout=step.get('timeout', 60)
                    )
                    
                    results['workflow_results'].append({
                        'step': step['name'],
                        'agent': step['agent'],
                        'status': 'success',
                        'result': step_result
                    })
                    
                except Exception as e:
                    logger.error(f"Step {step['name']} failed: {e}")
                    
                    if step.get('required', False):
                        results['status'] = 'failed'
                        results['error'] = str(e)
                        return results
        
        results['status'] = 'completed'
        return results
    
    def _should_execute_step(self, step: Dict[str, Any], results: Dict[str, Any]) -> bool:
        """Determine if a workflow step should be executed"""
        # If no condition, always execute
        if 'condition' not in step:
            return True
        
        # Simple condition evaluation (extend as needed)
        condition = step['condition']
        
        # For demo, always execute
        # In production, implement proper condition evaluation
        return True
    
    def _execute_agent(self, agent_name: str, alert: Dict[str, Any], timeout: int) -> Any:
        """Execute a specific agent"""
        logger.info(f"Executing agent: {agent_name}")
        
        # Import and execute the appropriate agent
        # This is a simplified version - extend based on your agents
        
        if agent_name == "triage_agent":
            from phase2.deploy_triage_agent import TriageAgent
            agent = TriageAgent()
            return agent.triage_alert(alert)
        
        # Add other agents here
        
        raise ValueError(f"Unknown agent: {agent_name}")


@app.task
def process_alert(alert_data: Dict[str, Any]):
    """Celery task to process an alert"""
    orchestrator = Orchestrator()
    return orchestrator.orchestrate_incident_response(alert_data)


if __name__ == "__main__":
    # Example usage
    sample_alert = {
        "id": "ALERT-001",
        "type": "Suspicious Login",
        "severity": "high",
        "source_ip": "185.220.101.45"
    }
    
    orchestrator = Orchestrator()
    result = orchestrator.orchestrate_incident_response(sample_alert)
    
    print(json.dumps(result, indent=2))
EOF
    
    chmod +x "$DEPLOY_DIR/agents/orchestrator.py"
    
    # Create Celery configuration
    cat > "$DEPLOY_DIR/agents/celeryconfig.py" << 'EOF'
"""Celery configuration"""

broker_url = 'redis://localhost:6379/0'
result_backend = 'redis://localhost:6379/1'

task_serializer = 'json'
result_serializer = 'json'
accept_content = ['json']
timezone = 'UTC'
enable_utc = True

task_routes = {
    'agents.orchestrator.process_alert': {'queue': 'alerts'},
}
EOF
    
    log_success "Orchestrator service created"
}

setup_message_queue() {
    log_info "Setting up Redis message queue..."
    
    # Check if Redis is running
    if ! docker ps | grep -q agentic-soc-redis; then
        log_warning "Redis container not running. Starting it..."
        cd "$DEPLOY_DIR"
        docker-compose -f docker-compose.db.yml up -d redis
        sleep 5
    fi
    
    log_success "Message queue ready"
    log_info "Start Celery worker with: celery -A agents.orchestrator worker --loglevel=info"
}

main "$@"
