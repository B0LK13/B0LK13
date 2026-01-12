# Security Best Practices for Windows 365 Cloud PC

## Overview

This document outlines security best practices for deploying and maintaining Windows 365 Cloud PCs using these deployment scripts.

## Pre-Deployment Security

### 1. Azure and Identity Security

- **Multi-Factor Authentication (MFA)**
  - Enable MFA for all administrator accounts
  - Require MFA for Azure portal access
  - Configure Conditional Access policies

- **Role-Based Access Control (RBAC)**
  - Use least-privilege principle
  - Assign specific roles instead of Owner/Contributor when possible
  - Regularly audit role assignments

- **Azure AD Configuration**
  - Enable Azure AD Identity Protection
  - Configure risk-based policies
  - Monitor sign-in logs for anomalies

### 2. Secrets Management

**DO NOT** hardcode credentials in scripts. Instead:

```powershell
# Use Azure Key Vault
$secret = Get-AzKeyVaultSecret -VaultName "YourVault" -Name "SecretName"

# Or use environment variables
$apiKey = $env:API_KEY

# Or prompt securely
$credential = Get-Credential
```

### 3. Network Security

- Configure Network Security Groups (NSGs)
- Enable Azure Firewall or third-party firewall
- Restrict Cloud PC access to specific IP ranges if needed
- Use Azure Virtual Network for hybrid scenarios

## During Deployment

### Script Execution Security

1. **Verify Script Integrity**
   ```powershell
   # Check script hash before execution
   Get-FileHash .\Phase1-Provision-CloudPC.ps1 -Algorithm SHA256
   ```

2. **Execution Policy**
   ```powershell
   # Set appropriate execution policy
   Set-ExecutionPolicy RemoteSigned -Scope CurrentUser
   
   # Never use Unrestricted in production
   ```

3. **Run with Minimal Privileges**
   - Use regular user account when possible
   - Only elevate when necessary (Phase 2-5 require admin)
   - Close elevated sessions immediately after use

### Windows Defender Configuration

All scripts enable these security features:

- **Real-time Protection**: Continuously scans files
- **Cloud-delivered Protection**: Uses Microsoft cloud intelligence
- **Controlled Folder Access**: Protects against ransomware
- **PUA Protection**: Blocks potentially unwanted applications

### Additional Hardening

```powershell
# Enable BitLocker (if not enabled by policy)
Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256

# Enable Windows Firewall
Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True

# Disable unnecessary services
Set-Service -Name "RemoteRegistry" -StartupType Disabled
```

## Post-Deployment Security

### 1. Ongoing Monitoring

- **Windows Defender Monitoring**
  ```powershell
  # Check threat status daily
  Get-MpThreatDetection
  
  # Review protection history
  Get-MpThreat
  ```

- **Event Log Monitoring**
  - Monitor Security logs for failed logon attempts
  - Review Application logs for crashes
  - Check System logs for errors

- **SOC Dashboard**
  - Access Grafana dashboard regularly: http://localhost:3000
  - Run Threat Triage Agent on new alerts
  - Use Defender Alert Monitor for real-time detection

### 2. Update Management

```powershell
# Check for updates weekly
Get-WindowsUpdate

# Install critical updates immediately
Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot

# Update Defender signatures daily (automatic)
Update-MpSignature
```

### 3. Backup and Recovery

- **Configuration Backups**
  - Phase 5 creates automatic backups
  - Store backups in Azure Storage or OneDrive
  - Test restore procedures regularly

- **Azure Backup**
  ```powershell
  # Enable Azure Backup if not using Intune
  # Configure via Azure portal or backup policies
  ```

### 4. Access Control

- **Conditional Access**
  - Require MFA for Cloud PC access
  - Block access from untrusted locations
  - Require compliant devices

- **Session Management**
  - Configure idle timeout policies
  - Enable session recording for compliance
  - Review access logs regularly

## Security for SOC Components

### Grafana Security

```powershell
# Change default admin password immediately
# Access http://localhost:3000
# Admin > Profile > Change Password

# Enable HTTPS (production)
# Edit grafana.ini:
# [server]
# protocol = https
# cert_file = /path/to/cert.crt
# cert_key = /path/to/cert.key
```

### AI Agent Security

- **API Key Protection**
  ```python
  # Never hardcode API keys
  import os
  api_key = os.environ.get('OPENAI_API_KEY')
  
  # Or use Azure Key Vault
  from azure.keyvault.secrets import SecretClient
  ```

- **Input Validation**
  - Sanitize all inputs to AI agents
  - Validate alert data before processing
  - Implement rate limiting

### Network Security Tools

- **Wireshark**
  - Only capture traffic when investigating incidents
  - Store captures securely
  - Delete captures after analysis

- **Nmap**
  - Only scan authorized networks
  - Document all scanning activities
  - Avoid aggressive scans on production

## Compliance and Auditing

### 1. Audit Logging

```powershell
# Enable audit policies
auditpol /set /category:"Logon/Logoff" /success:enable /failure:enable
auditpol /set /category:"Object Access" /success:enable /failure:enable

# Review audit logs
Get-EventLog -LogName Security -Newest 100
```

### 2. Compliance Checks

- **GDPR Compliance**
  - Ensure data residency requirements (Location parameter)
  - Implement data retention policies
  - Document data processing activities

- **Industry Standards**
  - Align with CIS Benchmarks for Windows
  - Follow NIST Cybersecurity Framework
  - Implement ISO 27001 controls where applicable

### 3. Regular Security Assessments

```powershell
# Run Windows Security Compliance Toolkit
# Download from Microsoft: https://www.microsoft.com/en-us/download/details.aspx?id=55319

# Security baseline assessment
# LocalGPO /v /s /e
```

## Incident Response

### Preparation

1. **Incident Response Plan**
   - Define roles and responsibilities
   - Establish communication channels
   - Document escalation procedures

2. **Forensics Preparation**
   ```powershell
   # Enable forensic logging
   wevtutil sl Security /ms:1024000
   wevtutil sl System /ms:1024000
   
   # Create forensic collection script
   # See Phase4 SOC workspace for templates
   ```

### Detection and Analysis

1. **Use Threat Triage Agent**
   ```powershell
   python "$env:USERPROFILE\Documents\SOC-Workspace\ThreatTriageAgent.py"
   ```

2. **Collect Evidence**
   ```powershell
   # Create memory dump (if needed)
   # Use Sysinternals ProcDump or Windows built-in tools
   
   # Collect event logs
   wevtutil epl Security "$env:USERPROFILE\Desktop\security.evtx"
   ```

### Containment and Recovery

1. **Immediate Actions**
   ```powershell
   # Isolate system from network (if compromised)
   Disable-NetAdapter -Name "Ethernet"
   
   # Block suspicious IP
   New-NetFirewallRule -DisplayName "Block Malicious IP" `
       -Direction Outbound -RemoteAddress "1.2.3.4" -Action Block
   ```

2. **Recovery**
   - Restore from known-good backup
   - Re-run security scans
   - Update all credentials
   - Review and update security policies

## Security Checklist

### Daily
- [ ] Review Windows Defender alerts
- [ ] Check Grafana dashboard for anomalies
- [ ] Monitor failed login attempts
- [ ] Verify backup completion

### Weekly
- [ ] Install critical updates
- [ ] Review security event logs
- [ ] Run full malware scan
- [ ] Test incident response procedures

### Monthly
- [ ] Review and update access controls
- [ ] Audit user permissions
- [ ] Update security documentation
- [ ] Test disaster recovery

### Quarterly
- [ ] Security assessment/penetration test
- [ ] Review and update security policies
- [ ] Staff security training
- [ ] Compliance audit

## Resources

- **Microsoft Security Documentation**
  - https://docs.microsoft.com/en-us/security/
  - https://docs.microsoft.com/en-us/windows-365/

- **Security Tools**
  - Windows Defender: Built-in
  - Microsoft Defender for Cloud: https://azure.microsoft.com/services/defender-for-cloud/
  - Azure Sentinel: https://azure.microsoft.com/services/microsoft-sentinel/

- **Compliance**
  - CIS Benchmarks: https://www.cisecurity.org/cis-benchmarks/
  - NIST Framework: https://www.nist.gov/cyberframework

## Contact

For security incidents or concerns:
1. Follow your organization's incident response procedures
2. Contact your security team immediately
3. Document all actions taken

---

**Last Updated:** 2026-01-12  
**Version:** 1.0.0
