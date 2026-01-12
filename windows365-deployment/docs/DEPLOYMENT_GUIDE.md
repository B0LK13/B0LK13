# Windows 365 Cloud PC Deployment Guide

## Step-by-Step Deployment Instructions

This guide provides detailed instructions for deploying Windows 365 Cloud PCs using the automated PowerShell scripts.

## Table of Contents

1. [Pre-Deployment Planning](#pre-deployment-planning)
2. [Phase 1: Provisioning](#phase-1-provisioning)
3. [Phase 2: Base OS Customization](#phase-2-base-os-customization)
4. [Phase 3: Desktop Customization](#phase-3-desktop-customization)
5. [Phase 4: SOC Integration](#phase-4-soc-integration)
6. [Phase 5: Testing and Finalization](#phase-5-testing-and-finalization)
7. [Post-Deployment Tasks](#post-deployment-tasks)
8. [Troubleshooting](#troubleshooting)

---

## Pre-Deployment Planning

### 1. Gather Required Information

Before starting, collect the following information:

| Item | Description | Example |
|------|-------------|---------|
| Subscription ID | Your Azure subscription ID | `12345678-1234-1234-1234-123456789012` |
| User Principal Name | User email address | `user@contoso.com` |
| Resource Group Name | Name for Azure resources | `CyberAgencyRG` |
| Azure Region | Deployment location | `westeurope` or `eastus` |
| Cloud PC Size | VM specifications | `8vCPU-32GB-512GB` |

### 2. Verify Prerequisites

**On Your Local Machine:**

```powershell
# Check PowerShell version (should be 5.1 or later)
$PSVersionTable.PSVersion

# Check if Azure modules are installed
Get-Module -ListAvailable -Name Az
Get-Module -ListAvailable -Name Microsoft.Graph

# If not installed, run:
Install-Module -Name Az -Scope CurrentUser -Force
Install-Module Microsoft.Graph -Scope CurrentUser -Force
```

**Azure/Microsoft 365 Setup:**

1. Verify you have:
   - Azure subscription with Contributor or Owner role
   - Windows 365 licenses purchased and available
   - Intune configured (comes with Microsoft 365)

2. Log in to Azure:
   ```powershell
   Connect-AzAccount
   ```

### 3. Download Deployment Scripts

```powershell
# Clone or download the repository
git clone https://github.com/B0LK13/B0LK13.git
cd B0LK13/windows365-deployment

# Or download ZIP and extract
# Then navigate to: windows365-deployment/scripts
```

### 4. Review Scripts

**Important:** Review all scripts before execution to understand what they do and customize if needed.

```powershell
# View script contents
Get-Content .\scripts\Phase1-Provision-CloudPC.ps1 | more
```

---

## Phase 1: Provisioning

**Duration:** 30-45 minutes (mostly automated waiting)  
**Location:** Run on your local machine  
**Requires:** Azure PowerShell, Microsoft Graph

### Step 1: Prepare Parameters

Create a parameter file or prepare command:

```powershell
# Option 1: Interactive prompts (recommended for first time)
$subscriptionId = Read-Host "Enter your Azure Subscription ID"
$userPrincipalName = Read-Host "Enter user email (e.g., user@domain.com)"

# Option 2: Direct values
$subscriptionId = "your-subscription-id"
$userPrincipalName = "user@domain.com"
$resourceGroupName = "CyberAgencyRG"
$location = "westeurope"
$cloudPcSize = "8vCPU-32GB-512GB"
```

### Step 2: Execute Phase 1

```powershell
cd windows365-deployment/scripts

# Run the provisioning script
.\Phase1-Provision-CloudPC.ps1 `
    -SubscriptionId $subscriptionId `
    -UserPrincipalName $userPrincipalName `
    -ResourceGroupName $resourceGroupName `
    -Location $location `
    -CloudPcSize $cloudPcSize
```

### Step 3: Monitor Provisioning

The script will:
1. Create Azure resource group (if needed)
2. Connect to Microsoft Graph
3. Create Windows 365 provisioning policy
4. Assign policy to user

**Expected output:**
```
=== Phase 1: Provisioning Windows 365 Cloud PC ===
[1/6] Setting Azure subscription context...
✓ Subscription context set
[2/6] Checking resource group...
✓ Resource group created
...
=== Provisioning Initiated ===
```

### Step 4: Wait for Cloud PC Provisioning

1. Go to https://windows365.microsoft.com
2. Sign in with the user account
3. Monitor provisioning status (typically 15-30 minutes)

**Provisioning States:**
- **Provisioning:** Cloud PC is being created
- **Provisioned:** Ready to use
- **Failed:** Check Intune portal for errors

### Step 5: Access Cloud PC

Once provisioned:

**Option 1: Web Browser**
1. Go to https://windows365.microsoft.com
2. Click "Open in browser" for your Cloud PC

**Option 2: Remote Desktop**
1. Download RDP file from windows365.microsoft.com
2. Open with Remote Desktop Connection
3. Sign in with user credentials

---

## Phase 2: Base OS Customization

**Duration:** 15-25 minutes  
**Location:** Inside Cloud PC (via Remote Desktop)  
**Requires:** Administrator privileges

### Step 1: Copy Scripts to Cloud PC

**Option 1: Download directly in Cloud PC**
```powershell
# Inside Cloud PC, open PowerShell
cd $env:USERPROFILE\Desktop
mkdir CloudPC-Setup
cd CloudPC-Setup

# Download from repository
# (Adjust URL to your repository location)
Invoke-WebRequest -Uri "https://github.com/B0LK13/B0LK13/archive/refs/heads/main.zip" -OutFile "scripts.zip"
Expand-Archive -Path "scripts.zip" -DestinationPath "."
cd "B0LK13-main\windows365-deployment\scripts"
```

**Option 2: Copy via OneDrive/SharePoint**
1. Upload scripts to OneDrive on local machine
2. Access OneDrive in Cloud PC
3. Download scripts folder

### Step 2: Open PowerShell as Administrator

```powershell
# Right-click PowerShell icon
# Select "Run as Administrator"

# Navigate to scripts directory
cd $env:USERPROFILE\Desktop\CloudPC-Setup\scripts
```

### Step 3: Set Execution Policy

```powershell
# Allow script execution
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser

# Confirm when prompted
```

### Step 4: Execute Phase 2

```powershell
# Run the base customization script
.\Phase2-BaseOS-Customization.ps1
```

**What happens:**
1. Windows updates installed (may take 10-15 minutes)
2. Dark mode enabled
3. Windows Defender configured
4. Essential tools installed via Winget:
   - Git
   - Python 3.12
   - VS Code
   - PowerShell 7
   - Windows Terminal
   - 7-Zip
   - Notepad++

### Step 5: Review Output and Reboot

**Expected output:**
```
=== Phase 2: Base OS Customization ===
[1/5] Installing Windows Updates...
✓ Windows updates installed
[2/5] Configuring UI and accessibility...
✓ Dark mode enabled
...
=== Phase 2 Complete ===

Would you like to restart now? (Y/N)
```

**Action:** Type `Y` to reboot, or reboot manually later.

### Step 6: Verify Installation

After reboot:
```powershell
# Check installed tools
git --version
python --version
code --version
pwsh --version
```

---

## Phase 3: Desktop Customization

**Duration:** 10-15 minutes  
**Location:** Inside Cloud PC (after reboot from Phase 2)  
**Requires:** Administrator privileges

### Step 1: Open PowerShell as Administrator

```powershell
# Navigate to scripts directory
cd $env:USERPROFILE\Desktop\CloudPC-Setup\scripts
```

### Step 2: Execute Phase 3

```powershell
.\Phase3-Desktop-Customization.ps1
```

**What happens:**
1. SecureUxTheme installed (for custom themes)
2. Accent colors configured (cyberpunk orange-red theme)
3. GlazeWM tiling window manager installed
4. Rainmeter installed
5. Custom wallpaper applied
6. Taskbar and File Explorer optimized

### Step 3: Review and Apply Changes

**Expected output:**
```
=== Phase 3: Desktop Environment Customization ===
[1/6] Installing SecureUxTheme...
✓ SecureUxTheme downloaded
...
Would you like to restart Explorer now? (Y/N)
```

**Action:** Type `Y` to restart Explorer.

### Step 4: Configure GlazeWM

GlazeWM is now installed and will start automatically on next login.

**Test GlazeWM:**
```
Press Alt+Enter to open Windows Terminal
Press Alt+1 to switch to workspace 1
Press Alt+Shift+Q to close a window
```

**Customize GlazeWM:**
Edit config at: `$env:USERPROFILE\.glzr\glazewm\config.yaml`

### Step 5: Optional - Install Rainmeter Skins

1. Visit https://www.deviantart.com/rainmeter
2. Download desired skins (e.g., NeonTacticalHUD, ModernGadgets)
3. Double-click .rmskin files to install
4. Right-click Rainmeter tray icon > Manage to configure

---

## Phase 4: SOC Integration

**Duration:** 15-20 minutes  
**Location:** Inside Cloud PC  
**Requires:** Administrator privileges, Python installed

### Step 1: Execute Phase 4

```powershell
# Open PowerShell as Administrator
cd $env:USERPROFILE\Desktop\CloudPC-Setup\scripts

.\Phase4-Military-Interfaces.ps1
```

**What happens:**
1. Grafana installed for threat dashboards
2. Security tools installed (Wireshark, Nmap, Sysinternals)
3. Python packages installed for AI agents
4. Threat Triage Agent script created
5. Defender Alert Monitor created
6. Dashboard configurations prepared

### Step 2: Start Grafana

```powershell
# Start Grafana server
& "$env:ProgramFiles\Grafana\start-grafana.bat"

# Access Grafana in browser
Start-Process "http://localhost:3000"

# Default credentials: admin/admin
# IMPORTANT: Change password on first login!
```

### Step 3: Test AI Threat Triage Agent

```powershell
# Navigate to SOC workspace
cd "$env:USERPROFILE\Documents\SOC-Workspace"

# Run the triage agent
python ThreatTriageAgent.py

# Expected output:
# Processing alerts...
# === THREAT TRIAGE REPORT ===
# ...
```

### Step 4: Configure Grafana Dashboard

1. Log in to Grafana (http://localhost:3000)
2. Change default password
3. Add data sources:
   - Configuration > Data sources > Add data source
   - Options: Prometheus, Windows Event Log, etc.
4. Import dashboard:
   - Create > Import
   - Upload `dashboard_config.json` from SOC-Workspace

### Step 5: Set Up Monitoring

**Option 1: Run Defender Monitor Manually**
```powershell
powershell "$env:USERPROFILE\Documents\SOC-Workspace\DefenderAlertMonitor.ps1"
```

**Option 2: Create Scheduled Task**
```powershell
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-File `"$env:USERPROFILE\Documents\SOC-Workspace\DefenderAlertMonitor.ps1`""
$trigger = New-ScheduledTaskTrigger -AtStartup
Register-ScheduledTask -TaskName "DefenderAlertMonitor" `
    -Action $action -Trigger $trigger -User $env:USERNAME
```

---

## Phase 5: Testing and Finalization

**Duration:** 10-15 minutes  
**Location:** Inside Cloud PC  
**Requires:** Administrator privileges

### Step 1: Execute Phase 5

```powershell
# Open PowerShell as Administrator
cd $env:USERPROFILE\Desktop\CloudPC-Setup\scripts

.\Phase5-Testing-Optimization.ps1
```

**What happens:**
1. Security scans performed
2. Tool installations verified
3. Performance analyzed
4. System optimized
5. Configuration backed up
6. Documentation generated

### Step 2: Review Test Results

```powershell
# View test results
notepad "$env:USERPROFILE\Documents\Deployment-Tests\Test-Results-*.md"

# View deployment report
notepad "$env:USERPROFILE\Documents\Deployment-Tests\Deployment-Report-*.md"
```

### Step 3: Verify All Components

**Checklist:**
- [ ] All tools installed and working
- [ ] GlazeWM keybindings functional
- [ ] Grafana accessible at localhost:3000
- [ ] Python and AI agents working
- [ ] Security features enabled
- [ ] No critical errors in test report

### Step 4: Review Backup

```powershell
# Navigate to backup directory
$backupDir = Get-ChildItem "$env:USERPROFILE\Documents\CloudPC-Backup-*" | 
    Sort-Object LastWriteTime -Descending | Select-Object -First 1

explorer $backupDir.FullName
```

**Backup includes:**
- GlazeWM configuration
- SOC workspace files
- Installed applications list
- Enabled Windows features

### Step 5: Address Any Issues

Review test results and fix any failures:

```powershell
# Re-run security scan if needed
Start-MpScan -ScanType QuickScan

# Re-install failed tools
winget install --id ToolName -e

# Verify Defender settings
Get-MpPreference
```

---

## Post-Deployment Tasks

### 1. User Training

- **GlazeWM Basics:** Train users on tiling window manager keybindings
- **SOC Tools:** Explain Grafana dashboard and threat triage process
- **Security Awareness:** Brief on Windows Defender features

### 2. Configure Additional Security

```powershell
# Enable BitLocker (if not enabled)
Enable-BitLocker -MountPoint "C:" -EncryptionMethod XtsAes256

# Configure Windows Firewall rules
New-NetFirewallRule -DisplayName "Block Suspicious Traffic" `
    -Direction Outbound -RemoteAddress "suspicious-ip" -Action Block

# Set password policies
# (Usually managed via Intune/Azure AD)
```

### 3. Set Up Automated Backups

**Option 1: OneDrive (Recommended)**
```powershell
# Configure OneDrive to backup important folders
# Settings > Backup > Manage backup

# Include:
# - Desktop
# - Documents
# - SOC-Workspace
```

**Option 2: Azure Backup**
- Configure via Azure portal
- Set retention policies
- Test restore procedures

### 4. Schedule Maintenance Tasks

```powershell
# Weekly Windows Update check
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-Command Get-WindowsUpdate; Install-WindowsUpdate -AcceptAll"
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2am
Register-ScheduledTask -TaskName "WeeklyUpdates" `
    -Action $action -Trigger $trigger

# Daily Defender scan
$action = New-ScheduledTaskAction -Execute "PowerShell.exe" `
    -Argument "-Command Start-MpScan -ScanType QuickScan"
$trigger = New-ScheduledTaskTrigger -Daily -At 3am
Register-ScheduledTask -TaskName "DailyDefenderScan" `
    -Action $action -Trigger $trigger
```

### 5. Documentation

Create user documentation:
- **Quick Start Guide:** Basic operations and tools
- **SOC Procedures:** How to respond to alerts
- **Troubleshooting Guide:** Common issues and solutions

### 6. Monitoring Setup

- Add Cloud PC to monitoring dashboard
- Configure alerts for critical events
- Set up log forwarding to SIEM (if applicable)

---

## Troubleshooting

### Common Issues and Solutions

#### Issue: "Execution Policy" Error

**Error:** "File cannot be loaded because running scripts is disabled"

**Solution:**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

#### Issue: Winget Install Failures

**Error:** "Failed to install package"

**Solution:**
```powershell
# Update winget sources
winget source update

# Reset winget
winget source reset --force

# Try installing manually
winget install --id PackageName -e --force
```

#### Issue: GlazeWM Not Starting

**Error:** GlazeWM doesn't start automatically

**Solution:**
```powershell
# Check if executable exists
Test-Path "$env:ProgramFiles\GlazeWM\glazewm.exe"

# Check startup folder
explorer ([Environment]::GetFolderPath("Startup"))

# Manually start to see errors
& "$env:ProgramFiles\GlazeWM\glazewm.exe"
```

#### Issue: Grafana Won't Start

**Error:** "Cannot access localhost:3000"

**Solution:**
```powershell
# Check if port is in use
netstat -ano | findstr :3000

# Start Grafana manually
cd "$env:ProgramFiles\Grafana\bin"
.\grafana-server.exe

# Check logs
Get-Content "$env:ProgramFiles\Grafana\data\log\grafana.log" -Tail 50
```

#### Issue: Python Packages Won't Install

**Error:** "pip install fails"

**Solution:**
```powershell
# Update pip
python -m pip install --upgrade pip

# Use --user flag
python -m pip install package-name --user

# Check Python version
python --version  # Should be 3.12 or later
```

### Getting Additional Help

1. **Review Logs:**
   - Windows Event Viewer: `eventvwr.msc`
   - PowerShell transcripts (if enabled)
   - Individual tool logs

2. **Check Documentation:**
   - [SECURITY_BEST_PRACTICES.md](./SECURITY_BEST_PRACTICES.md)
   - Tool-specific documentation in configs/

3. **Support Channels:**
   - Open issue in GitHub repository
   - Contact your IT support team
   - Azure support for subscription issues

---

## Deployment Checklist

Use this checklist to track your deployment progress:

### Pre-Deployment
- [ ] Azure subscription verified
- [ ] Windows 365 licenses available
- [ ] Azure PowerShell installed
- [ ] Microsoft Graph module installed
- [ ] Parameters collected (subscription ID, user email, etc.)
- [ ] Scripts downloaded and reviewed

### Phase 1: Provisioning
- [ ] Resource group created
- [ ] Provisioning policy created
- [ ] Policy assigned to user
- [ ] Cloud PC provisioned (15-30 min wait)
- [ ] Able to access Cloud PC via RDP or browser

### Phase 2: Base OS
- [ ] Scripts copied to Cloud PC
- [ ] Windows updates installed
- [ ] Dark mode enabled
- [ ] Windows Defender configured
- [ ] Tools installed (Git, Python, VS Code, etc.)
- [ ] System rebooted

### Phase 3: Desktop
- [ ] SecureUxTheme installed
- [ ] GlazeWM installed and configured
- [ ] Rainmeter installed
- [ ] Custom wallpaper applied
- [ ] Explorer restarted
- [ ] GlazeWM keybindings tested

### Phase 4: SOC Integration
- [ ] Grafana installed
- [ ] Security tools installed
- [ ] Python environment configured
- [ ] AI agents created
- [ ] Grafana accessible
- [ ] Default password changed

### Phase 5: Testing
- [ ] Security scans completed
- [ ] Tool installations verified
- [ ] Performance analyzed
- [ ] Configuration backed up
- [ ] Test report reviewed
- [ ] All issues resolved

### Post-Deployment
- [ ] User training completed
- [ ] Additional security configured
- [ ] Backups scheduled
- [ ] Monitoring configured
- [ ] Documentation created
- [ ] Deployment signed off

---

**Deployment Complete!**

Your Windows 365 Cloud PC is now fully configured and ready for production use.

For ongoing maintenance and security, refer to:
- [SECURITY_BEST_PRACTICES.md](./SECURITY_BEST_PRACTICES.md)
- Generated deployment reports in Documents/Deployment-Tests/

---

**Last Updated:** 2026-01-12  
**Version:** 1.0.0
