# Phase 2: Base OS Customization
# Run inside Cloud PC after successful provisioning
# This script updates Windows, installs essential tools, and configures security

<#
.SYNOPSIS
    Customizes the base Windows 365 Cloud PC operating system.

.DESCRIPTION
    This script performs the following:
    - Updates Windows OS to latest patches
    - Enables dark mode and accessibility features
    - Configures Windows Defender security settings
    - Installs essential development and security tools via Winget
    - Prepares the system for desktop customization

.EXAMPLE
    .\Phase2-BaseOS-Customization.ps1

.NOTES
    Run with administrator privileges inside the Cloud PC.
    System may require reboot after completion.
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
    Write-Host "=== Phase 2: Base OS Customization ===" -ForegroundColor Cyan
    Write-Host "Starting system configuration..." -ForegroundColor Gray
    Write-Host ""

    # Update Windows
    Write-Host "[1/5] Installing Windows Updates..." -ForegroundColor Yellow
    try {
        # Install PSWindowsUpdate module if not present
        if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
            Write-Host "Installing PSWindowsUpdate module..." -ForegroundColor Gray
            Install-Module PSWindowsUpdate -Force -Scope CurrentUser
            Import-Module PSWindowsUpdate
        }
        
        Write-Host "Checking for Windows updates (this may take several minutes)..." -ForegroundColor Gray
        Get-WindowsUpdate -AcceptAll -Install -AutoReboot:$false | Out-Null
        Write-Host "✓ Windows updates installed" -ForegroundColor Green
    } catch {
        Write-Warning "Windows Update installation encountered issues: $($_.Exception.Message)"
        Write-Host "Continuing with remaining configuration..." -ForegroundColor Yellow
    }

    # Configure UI preferences
    Write-Host "[2/5] Configuring UI and accessibility..." -ForegroundColor Yellow
    
    # Enable dark mode
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value 0 -Type DWord
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "SystemUsesLightTheme" -Value 0 -Type DWord
    
    # Disable transparency effects for better performance
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -Type DWord
    
    Write-Host "✓ Dark mode enabled" -ForegroundColor Green

    # Configure Windows Defender
    Write-Host "[3/5] Configuring Windows Defender security..." -ForegroundColor Yellow
    
    # Enable Controlled Folder Access
    Set-MpPreference -EnableControlledFolderAccess Enabled
    
    # Enable PUA protection
    Set-MpPreference -PUAProtection Enabled
    
    # Enable real-time monitoring
    Set-MpPreference -DisableRealtimeMonitoring $false
    
    # Enable cloud-delivered protection
    Set-MpPreference -MAPSReporting Advanced
    
    Write-Host "✓ Windows Defender configured" -ForegroundColor Green

    # Install essential tools via Winget
    Write-Host "[4/5] Installing essential tools (this may take 10-15 minutes)..." -ForegroundColor Yellow
    
    $tools = @(
        @{Name="Git"; Id="Git.Git"},
        @{Name="PowerShell 7"; Id="Microsoft.PowerShell"},
        @{Name="Visual Studio Code"; Id="Microsoft.VisualStudioCode"},
        @{Name="Python 3.12"; Id="Python.Python.3.12"},
        @{Name="7-Zip"; Id="7zip.7zip"},
        @{Name="Windows Terminal"; Id="Microsoft.WindowsTerminal"},
        @{Name="Notepad++"; Id="Notepad++.Notepad++"}
    )

    foreach ($tool in $tools) {
        try {
            Write-Host "  Installing $($tool.Name)..." -ForegroundColor Gray
            winget install --id $tool.Id -e --accept-package-agreements --accept-source-agreements --silent
            Write-Host "  ✓ $($tool.Name) installed" -ForegroundColor Green
        } catch {
            Write-Warning "Failed to install $($tool.Name): $($_.Exception.Message)"
        }
    }

    # Optional security tools (commented out by default)
    Write-Host "[5/5] System optimization..." -ForegroundColor Yellow
    
    # Disable unnecessary startup programs
    # Get-CimInstance Win32_StartupCommand | Where-Object {$_.Location -notlike "*Microsoft*"} | Remove-CimInstance
    
    # Clean temporary files
    Write-Host "Cleaning temporary files..." -ForegroundColor Gray
    Remove-Item -Path "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    
    # Update Windows Defender signatures
    Write-Host "Updating Windows Defender signatures..." -ForegroundColor Gray
    Update-MpSignature
    
    Write-Host "✓ System optimization complete" -ForegroundColor Green

    Write-Host ""
    Write-Host "=== Phase 2 Complete ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Summary of changes:" -ForegroundColor Yellow
    Write-Host "✓ Windows updates installed" -ForegroundColor Green
    Write-Host "✓ Dark mode enabled" -ForegroundColor Green
    Write-Host "✓ Security features configured" -ForegroundColor Green
    Write-Host "✓ Essential development tools installed" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Restart the computer to apply all changes: Restart-Computer" -ForegroundColor White
    Write-Host "2. After restart, run Phase3-Desktop-Customization.ps1" -ForegroundColor White
    Write-Host "3. Verify all tools are accessible via Start Menu" -ForegroundColor White
    Write-Host ""
    
    # Ask if user wants to restart now
    $restart = Read-Host "Would you like to restart now? (Y/N)"
    if ($restart -eq 'Y' -or $restart -eq 'y') {
        Write-Host "Restarting in 10 seconds... Press Ctrl+C to cancel" -ForegroundColor Yellow
        Start-Sleep -Seconds 10
        Restart-Computer -Force
    }

} catch {
    Write-Host ""
    Write-Host "=== Error During Base OS Customization ===" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    exit 1
}
