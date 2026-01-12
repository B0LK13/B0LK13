#!/bin/bash

################################################################################
# Phase 2: Setup Agent Development Environment
#
# Prepares the development environment for building AI agents.
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
source "$DEPLOY_DIR/common/utils.sh"

main() {
    log_info "Setting up agent development environment..."
    
    # Activate virtual environment
    source "$DEPLOY_DIR/.venv/bin/activate"
    
    # Install development tools
    log_info "Installing development tools..."
    pip install ipython jupyter notebook
    pip install black flake8 pylint  # Code formatting and linting
    pip install pytest pytest-asyncio  # Testing frameworks
    
    # Create agent directories
    ensure_directory "$DEPLOY_DIR/agents/triage"
    ensure_directory "$DEPLOY_DIR/agents/investigation"
    ensure_directory "$DEPLOY_DIR/agents/response"
    ensure_directory "$DEPLOY_DIR/agents/common"
    
    # Create common utilities
    create_agent_utils
    
    # Create agent base class
    create_agent_base_class
    
    log_success "Agent development environment ready"
}

create_agent_utils() {
    log_info "Creating common agent utilities..."
    
    cat > "$DEPLOY_DIR/agents/common/__init__.py" << 'EOF'
"""Common utilities for AI agents"""

from .base_agent import BaseAgent
from .logger import setup_logger
from .config import load_config

__all__ = ['BaseAgent', 'setup_logger', 'load_config']
EOF

    cat > "$DEPLOY_DIR/agents/common/logger.py" << 'EOF'
"""Logging utilities for agents"""

import logging
import sys
from pathlib import Path

def setup_logger(name: str, log_file: str = None, level=logging.INFO):
    """Set up logger for an agent"""
    
    logger = logging.getLogger(name)
    logger.setLevel(level)
    
    # Console handler
    console_handler = logging.StreamHandler(sys.stdout)
    console_handler.setLevel(level)
    
    # File handler
    if log_file:
        file_handler = logging.FileHandler(log_file)
        file_handler.setLevel(level)
        logger.addHandler(file_handler)
    
    # Formatter
    formatter = logging.Formatter(
        '%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    console_handler.setFormatter(formatter)
    
    logger.addHandler(console_handler)
    
    return logger
EOF

    cat > "$DEPLOY_DIR/agents/common/config.py" << 'EOF'
"""Configuration utilities for agents"""

import os
import yaml
from pathlib import Path
from typing import Dict, Any

def load_config(config_name: str = "agent_config.yaml") -> Dict[str, Any]:
    """Load agent configuration from YAML file"""
    
    # Try to find config file
    config_paths = [
        Path.cwd() / config_name,
        Path(__file__).parent.parent.parent / "config" / config_name,
        Path("/etc/agentic-soc") / config_name
    ]
    
    for config_path in config_paths:
        if config_path.exists():
            with open(config_path) as f:
                return yaml.safe_load(f)
    
    raise FileNotFoundError(f"Config file {config_name} not found in any of: {config_paths}")
EOF
    
    log_success "Agent utilities created"
}

create_agent_base_class() {
    log_info "Creating base agent class..."
    
    cat > "$DEPLOY_DIR/agents/common/base_agent.py" << 'EOF'
"""Base class for all AI agents"""

from abc import ABC, abstractmethod
from typing import Dict, Any, Optional
from datetime import datetime
import json
from pathlib import Path

class BaseAgent(ABC):
    """
    Base class for all AI security agents.
    
    Provides common functionality:
    - Logging
    - Audit trails
    - Error handling
    - Configuration management
    """
    
    def __init__(self, name: str, config: Optional[Dict[str, Any]] = None):
        """
        Initialize base agent.
        
        Args:
            name: Agent name
            config: Optional configuration dictionary
        """
        self.name = name
        self.config = config or {}
        self.audit_log_path = Path("data/logs")
        self.audit_log_path.mkdir(parents=True, exist_ok=True)
    
    @abstractmethod
    def process(self, input_data: Dict[str, Any]) -> Dict[str, Any]:
        """
        Process input and return output.
        
        This method must be implemented by each agent.
        
        Args:
            input_data: Input data to process
            
        Returns:
            Processing results
        """
        pass
    
    def log_action(self, action: str, input_data: Any, output_data: Any, status: str = "success"):
        """
        Log agent action to audit trail.
        
        Args:
            action: Action performed
            input_data: Input to the action
            output_data: Output from the action
            status: Action status
        """
        audit_entry = {
            "timestamp": datetime.now().isoformat(),
            "agent": self.name,
            "action": action,
            "input": input_data,
            "output": output_data,
            "status": status
        }
        
        audit_file = self.audit_log_path / f"audit_{datetime.now().strftime('%Y%m%d')}.jsonl"
        with open(audit_file, "a") as f:
            f.write(json.dumps(audit_entry) + "\n")
    
    def get_config(self, key: str, default: Any = None) -> Any:
        """Get configuration value."""
        return self.config.get(key, default)
EOF
    
    log_success "Base agent class created"
}

main "$@"
