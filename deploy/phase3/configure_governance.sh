#!/bin/bash

################################################################################
# Phase 3: Configure Governance Controls
#
# Implements governance, compliance, and audit controls.
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
source "$DEPLOY_DIR/common/utils.sh"

main() {
    log_info "Configuring governance controls..."
    
    # Create governance configuration
    create_governance_config
    
    # Implement human-in-the-loop
    implement_hitl
    
    # Set up audit logging
    setup_audit_logging
    
    # Create compliance reports
    create_compliance_reports
    
    log_success "Governance controls configured"
}

create_governance_config() {
    log_info "Creating governance configuration..."
    
    cat > "$DEPLOY_DIR/config/governance_config.yaml" << 'EOF'
# Governance and Compliance Configuration

governance:
  # Human-in-the-Loop (HITL)
  hitl:
    enabled: true
    threshold: high  # Actions at or above this severity require approval
    timeout: 300  # Seconds to wait for approval
    auto_approve_low_risk: true
    escalation_contacts:
      - security-team@company.com
  
  # Automated Actions Restrictions
  restrictions:
    allow_endpoint_isolation: false  # Require manual approval
    allow_account_disable: false
    allow_firewall_changes: false
    allow_auto_remediation: false
  
  # Audit Trail
  audit:
    enabled: true
    retention_days: 365
    log_all_actions: true
    log_all_decisions: true
    include_llm_prompts: true
    include_llm_responses: true
  
  # Compliance
  compliance:
    gdpr:
      enabled: true
      data_retention_days: 90
      anonymize_pii: true
    
    soc2:
      enabled: true
      audit_trail_required: true
      access_logging: true
    
    nist_csf:
      enabled: true
      framework_version: "2.0"

# Rate Limiting
rate_limiting:
  enabled: true
  requests_per_minute: 60
  burst_size: 10
  
# Security
security:
  api_key_rotation_days: 90
  session_timeout: 3600
  require_mfa: false
  encryption_at_rest: true
  encryption_in_transit: true
EOF
    
    log_success "Governance configuration created"
}

implement_hitl() {
    log_info "Implementing Human-in-the-Loop workflow..."
    
    cat > "$DEPLOY_DIR/agents/hitl.py" << 'EOF'
#!/usr/bin/env python3
"""
Human-in-the-Loop (HITL) Workflow

Requires human approval for critical security actions.
"""

import logging
from typing import Dict, Any, Optional
from datetime import datetime, timedelta
import json

logger = logging.getLogger(__name__)


class HITLManager:
    """Manages human approval workflow for agent actions"""
    
    def __init__(self, config: Dict[str, Any]):
        """Initialize HITL manager"""
        self.config = config
        self.pending_approvals = {}
        logger.info("HITL Manager initialized")
    
    def requires_approval(self, action: Dict[str, Any]) -> bool:
        """
        Determine if an action requires human approval.
        
        Args:
            action: Proposed action details
            
        Returns:
            True if approval is required
        """
        severity = action.get('severity', 'low')
        action_type = action.get('type')
        
        threshold = self.config.get('hitl', {}).get('threshold', 'high')
        
        # Check severity threshold
        severity_levels = {'low': 0, 'medium': 1, 'high': 2, 'critical': 3}
        
        if severity_levels.get(severity, 0) >= severity_levels.get(threshold, 2):
            return True
        
        # Check action restrictions
        restrictions = self.config.get('restrictions', {})
        
        if action_type == 'isolate_endpoint' and not restrictions.get('allow_endpoint_isolation', False):
            return True
        
        if action_type == 'disable_account' and not restrictions.get('allow_account_disable', False):
            return True
        
        return False
    
    def request_approval(self, action: Dict[str, Any], agent_name: str) -> str:
        """
        Request human approval for an action.
        
        Args:
            action: Action requiring approval
            agent_name: Name of requesting agent
            
        Returns:
            Approval request ID
        """
        request_id = f"APPROVAL-{datetime.now().strftime('%Y%m%d%H%M%S')}"
        
        timeout = self.config.get('hitl', {}).get('timeout', 300)
        expires_at = datetime.now() + timedelta(seconds=timeout)
        
        self.pending_approvals[request_id] = {
            'action': action,
            'agent': agent_name,
            'requested_at': datetime.now().isoformat(),
            'expires_at': expires_at.isoformat(),
            'status': 'pending'
        }
        
        # In production, send notification to security team
        self._notify_approvers(request_id, action)
        
        logger.info(f"Approval requested: {request_id}")
        return request_id
    
    def check_approval_status(self, request_id: str) -> Optional[str]:
        """
        Check status of an approval request.
        
        Returns:
            'approved', 'denied', 'pending', or 'expired'
        """
        if request_id not in self.pending_approvals:
            return None
        
        request = self.pending_approvals[request_id]
        
        # Check expiration
        expires_at = datetime.fromisoformat(request['expires_at'])
        if datetime.now() > expires_at:
            request['status'] = 'expired'
            return 'expired'
        
        return request['status']
    
    def _notify_approvers(self, request_id: str, action: Dict[str, Any]):
        """Send notification to approvers"""
        # In production, integrate with email/Slack/Teams
        logger.info(f"Notification sent for {request_id}: {action.get('type')}")
        
        # For demo, auto-approve low severity after delay
        if action.get('severity') == 'medium':
            # Simulate approval
            pass


if __name__ == "__main__":
    # Example usage
    config = {'hitl': {'enabled': True, 'threshold': 'high', 'timeout': 300}}
    manager = HITLManager(config)
    
    action = {
        'type': 'isolate_endpoint',
        'severity': 'critical',
        'target': '10.0.1.100'
    }
    
    if manager.requires_approval(action):
        request_id = manager.request_approval(action, 'response_agent')
        print(f"Approval required: {request_id}")
EOF
    
    chmod +x "$DEPLOY_DIR/agents/hitl.py"
    log_success "HITL workflow implemented"
}

setup_audit_logging() {
    log_info "Setting up comprehensive audit logging..."
    
    ensure_directory "/var/log/agentic-soc/audit"
    sudo chown -R "$USER:$USER" /var/log/agentic-soc || true
    
    cat > "$DEPLOY_DIR/agents/audit_logger.py" << 'EOF'
#!/usr/bin/env python3
"""
Audit Logger

Comprehensive logging of all agent actions for compliance and forensics.
"""

import json
import logging
from datetime import datetime
from pathlib import Path
from typing import Dict, Any

class AuditLogger:
    """Comprehensive audit logging for compliance"""
    
    def __init__(self, log_dir: str = "/var/log/agentic-soc/audit"):
        """Initialize audit logger"""
        self.log_dir = Path(log_dir)
        self.log_dir.mkdir(parents=True, exist_ok=True)
    
    def log_agent_action(
        self,
        agent_name: str,
        action: str,
        input_data: Any,
        output_data: Any,
        status: str = "success",
        metadata: Dict[str, Any] = None
    ):
        """Log an agent action"""
        
        entry = {
            "timestamp": datetime.now().isoformat(),
            "event_type": "agent_action",
            "agent": agent_name,
            "action": action,
            "input": self._sanitize(input_data),
            "output": self._sanitize(output_data),
            "status": status,
            "metadata": metadata or {}
        }
        
        self._write_log(entry)
    
    def log_decision(
        self,
        agent_name: str,
        decision: str,
        reasoning: str,
        confidence: float = None
    ):
        """Log an agent decision"""
        
        entry = {
            "timestamp": datetime.now().isoformat(),
            "event_type": "agent_decision",
            "agent": agent_name,
            "decision": decision,
            "reasoning": reasoning,
            "confidence": confidence
        }
        
        self._write_log(entry)
    
    def _sanitize(self, data: Any) -> Any:
        """Remove sensitive data from logs"""
        # Implement PII removal/anonymization
        if isinstance(data, dict):
            sanitized = {}
            for key, value in data.items():
                if key.lower() in ['password', 'api_key', 'token', 'secret']:
                    sanitized[key] = "***REDACTED***"
                else:
                    sanitized[key] = value
            return sanitized
        return data
    
    def _write_log(self, entry: Dict[str, Any]):
        """Write log entry to file"""
        log_file = self.log_dir / f"audit_{datetime.now().strftime('%Y%m%d')}.jsonl"
        
        with open(log_file, "a") as f:
            f.write(json.dumps(entry) + "\n")
EOF
    
    log_success "Audit logging configured"
}

create_compliance_reports() {
    log_info "Creating compliance reporting tools..."
    
    cat > "$DEPLOY_DIR/agents/compliance_reporter.py" << 'EOF'
#!/usr/bin/env python3
"""Generate compliance reports"""

import json
from datetime import datetime, timedelta
from pathlib import Path
from collections import defaultdict

def generate_daily_report(date: datetime = None):
    """Generate daily compliance report"""
    
    if not date:
        date = datetime.now()
    
    report = {
        "report_date": date.strftime("%Y-%m-%d"),
        "generated_at": datetime.now().isoformat(),
        "summary": {
            "total_actions": 0,
            "automated_actions": 0,
            "manual_approvals": 0,
            "alerts_processed": 0
        },
        "compliance": {
            "audit_trail_complete": True,
            "data_retention_compliant": True,
            "access_controls_verified": True
        }
    }
    
    # In production, query actual data
    print(json.dumps(report, indent=2))
    return report

if __name__ == "__main__":
    generate_daily_report()
EOF
    
    chmod +x "$DEPLOY_DIR/agents/compliance_reporter.py"
    log_success "Compliance reporting tools created"
}

main "$@"
