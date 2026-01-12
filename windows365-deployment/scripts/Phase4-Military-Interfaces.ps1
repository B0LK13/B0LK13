# Phase 4: Military-Style Interfaces and SOC Integration
# Run inside Cloud PC after Phase 3 completion
# Sets up security operations center tools, dashboards, and AI agents

<#
.SYNOPSIS
    Sets up military-style interfaces and SOC (Security Operations Center) integration.

.DESCRIPTION
    This script performs the following:
    - Installs Grafana for threat dashboards
    - Sets up Python environment for AI agentic SOC
    - Creates sample threat triage and response agents
    - Configures security monitoring tools
    - Sets up automation scripts for alert handling

.EXAMPLE
    .\Phase4-Military-Interfaces.ps1

.NOTES
    Run with administrator privileges inside the Cloud PC.
    Requires Python to be installed (from Phase 2).
#>

[CmdletBinding()]
param()

# Require administrator privileges
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "This script must be run as Administrator. Please restart PowerShell as Administrator."
    exit 1
}

$ErrorActionPreference = "Continue"

try {
    Write-Host "=== Phase 4: Military-Style Interfaces and SOC Integration ===" -ForegroundColor Cyan
    Write-Host "Setting up security operations center..." -ForegroundColor Gray
    Write-Host ""

    # Create SOC workspace directory
    $socDir = "$env:USERPROFILE\Documents\SOC-Workspace"
    if (-not (Test-Path $socDir)) {
        New-Item -Path $socDir -ItemType Directory | Out-Null
    }

    # Install Grafana
    Write-Host "[1/5] Installing Grafana..." -ForegroundColor Yellow
    try {
        # Download Grafana OSS
        $grafanaVersion = "10.2.3"
        $grafanaUrl = "https://dl.grafana.com/oss/release/grafana-$grafanaVersion.windows-amd64.zip"
        $grafanaZip = "$env:TEMP\grafana.zip"
        $grafanaPath = "$env:ProgramFiles\Grafana"
        
        Write-Host "Downloading Grafana $grafanaVersion..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $grafanaUrl -OutFile $grafanaZip -UseBasicParsing
        
        if (Test-Path $grafanaPath) {
            Remove-Item -Path $grafanaPath -Recurse -Force
        }
        
        Expand-Archive -Path $grafanaZip -DestinationPath "$env:ProgramFiles" -Force
        Rename-Item -Path "$env:ProgramFiles\grafana-$grafanaVersion" -NewName "Grafana"
        
        # Create Windows service for Grafana
        $grafanaBin = "$grafanaPath\bin\grafana-server.exe"
        
        # Create startup script
        $startupScript = @"
@echo off
cd /d "$grafanaPath\bin"
start "" grafana-server.exe
"@
        $startupBat = "$grafanaPath\start-grafana.bat"
        Set-Content -Path $startupBat -Value $startupScript
        
        Write-Host "✓ Grafana installed" -ForegroundColor Green
        Write-Host "  Access Grafana at: http://localhost:3000 (admin/admin)" -ForegroundColor Gray
        Write-Host "  Start Grafana: $startupBat" -ForegroundColor Gray
    } catch {
        Write-Warning "Failed to install Grafana: $($_.Exception.Message)"
        Write-Host "You can manually download from: https://grafana.com/grafana/download" -ForegroundColor Yellow
    }

    # Install additional security tools
    Write-Host "[2/5] Installing security and monitoring tools..." -ForegroundColor Yellow
    
    $securityTools = @(
        @{Name="Wireshark"; Id="WiresharkFoundation.Wireshark"},
        @{Name="Nmap"; Id="Insecure.Nmap"},
        @{Name="Sysinternals Suite"; Id="Microsoft.Sysinternals.ProcessExplorer"}
    )

    foreach ($tool in $securityTools) {
        try {
            Write-Host "  Installing $($tool.Name)..." -ForegroundColor Gray
            winget install --id $tool.Id -e --accept-package-agreements --accept-source-agreements --silent
            Write-Host "  ✓ $($tool.Name) installed" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to install $($tool.Name): $($_.Exception.Message)"
        }
    }

    # Set up Python environment for AI agents
    Write-Host "[3/5] Setting up AI agentic SOC environment..." -ForegroundColor Yellow
    
    # Verify Python installation
    try {
        $pythonVersion = python --version 2>&1
        Write-Host "  Python found: $pythonVersion" -ForegroundColor Gray
        
        # Install required Python packages
        Write-Host "  Installing Python packages for AI agents..." -ForegroundColor Gray
        python -m pip install --upgrade pip --quiet
        python -m pip install langchain openai anthropic requests pandas --user --quiet
        
        Write-Host "✓ Python environment configured" -ForegroundColor Green
    } catch {
        Write-Warning "Python not found. Please ensure Python was installed in Phase 2."
    }

    # Create AI Triage Agent script
    Write-Host "[4/5] Creating AI agent scripts..." -ForegroundColor Yellow
    
    $triageAgentScript = @"
#!/usr/bin/env python3
"""
AI-Powered Threat Triage Agent
Analyzes security alerts and provides initial triage recommendations.
"""

import json
import datetime
from typing import Dict, List, Optional

class ThreatTriageAgent:
    """
    AI-powered threat triage agent for initial security alert analysis.
    """
    
    def __init__(self, api_key: Optional[str] = None):
        self.api_key = api_key
        self.severity_levels = {
            'CRITICAL': 5,
            'HIGH': 4,
            'MEDIUM': 3,
            'LOW': 2,
            'INFO': 1
        }
    
    def analyze_alert(self, alert: Dict) -> Dict:
        """
        Analyze a security alert and provide triage recommendation.
        
        Args:
            alert: Dictionary containing alert information
            
        Returns:
            Triage analysis with severity, priority, and recommended actions
        """
        timestamp = datetime.datetime.now().isoformat()
        
        # Basic analysis (in production, integrate with LLM)
        severity = alert.get('severity', 'MEDIUM')
        alert_type = alert.get('type', 'Unknown')
        source_ip = alert.get('source_ip', 'Unknown')
        
        analysis = {
            'timestamp': timestamp,
            'alert_id': alert.get('id', 'N/A'),
            'severity': severity,
            'priority': self.severity_levels.get(severity, 3),
            'alert_type': alert_type,
            'source_ip': source_ip,
            'recommended_actions': self._get_recommended_actions(severity, alert_type),
            'requires_human_review': severity in ['CRITICAL', 'HIGH'],
            'auto_response_available': self._check_auto_response(alert_type)
        }
        
        return analysis
    
    def _get_recommended_actions(self, severity: str, alert_type: str) -> List[str]:
        """Generate recommended actions based on alert type and severity."""
        actions = []
        
        if severity == 'CRITICAL':
            actions.append("Immediate escalation to SOC lead")
            actions.append("Isolate affected systems from network")
            actions.append("Preserve forensic evidence")
        elif severity == 'HIGH':
            actions.append("Investigate within 1 hour")
            actions.append("Review related logs and network traffic")
            actions.append("Prepare containment strategy")
        elif severity == 'MEDIUM':
            actions.append("Investigate within 4 hours")
            actions.append("Monitor for related alerts")
        else:
            actions.append("Log for trend analysis")
            actions.append("Review during next shift")
        
        # Type-specific actions
        if 'malware' in alert_type.lower():
            actions.append("Run antivirus scan on affected host")
            actions.append("Check for lateral movement")
        elif 'phishing' in alert_type.lower():
            actions.append("Block sender domain/email")
            actions.append("Alert affected users")
        
        return actions
    
    def _check_auto_response(self, alert_type: str) -> bool:
        """Check if automatic response is available for this alert type."""
        auto_response_types = ['spam', 'known_malware', 'policy_violation']
        return any(art in alert_type.lower() for art in auto_response_types)
    
    def batch_triage(self, alerts: List[Dict]) -> List[Dict]:
        """Process multiple alerts in batch."""
        return [self.analyze_alert(alert) for alert in alerts]
    
    def generate_report(self, triaged_alerts: List[Dict]) -> str:
        """Generate a summary report of triaged alerts."""
        report = []
        report.append("="*60)
        report.append("THREAT TRIAGE REPORT")
        report.append(f"Generated: {datetime.datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
        report.append("="*60)
        report.append("")
        
        # Group by severity
        by_severity = {}
        for alert in triaged_alerts:
            sev = alert['severity']
            if sev not in by_severity:
                by_severity[sev] = []
            by_severity[sev].append(alert)
        
        for severity in ['CRITICAL', 'HIGH', 'MEDIUM', 'LOW', 'INFO']:
            if severity in by_severity:
                report.append(f"\n{severity} ALERTS: {len(by_severity[severity])}")
                report.append("-"*60)
                for alert in by_severity[severity]:
                    report.append(f"  Alert ID: {alert['alert_id']}")
                    report.append(f"  Type: {alert['alert_type']}")
                    report.append(f"  Source: {alert['source_ip']}")
                    report.append(f"  Actions:")
                    for action in alert['recommended_actions']:
                        report.append(f"    - {action}")
                    report.append("")
        
        report.append("="*60)
        report.append(f"Total alerts triaged: {len(triaged_alerts)}")
        report.append(f"Require human review: {sum(1 for a in triaged_alerts if a['requires_human_review'])}")
        report.append("="*60)
        
        return "\n".join(report)


# Example usage
if __name__ == "__main__":
    # Sample alerts for testing
    sample_alerts = [
        {
            'id': 'ALT-001',
            'severity': 'HIGH',
            'type': 'Malware Detection',
            'source_ip': '192.168.1.105',
            'description': 'Suspicious executable detected'
        },
        {
            'id': 'ALT-002',
            'severity': 'MEDIUM',
            'type': 'Failed Login Attempt',
            'source_ip': '10.0.0.50',
            'description': 'Multiple failed login attempts'
        },
        {
            'id': 'ALT-003',
            'severity': 'CRITICAL',
            'type': 'Data Exfiltration',
            'source_ip': '192.168.1.200',
            'description': 'Large data transfer to unknown external IP'
        }
    ]
    
    # Initialize agent
    agent = ThreatTriageAgent()
    
    # Triage alerts
    print("Processing alerts...\n")
    triaged = agent.batch_triage(sample_alerts)
    
    # Generate report
    report = agent.generate_report(triaged)
    print(report)
    
    # Save report to file
    report_file = 'triage_report.txt'
    with open(report_file, 'w') as f:
        f.write(report)
    
    print(f"\nReport saved to: {report_file}")
"@

    $triageAgentPath = "$socDir\ThreatTriageAgent.py"
    Set-Content -Path $triageAgentPath -Value $triageAgentScript
    Write-Host "✓ Threat Triage Agent created: $triageAgentPath" -ForegroundColor Green

    # Create alert monitoring script
    $alertMonitorScript = @"
# Windows Defender Alert Monitor
# Monitors Windows Defender threat detections and generates alerts

`$logFile = "$socDir\defender_alerts.log"

function Get-DefenderThreats {
    `$threats = Get-MpThreatDetection
    
    if (`$threats) {
        `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        
        foreach (`$threat in `$threats) {
            `$alert = @{
                Timestamp = `$timestamp
                ThreatName = `$threat.ThreatName
                Severity = `$threat.SeverityID
                Resources = `$threat.Resources -join "; "
                ProcessName = `$threat.ProcessName
            }
            
            # Log to file
            `$logEntry = "`$timestamp | `$(`$threat.ThreatName) | Severity: `$(`$threat.SeverityID) | `$(`$threat.Resources)"
            Add-Content -Path `$logFile -Value `$logEntry
            
            # Display alert
            Write-Host "[THREAT DETECTED] `$(`$threat.ThreatName)" -ForegroundColor Red
            Write-Host "  Severity: `$(`$threat.SeverityID)" -ForegroundColor Yellow
            Write-Host "  Resource: `$(`$threat.Resources)" -ForegroundColor Yellow
        }
        
        return `$threats
    } else {
        Write-Host "[`$(Get-Date -Format 'HH:mm:ss')] No threats detected" -ForegroundColor Green
        return `$null
    }
}

# Run monitoring
Write-Host "=== Windows Defender Threat Monitor ===" -ForegroundColor Cyan
Write-Host "Monitoring for threats... Press Ctrl+C to stop" -ForegroundColor Yellow
Write-Host ""

while (`$true) {
    Get-DefenderThreats
    Start-Sleep -Seconds 60
}
"@

    $alertMonitorPath = "$socDir\DefenderAlertMonitor.ps1"
    Set-Content -Path $alertMonitorPath -Value $alertMonitorScript
    Write-Host "✓ Defender Alert Monitor created: $alertMonitorPath" -ForegroundColor Green

    # Create dashboard configuration
    Write-Host "[5/5] Creating dashboard configurations..." -ForegroundColor Yellow
    
    $dashboardConfig = @"
{
  "dashboard": {
    "title": "Security Operations Dashboard",
    "panels": [
      {
        "title": "Threat Detection Timeline",
        "type": "graph",
        "datasource": "Windows Event Log",
        "targets": [
          {
            "query": "Event.Level == 'Warning' OR Event.Level == 'Error'"
          }
        ]
      },
      {
        "title": "Active Threats",
        "type": "stat",
        "datasource": "Defender API",
        "targets": [
          {
            "query": "SELECT COUNT(*) FROM threats WHERE status='active'"
          }
        ]
      },
      {
        "title": "Network Activity",
        "type": "heatmap",
        "datasource": "Network Monitor",
        "targets": [
          {
            "query": "netstat -an"
          }
        ]
      }
    ]
  }
}
"@

    $dashboardPath = "$socDir\dashboard_config.json"
    Set-Content -Path $dashboardPath -Value $dashboardConfig
    Write-Host "✓ Dashboard configuration created: $dashboardPath" -ForegroundColor Green

    # Create README for SOC workspace
    $socReadme = @"
# Security Operations Center (SOC) Workspace

## Overview
This workspace contains AI-powered security monitoring and incident response tools.

## Components

### 1. Threat Triage Agent (`ThreatTriageAgent.py`)
AI-powered agent for initial security alert analysis and triage.

**Usage:**
``````powershell
python ThreatTriageAgent.py
``````

### 2. Defender Alert Monitor (`DefenderAlertMonitor.ps1`)
Monitors Windows Defender for threat detections.

**Usage:**
``````powershell
powershell -ExecutionPolicy Bypass -File DefenderAlertMonitor.ps1
``````

### 3. Grafana Dashboard
Access at: http://localhost:3000
- Default credentials: admin/admin
- Import dashboard configuration from `dashboard_config.json`

## Quick Start

1. Start Grafana:
   ``````
   $grafanaPath\start-grafana.bat
   ``````

2. Run Threat Triage Agent:
   ``````
   python ThreatTriageAgent.py
   ``````

3. Monitor Defender alerts:
   ``````
   powershell DefenderAlertMonitor.ps1
   ``````

## Integration Points

- **Windows Defender**: Real-time threat detection
- **Event Logs**: System and security event monitoring
- **Network**: Traffic analysis and anomaly detection
- **AI Agents**: Automated triage and response

## Security Best Practices

1. Run monitoring tools with appropriate permissions
2. Review and validate AI recommendations before taking action
3. Maintain audit logs of all security events
4. Regularly update threat intelligence sources
5. Test incident response procedures

## Next Steps

1. Configure Grafana data sources
2. Customize alert thresholds
3. Integrate with external SIEM if available
4. Set up automated response playbooks
5. Train team on SOC tools and procedures
"@

    $socReadmePath = "$socDir\README.md"
    Set-Content -Path $socReadmePath -Value $socReadme
    Write-Host "✓ SOC workspace README created: $socReadmePath" -ForegroundColor Green

    Write-Host ""
    Write-Host "=== Phase 4 Complete ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Summary of changes:" -ForegroundColor Yellow
    Write-Host "✓ Grafana installed for threat dashboards" -ForegroundColor Green
    Write-Host "✓ Security tools installed (Wireshark, Nmap, Sysinternals)" -ForegroundColor Green
    Write-Host "✓ AI Threat Triage Agent created" -ForegroundColor Green
    Write-Host "✓ Defender Alert Monitor configured" -ForegroundColor Green
    Write-Host "✓ Dashboard configurations prepared" -ForegroundColor Green
    Write-Host ""
    Write-Host "SOC Workspace: $socDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Start Grafana: $grafanaPath\start-grafana.bat" -ForegroundColor White
    Write-Host "2. Access Grafana at http://localhost:3000 (admin/admin)" -ForegroundColor White
    Write-Host "3. Test Threat Triage Agent: python $triageAgentPath" -ForegroundColor White
    Write-Host "4. Review SOC workspace README: $socReadmePath" -ForegroundColor White
    Write-Host "5. Proceed to Phase5-Testing-Optimization.ps1" -ForegroundColor White
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "=== Error During SOC Integration ===" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    exit 1
}
