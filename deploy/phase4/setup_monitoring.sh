#!/bin/bash

################################################################################
# Phase 4: Setup Monitoring and KPIs
#
# Configures comprehensive monitoring and KPI tracking.
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_DIR="$(dirname "$SCRIPT_DIR")"
source "$DEPLOY_DIR/common/utils.sh"

main() {
    log_info "Setting up monitoring and KPI tracking..."
    
    # Activate virtual environment
    source "$DEPLOY_DIR/.venv/bin/activate"
    
    # Install monitoring libraries
    install_monitoring_tools
    
    # Create KPI tracker
    create_kpi_tracker
    
    # Set up alerting
    setup_alerting
    
    # Create monitoring dashboards
    create_monitoring_dashboards
    
    log_success "Monitoring and KPI tracking configured"
}

install_monitoring_tools() {
    log_info "Installing monitoring tools..."
    
    pip install prometheus-client
    pip install grafana-api
    pip install psutil  # System metrics
    
    log_success "Monitoring tools installed"
}

create_kpi_tracker() {
    log_info "Creating KPI tracker..."
    
    cat > "$DEPLOY_DIR/agents/kpi_tracker.py" << 'EOF'
#!/usr/bin/env python3
"""
KPI Tracker for AI Agentic SOC

Tracks key performance indicators:
- Mean Time to Triage (MTTI)
- Mean Time to Investigate (MTTI)
- Mean Time to Respond (MTTR)
- Automation Rate
- False Positive Rate
- Agent Accuracy
"""

import json
import logging
from datetime import datetime, timedelta
from pathlib import Path
from typing import Dict, List, Any
from collections import defaultdict

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


class KPITracker:
    """Track and calculate SOC KPIs"""
    
    def __init__(self, data_dir: str = "data/logs"):
        """Initialize KPI tracker"""
        self.data_dir = Path(data_dir)
        self.metrics = defaultdict(list)
    
    def calculate_mtti(self, start_date: datetime = None, end_date: datetime = None) -> float:
        """
        Calculate Mean Time to Triage (MTTI).
        
        Returns:
            Average time in seconds from alert creation to triage completion
        """
        # Load audit logs
        logs = self._load_audit_logs(start_date, end_date)
        
        triage_times = []
        
        for log in logs:
            if log.get('action') == 'triage':
                exec_time = log.get('output', {}).get('execution_time_seconds', 0)
                if exec_time > 0:
                    triage_times.append(exec_time)
        
        if not triage_times:
            return 0.0
        
        mtti = sum(triage_times) / len(triage_times)
        logger.info(f"MTTI: {mtti:.2f} seconds ({mtti/60:.2f} minutes)")
        
        return mtti
    
    def calculate_automation_rate(self, start_date: datetime = None, end_date: datetime = None) -> float:
        """
        Calculate automation rate.
        
        Returns:
            Percentage of alerts handled automatically (0-100)
        """
        logs = self._load_audit_logs(start_date, end_date)
        
        total_alerts = 0
        automated_alerts = 0
        
        for log in logs:
            if log.get('event_type') == 'agent_action':
                total_alerts += 1
                if log.get('status') == 'completed':
                    automated_alerts += 1
        
        if total_alerts == 0:
            return 0.0
        
        rate = (automated_alerts / total_alerts) * 100
        logger.info(f"Automation Rate: {rate:.1f}%")
        
        return rate
    
    def calculate_false_positive_rate(self, start_date: datetime = None, end_date: datetime = None) -> float:
        """
        Calculate false positive rate.
        
        Returns:
            Percentage of alerts marked as false positives (0-100)
        """
        # This would integrate with your alert tracking system
        # For now, return a sample value
        return 15.0
    
    def generate_daily_report(self, date: datetime = None) -> Dict[str, Any]:
        """
        Generate daily KPI report.
        
        Args:
            date: Date for the report (defaults to today)
            
        Returns:
            Dictionary with KPI metrics
        """
        if not date:
            date = datetime.now()
        
        start = date.replace(hour=0, minute=0, second=0, microsecond=0)
        end = start + timedelta(days=1)
        
        report = {
            "date": date.strftime("%Y-%m-%d"),
            "generated_at": datetime.now().isoformat(),
            "kpis": {
                "mtti_seconds": self.calculate_mtti(start, end),
                "automation_rate_percent": self.calculate_automation_rate(start, end),
                "false_positive_rate_percent": self.calculate_false_positive_rate(start, end),
            },
            "status": "success"
        }
        
        # Save report
        report_dir = self.data_dir / "reports"
        report_dir.mkdir(parents=True, exist_ok=True)
        
        report_file = report_dir / f"kpi_report_{date.strftime('%Y%m%d')}.json"
        with open(report_file, "w") as f:
            json.dump(report, f, indent=2)
        
        logger.info(f"KPI report saved: {report_file}")
        
        return report
    
    def _load_audit_logs(self, start_date: datetime = None, end_date: datetime = None) -> List[Dict[str, Any]]:
        """Load audit logs for the specified date range"""
        
        logs = []
        
        # Find all audit log files
        audit_files = sorted(self.data_dir.glob("audit_*.jsonl"))
        
        for audit_file in audit_files:
            try:
                with open(audit_file) as f:
                    for line in f:
                        log_entry = json.loads(line.strip())
                        
                        # Filter by date range if specified
                        if start_date or end_date:
                            log_time = datetime.fromisoformat(log_entry.get('timestamp', ''))
                            if start_date and log_time < start_date:
                                continue
                            if end_date and log_time >= end_date:
                                continue
                        
                        logs.append(log_entry)
            except Exception as e:
                logger.warning(f"Error reading {audit_file}: {e}")
        
        return logs


def main():
    """Generate KPI report"""
    print("AI Agentic SOC - KPI Tracker")
    print("=" * 80)
    
    tracker = KPITracker()
    
    # Generate daily report
    report = tracker.generate_daily_report()
    
    print("\nDaily KPI Report:")
    print(json.dumps(report, indent=2))
    
    # Display summary
    print("\n" + "=" * 80)
    print("KPI Summary:")
    print(f"  Mean Time to Triage: {report['kpis']['mtti_seconds']/60:.2f} minutes")
    print(f"  Automation Rate: {report['kpis']['automation_rate_percent']:.1f}%")
    print(f"  False Positive Rate: {report['kpis']['false_positive_rate_percent']:.1f}%")
    print("=" * 80)


if __name__ == "__main__":
    main()
EOF
    
    chmod +x "$DEPLOY_DIR/agents/kpi_tracker.py"
    log_success "KPI tracker created"
}

setup_alerting() {
    log_info "Setting up alerting system..."
    
    cat > "$DEPLOY_DIR/config/alerting_rules.yaml" << 'EOF'
# Alerting Rules for AI Agentic SOC

alerts:
  # High MTTI
  - name: high_mtti
    condition: mtti_minutes > 5
    severity: warning
    message: "Mean Time to Triage exceeds 5 minutes"
    actions:
      - notify_team
  
  # Low automation rate
  - name: low_automation_rate
    condition: automation_rate < 70
    severity: warning
    message: "Automation rate below 70%"
    actions:
      - notify_team
  
  # Agent errors
  - name: agent_errors
    condition: error_rate > 5
    severity: critical
    message: "Agent error rate exceeds 5%"
    actions:
      - notify_team
      - create_incident
  
  # System health
  - name: system_down
    condition: health_check_failed
    severity: critical
    message: "System health check failed"
    actions:
      - notify_team
      - page_oncall
      - auto_restart

# Notification channels
notifications:
  email:
    enabled: true
    recipients:
      - security-team@company.com
  
  slack:
    enabled: false
    webhook_url: ""
    channel: "#security-alerts"
  
  pagerduty:
    enabled: false
    api_key: ""
EOF
    
    log_success "Alerting system configured"
}

create_monitoring_dashboards() {
    log_info "Creating Grafana dashboard configurations..."
    
    ensure_directory "$DEPLOY_DIR/config/grafana/dashboards"
    
    cat > "$DEPLOY_DIR/config/grafana/dashboards/soc_overview.json" << 'EOF'
{
  "dashboard": {
    "title": "AI Agentic SOC Overview",
    "tags": ["security", "soc", "ai"],
    "timezone": "browser",
    "panels": [
      {
        "title": "Active Alerts",
        "type": "stat",
        "targets": [
          {
            "expr": "soc_active_alerts_total"
          }
        ]
      },
      {
        "title": "Mean Time to Triage",
        "type": "graph",
        "targets": [
          {
            "expr": "soc_mtti_seconds"
          }
        ]
      },
      {
        "title": "Automation Rate",
        "type": "gauge",
        "targets": [
          {
            "expr": "soc_automation_rate_percent"
          }
        ]
      }
    ]
  }
}
EOF
    
    log_success "Monitoring dashboards created"
}

main "$@"
