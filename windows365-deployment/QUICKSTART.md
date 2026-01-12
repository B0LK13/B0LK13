# Quick Start Guide - Windows 365 Cloud PC Deployment

This guide gets you started quickly with the Windows 365 Cloud PC deployment scripts.

## ⚡ 5-Minute Quick Start

### Prerequisites Check

```powershell
# 1. Check PowerShell version (need 5.1+)
$PSVersionTable.PSVersion

# 2. Install required modules
Install-Module -Name Az -Scope CurrentUser -Force
Install-Module Microsoft.Graph -Scope CurrentUser -Force

# 3. Login to Azure
Connect-AzAccount
```

### Phase 1: Provision Cloud PC (Local Machine)

```powershell
# Download scripts
git clone https://github.com/B0LK13/B0LK13.git
cd B0LK13/windows365-deployment/scripts

# Run Phase 1
.\Phase1-Provision-CloudPC.ps1 `
    -SubscriptionId "YOUR-SUBSCRIPTION-ID" `
    -UserPrincipalName "user@yourdomain.com"

# Wait 15-30 minutes for provisioning
# Access at: https://windows365.microsoft.com
```

### Phases 2-5: Configure Cloud PC (Inside Cloud PC)

```powershell
# Copy scripts to Cloud PC, then:

# Phase 2: Base OS (15-20 min)
.\Phase2-BaseOS-Customization.ps1
# Reboot when prompted

# Phase 3: Desktop (10-15 min)
.\Phase3-Desktop-Customization.ps1
# Restart Explorer when prompted

# Phase 4: SOC Integration (15-20 min)
.\Phase4-Military-Interfaces.ps1

# Phase 5: Testing (10-15 min)
.\Phase5-Testing-Optimization.ps1
```

## 📦 What Gets Installed

### Development Tools
- Git
- Python 3.12
- Visual Studio Code
- PowerShell 7
- Windows Terminal
- Notepad++
- 7-Zip

### Security Tools
- Wireshark
- Nmap
- Sysinternals Suite
- Windows Defender (configured)

### Desktop Customization
- GlazeWM (Tiling Window Manager)
- Rainmeter (System Monitor)
- Custom themes and wallpapers

### SOC Components
- Grafana (http://localhost:3000)
- AI Threat Triage Agent
- Defender Alert Monitor

## 🎮 Essential Keybindings (GlazeWM)

| Action | Keys |
|--------|------|
| Open terminal | `Alt+Enter` |
| Switch workspace | `Alt+1-5` |
| Move window | `Alt+Shift+H/J/K/L` |
| Close window | `Alt+Shift+Q` |
| Maximize | `Alt+X` |

## 🔒 Security Notes

1. **Change Grafana password** after Phase 4 (default: admin/admin)
2. **Never hardcode credentials** in scripts
3. **Enable MFA** on all accounts
4. **Review test results** after Phase 5

## 📚 Full Documentation

- **Complete Guide:** [DEPLOYMENT_GUIDE.md](./docs/DEPLOYMENT_GUIDE.md)
- **Security:** [SECURITY_BEST_PRACTICES.md](./docs/SECURITY_BEST_PRACTICES.md)
- **Main README:** [README.md](./README.md)

## 🆘 Common Issues

### Script won't run
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Winget fails
```powershell
winget source reset --force
```

### GlazeWM not starting
```powershell
& "$env:ProgramFiles\GlazeWM\glazewm.exe"
# Check for errors
```

## ✅ Validation

```powershell
# Validate all scripts
.\Validate-Scripts.ps1

# Check installed tools
git --version
python --version
code --version

# Access SOC Dashboard
Start-Process "http://localhost:3000"
```

## 📊 Expected Timeline

| Phase | Duration | Location |
|-------|----------|----------|
| 1. Provisioning | 30-45 min | Local machine |
| 2. Base OS | 15-25 min | Cloud PC |
| 3. Desktop | 10-15 min | Cloud PC |
| 4. SOC Integration | 15-20 min | Cloud PC |
| 5. Testing | 10-15 min | Cloud PC |
| **Total** | **~90-120 min** | |

## 🎯 Success Criteria

After Phase 5, verify:

- [ ] All scripts completed without errors
- [ ] GlazeWM keybindings work
- [ ] Grafana accessible at localhost:3000
- [ ] Python agents run successfully
- [ ] Test report shows all passed
- [ ] Backup created in Documents

## 🚀 Next Steps

1. **User Training:** Learn GlazeWM keybindings
2. **Configure Grafana:** Set up custom dashboards
3. **Schedule Backups:** OneDrive or Azure Backup
4. **Monitor:** Check SOC dashboard daily
5. **Update:** Weekly Windows updates

---

**Need Help?** See [DEPLOYMENT_GUIDE.md](./docs/DEPLOYMENT_GUIDE.md) for detailed instructions.

**Security Questions?** Review [SECURITY_BEST_PRACTICES.md](./docs/SECURITY_BEST_PRACTICES.md).
