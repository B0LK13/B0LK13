# Windows 365 Cloud PC Deployment Scripts

**All-in-One Deployment Scripts for Windows 365 Cloud Machine Setup**

This repository provides self-contained, all-in-one PowerShell scripts for each phase of Windows 365 Cloud PC deployment. These scripts are designed for automation where possible, creating a fully configured development and security operations environment.

## 🚀 Quick Start

**New to this?** Start here: [QUICKSTART.md](./QUICKSTART.md) - Get up and running in ~90 minutes!

## 📋 Table of Contents

- [Overview](#overview)
- [Prerequisites](#prerequisites)
- [Deployment Phases](#deployment-phases)
- [Getting Started](#getting-started)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)
- [Support](#support)

## 🎯 Overview

This deployment automates the setup of a Windows 365 Cloud PC with:

- **Enterprise-grade security** with Windows Defender and monitoring tools
- **Development environment** with Git, Python, VS Code, and more
- **Custom desktop environment** with GlazeWM tiling window manager and Rainmeter
- **Security Operations Center (SOC)** with AI-powered threat triage agents
- **Military-style interfaces** with Grafana dashboards
- **Comprehensive testing and optimization**

## 📦 Prerequisites

### For All Scripts

1. **Azure and Microsoft 365 Access**
   - Active Azure subscription
   - Windows 365 license assigned
   - Appropriate permissions for Intune and Azure AD

2. **Local Machine Requirements** (for Phase 1)
   ```powershell
   # Install Azure PowerShell
   Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
   
   # Install Microsoft Graph PowerShell
   Install-Module Microsoft.Graph -Scope CurrentUser -Force
   
   # Log in to Azure
   Connect-AzAccount
   ```

3. **Cloud PC Requirements** (for Phases 2-5)
   - Windows 11 Enterprise (24H2 or later recommended)
   - Administrator privileges
   - Internet connectivity

### Configuration Placeholders

Before running scripts, replace these placeholders with your values:

- `<YourSubscriptionId>` - Your Azure subscription ID
- `<YourUserPrincipalName>` - User email (e.g., user@domain.com)
- `<ResourceGroupName>` - Azure resource group name (default: CyberAgencyRG)
- `<Location>` - Azure region (default: westeurope)

## 🚀 Deployment Phases

### Phase 1: Provisioning the Windows 365 Cloud PC
**Script:** `Phase1-Provision-CloudPC.ps1`  
**Location:** Run on local machine  
**Duration:** ~15-30 minutes (automated provisioning time)

Provisions the Cloud PC using Azure PowerShell and Microsoft Graph:
- Creates Azure resource group
- Creates Intune provisioning policy
- Assigns policy to user
- Monitors provisioning status

```powershell
.\Phase1-Provision-CloudPC.ps1 `
    -SubscriptionId "your-subscription-id" `
    -UserPrincipalName "user@domain.com" `
    -CloudPcSize "8vCPU-32GB-512GB"
```

**Expected Output:**
- Resource group created in Azure
- Provisioning policy created in Intune
- Cloud PC provisioning initiated
- Access URL: https://windows365.microsoft.com

---

### Phase 2: Base OS Customization
**Script:** `Phase2-BaseOS-Customization.ps1`  
**Location:** Run inside Cloud PC  
**Duration:** ~10-20 minutes

Customizes the base Windows operating system:
- Installs Windows updates
- Enables dark mode
- Configures Windows Defender security
- Installs essential development tools via Winget

```powershell
# Run as Administrator inside Cloud PC
.\Phase2-BaseOS-Customization.ps1
```

**Installed Tools:**
- Git
- PowerShell 7
- Visual Studio Code
- Python 3.12
- 7-Zip
- Windows Terminal
- Notepad++

---

### Phase 3: Desktop Environment Customization
**Script:** `Phase3-Desktop-Customization.ps1`  
**Location:** Run inside Cloud PC  
**Duration:** ~10-15 minutes

Customizes the desktop environment with advanced window management:
- Installs SecureUxTheme for custom themes
- Configures cyberpunk/military-style color scheme
- Installs and configures GlazeWM (tiling window manager)
- Installs Rainmeter for system monitoring
- Sets custom wallpapers and visual tweaks

```powershell
# Run as Administrator inside Cloud PC
.\Phase3-Desktop-Customization.ps1
```

**Key Features:**
- **GlazeWM Keybindings:**
  - `Alt+Enter` - Open terminal
  - `Alt+H/J/K/L` - Navigate windows
  - `Alt+1-5` - Switch workspaces
  - `Alt+Shift+Q` - Close window
  - `Alt+X` - Maximize/unmaximize

---

### Phase 4: Military-Style Interfaces and SOC Integration
**Script:** `Phase4-Military-Interfaces.ps1`  
**Location:** Run inside Cloud PC  
**Duration:** ~15-20 minutes

Sets up Security Operations Center tools and AI agents:
- Installs Grafana for threat dashboards
- Installs security tools (Wireshark, Nmap, Sysinternals)
- Creates AI-powered threat triage agent
- Configures alert monitoring scripts
- Sets up dashboard configurations

```powershell
# Run as Administrator inside Cloud PC
.\Phase4-Military-Interfaces.ps1
```

**SOC Components:**
- **Grafana Dashboard:** http://localhost:3000 (admin/admin)
- **Threat Triage Agent:** AI-powered security alert analysis
- **Defender Monitor:** Real-time threat detection monitoring
- **Dashboard Configs:** Pre-configured security dashboards

---

### Phase 5: Testing, Optimization, and Deployment
**Script:** `Phase5-Testing-Optimization.ps1`  
**Location:** Run inside Cloud PC  
**Duration:** ~10-15 minutes

Finalizes the setup with comprehensive testing:
- Runs security scans
- Verifies tool installations
- Analyzes system performance
- Optimizes system settings
- Creates configuration backups
- Generates deployment documentation

```powershell
# Run as Administrator inside Cloud PC
.\Phase5-Testing-Optimization.ps1
```

**Deliverables:**
- Test results report
- Deployment documentation
- Configuration backup
- Performance analysis
- Installation verification

---

## 🏁 Getting Started

### Quick Start (All Phases)

1. **On Your Local Machine:**
   ```powershell
   # Clone or download this repository
   cd windows365-deployment/scripts
   
   # Run Phase 1
   .\Phase1-Provision-CloudPC.ps1 -SubscriptionId "your-sub-id" -UserPrincipalName "user@domain.com"
   
   # Wait for provisioning (15-30 minutes)
   # Connect to Cloud PC via https://windows365.microsoft.com
   ```

2. **Inside Cloud PC (via Remote Desktop):**
   ```powershell
   # Copy scripts to Cloud PC or download from repository
   cd C:\CloudPC-Setup
   
   # Run Phase 2
   .\Phase2-BaseOS-Customization.ps1
   # Reboot when prompted
   
   # Run Phase 3
   .\Phase3-Desktop-Customization.ps1
   # Restart Explorer when prompted
   
   # Run Phase 4
   .\Phase4-Military-Interfaces.ps1
   
   # Run Phase 5
   .\Phase5-Testing-Optimization.ps1
   ```

3. **Verify Deployment:**
   ```powershell
   # Check test results
   notepad "$env:USERPROFILE\Documents\Deployment-Tests\Test-Results-*.md"
   
   # Check deployment report
   notepad "$env:USERPROFILE\Documents\Deployment-Tests\Deployment-Report-*.md"
   ```

### Step-by-Step Execution

For detailed step-by-step instructions, see [DEPLOYMENT_GUIDE.md](./docs/DEPLOYMENT_GUIDE.md)

## 🔒 Security Considerations

### ⚠️ Important Warnings

1. **Production Environment**
   - Test in non-production environment first
   - Review all scripts before execution
   - Validate configurations for your organization

2. **Cost Management**
   - Monitor Azure billing regularly
   - Windows 365 provisioning incurs costs
   - Consider auto-shutdown policies

3. **Secrets Management**
   - **Never hardcode credentials** in scripts
   - Use Azure Key Vault for production deployments
   - Rotate credentials regularly

4. **Network Security**
   - Configure Azure network security groups
   - Enable MFA for all accounts
   - Use Conditional Access policies

### Security Best Practices

- Run all scripts with minimal required permissions
- Review Windows Defender logs regularly
- Keep all tools and OS updated
- Enable audit logging for compliance
- Backup configurations before major changes

### Compliance

- Ensure compliance with organizational policies
- Review data residency requirements (Location parameter)
- Validate licensing for all installed tools
- Maintain audit trails of all changes

## 🔧 Troubleshooting

### Common Issues

#### Phase 1: Provisioning Errors

**Issue:** "Insufficient permissions" error
```powershell
# Solution: Verify you have necessary roles
Get-AzRoleAssignment -SignInName "your-email@domain.com"
# Required: Contributor or Owner on subscription
```

**Issue:** "Windows 365 license not found"
```
# Solution: Verify license assignment in M365 admin center
https://admin.microsoft.com > Users > Active users > Select user > Licenses
```

#### Phase 2-5: Execution Policy Errors

**Issue:** "Execution policy" prevents script execution
```powershell
# Solution: Set execution policy (run as Administrator)
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### GlazeWM Not Starting

**Issue:** GlazeWM doesn't start automatically
```powershell
# Solution: Manually start and check for errors
& "$env:ProgramFiles\GlazeWM\glazewm.exe"

# Check startup folder
explorer ([Environment]::GetFolderPath("Startup"))
```

#### Grafana Not Accessible

**Issue:** Cannot access Grafana at localhost:3000
```powershell
# Solution: Start Grafana manually
& "$env:ProgramFiles\Grafana\start-grafana.bat"

# Check if port is in use
netstat -ano | findstr :3000
```

### Getting Help

1. **Check Logs:**
   - Windows Event Viewer: Security and System logs
   - Script execution output
   - Individual tool logs

2. **Review Documentation:**
   - Tool-specific documentation in configs/
   - Deployment reports generated by Phase 5

3. **Community Support:**
   - Create an issue in this repository
   - Consult Windows 365 documentation
   - Azure support for subscription issues

## 📁 Repository Structure

```
windows365-deployment/
├── scripts/
│   ├── Phase1-Provision-CloudPC.ps1
│   ├── Phase2-BaseOS-Customization.ps1
│   ├── Phase3-Desktop-Customization.ps1
│   ├── Phase4-Military-Interfaces.ps1
│   └── Phase5-Testing-Optimization.ps1
├── configs/
│   └── glazewm-config.yaml
├── docs/
│   ├── DEPLOYMENT_GUIDE.md
│   └── SECURITY_BEST_PRACTICES.md
└── README.md
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Test changes in isolated environment
2. Document new features or modifications
3. Follow PowerShell best practices
4. Update relevant documentation

## 📄 License

This project is provided as-is for educational and deployment purposes. Review your organization's policies before use.

## 🆘 Support

For issues, questions, or contributions:

- **Issues:** Open an issue in this repository
- **Documentation:** See docs/ directory
- **Updates:** Check for script updates regularly

## ⚡ Quick Reference

### Essential Commands

```powershell
# Check script execution policy
Get-ExecutionPolicy

# Run script as Administrator
Start-Process powershell -Verb RunAs -ArgumentList "-File script.ps1"

# Check Windows version
winver

# Check installed tools
winget list

# Start Grafana
& "$env:ProgramFiles\Grafana\start-grafana.bat"

# Run threat triage agent
python "$env:USERPROFILE\Documents\SOC-Workspace\ThreatTriageAgent.py"

# Monitor Defender alerts
powershell "$env:USERPROFILE\Documents\SOC-Workspace\DefenderAlertMonitor.ps1"
```

### GlazeWM Keybindings Quick Reference

| Action | Keybinding |
|--------|------------|
| Open terminal | `Alt+Enter` |
| Focus left/right/up/down | `Alt+H/L/K/J` or Arrow keys |
| Move window | `Alt+Shift+H/L/K/J` |
| Switch workspace | `Alt+1-5` |
| Move to workspace | `Alt+Shift+1-5` |
| Toggle floating | `Alt+Shift+Space` |
| Maximize | `Alt+X` |
| Close window | `Alt+Shift+Q` |
| Reload config | `Alt+Shift+R` |

---

**Last Updated:** 2026-01-12  
**Version:** 1.0.0  
**Maintainer:** B0LK13 Cyber Agency
