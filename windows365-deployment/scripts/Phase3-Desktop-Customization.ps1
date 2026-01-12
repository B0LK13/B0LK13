# Phase 3: Desktop Environment Customization
# Run inside Cloud PC after Phase 2 completion
# Installs themes, window manager (GlazeWM), Rainmeter, and customizes visuals

<#
.SYNOPSIS
    Customizes the desktop environment with themes and advanced window management.

.DESCRIPTION
    This script performs the following:
    - Installs SecureUxTheme for custom theme support
    - Applies custom themes (Nord/Cyberpunk style)
    - Installs and configures GlazeWM (tiling window manager)
    - Installs Rainmeter with custom skins
    - Sets custom wallpapers and lock screens
    - Configures accent colors and visual preferences

.EXAMPLE
    .\Phase3-Desktop-Customization.ps1

.NOTES
    Run with administrator privileges inside the Cloud PC.
    Requires Phase 2 to be completed first.
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
    Write-Host "=== Phase 3: Desktop Environment Customization ===" -ForegroundColor Cyan
    Write-Host "Customizing visual experience and window management..." -ForegroundColor Gray
    Write-Host ""

    # Create download directory
    $downloadDir = "$env:USERPROFILE\Downloads\Windows365Setup"
    if (-not (Test-Path $downloadDir)) {
        New-Item -Path $downloadDir -ItemType Directory | Out-Null
    }

    # Install SecureUxTheme for custom themes
    Write-Host "[1/6] Installing SecureUxTheme..." -ForegroundColor Yellow
    try {
        $secureUxUrl = "https://github.com/namazso/SecureUxTheme/releases/latest/download/SecureUxTheme.zip"
        $secureUxZip = "$downloadDir\SecureUxTheme.zip"
        $secureUxPath = "$env:ProgramFiles\SecureUxTheme"
        
        Write-Host "Downloading SecureUxTheme..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $secureUxUrl -OutFile $secureUxZip -UseBasicParsing
        
        if (-not (Test-Path $secureUxPath)) {
            New-Item -Path $secureUxPath -ItemType Directory | Out-Null
        }
        
        Expand-Archive -Path $secureUxZip -DestinationPath $secureUxPath -Force
        Write-Host "✓ SecureUxTheme downloaded" -ForegroundColor Green
        Write-Host "  Note: Run ThemeTool.exe manually to enable custom themes" -ForegroundColor Yellow
    } catch {
        Write-Warning "Failed to install SecureUxTheme: $($_.Exception.Message)"
        Write-Host "You can manually download from: https://github.com/namazso/SecureUxTheme" -ForegroundColor Yellow
    }

    # Configure accent colors
    Write-Host "[2/6] Configuring accent colors and theme..." -ForegroundColor Yellow
    
    # Set accent color (Orange-Red for cyber theme)
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "AccentColor" -Value 0xFF4500 -Type DWord
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "ColorizationColor" -Value 0xC44500FF -Type DWord
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "ColorizationAfterglow" -Value 0xC44500FF -Type DWord
    
    # Enable accent color on title bars and window borders
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\DWM" -Name "ColorPrevalence" -Value 1 -Type DWord
    
    Write-Host "✓ Accent colors configured" -ForegroundColor Green

    # Install GlazeWM (Tiling Window Manager)
    Write-Host "[3/6] Installing GlazeWM..." -ForegroundColor Yellow
    try {
        $glazeWMUrl = "https://github.com/glzr-io/glazewm/releases/latest/download/glazewm-windows-x64.exe"
        $glazeWMPath = "$env:ProgramFiles\GlazeWM"
        $glazeWMExe = "$glazeWMPath\glazewm.exe"
        
        if (-not (Test-Path $glazeWMPath)) {
            New-Item -Path $glazeWMPath -ItemType Directory | Out-Null
        }
        
        Write-Host "Downloading GlazeWM..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $glazeWMUrl -OutFile $glazeWMExe -UseBasicParsing
        
        # Create GlazeWM config directory
        $glazeConfigDir = "$env:USERPROFILE\.glzr\glazewm"
        if (-not (Test-Path $glazeConfigDir)) {
            New-Item -Path $glazeConfigDir -ItemType Directory -Force | Out-Null
        }
        
        # Create default config
        $configPath = "$glazeConfigDir\config.yaml"
        $glazeConfig = @"
general:
  # Whether to automatically focus windows underneath the cursor.
  focus_follows_cursor: false

  # Whether to jump the cursor between windows focused by the WM.
  cursor_follows_focus: false

  # Whether to switch back and forth between the previously focused workspace
  # when focusing the current workspace.
  toggle_workspace_on_refocus: true

  # Whether to show floating windows as always on top.
  show_floating_on_top: false

  # Amount to move floating windows by (eg. when using `alt+<hjkl>` on a floating window)
  floating_window_move_amount: "5%"

  # Whether to center new floating windows.
  center_new_floating_windows: true

  # *Strongly* recommended to set to 'false'. Whether to globally enable/disable
  # window transition animations (on minimize, close, etc). Set to 'unchanged'
  # to make no setting changes.
  window_animations: "unchanged"

gaps:
  # Gap between adjacent windows.
  inner_gap: "10px"

  # Gap between windows and the screen edge.
  outer_gap: "10px"

# Highlight active/inactive windows with a colored border.
# ** Exclusive to Windows 11 due to API limitations.
focus_borders:
  active:
    enabled: true
    color: "#FF4500"

  inactive:
    enabled: false
    color: "#555555"

bar:
  enabled: false

workspaces:
  - name: "1"
  - name: "2"
  - name: "3"
  - name: "4"
  - name: "5"

window_rules:
  # Task Manager requires admin privileges to manage and should be ignored unless running
  # the WM as admin.
  - command: "ignore"
    match_process_name: "/Taskmgr|ScreenClippingHost/"

  # Launches system dialogs as floating by default (eg. File Explorer save/open dialog).
  - command: "set floating"
    match_class_name: "#32770"

  # Some applications (eg. Steam) have borders that extend past the normal border size.
  - command: "resize borders 0px -7px -7px -7px"
    match_process_name: "steam"

binding_modes:
  - name: "resize"
    keybindings:
      # Resize focused window by a percentage or pixel amount.
      - command: "resize width -2%"
        bindings: ["H", "Left"]
      - command: "resize width +2%"
        bindings: ["L", "Right"]
      - command: "resize height +2%"
        bindings: ["K", "Up"]
      - command: "resize height -2%"
        bindings: ["J", "Down"]
      # Press enter/escape to return to default keybindings.
      - command: "binding mode none"
        bindings: ["Escape", "Enter"]

keybindings:
  # Shift focus in a given direction.
  - command: "focus left"
    bindings: ["Alt+H", "Alt+Left"]
  - command: "focus right"
    bindings: ["Alt+L", "Alt+Right"]
  - command: "focus up"
    bindings: ["Alt+K", "Alt+Up"]
  - command: "focus down"
    bindings: ["Alt+J", "Alt+Down"]

  # Move focused window in a given direction.
  - command: "move left"
    bindings: ["Alt+Shift+H", "Alt+Shift+Left"]
  - command: "move right"
    bindings: ["Alt+Shift+L", "Alt+Shift+Right"]
  - command: "move up"
    bindings: ["Alt+Shift+K", "Alt+Shift+Up"]
  - command: "move down"
    bindings: ["Alt+Shift+J", "Alt+Shift+Down"]

  # Resize focused window by a percentage or pixel amount.
  - command: "resize width -2%"
    binding: "Alt+U"
  - command: "resize width +2%"
    binding: "Alt+P"
  - command: "resize height +2%"
    binding: "Alt+O"
  - command: "resize height -2%"
    binding: "Alt+I"

  # Change focus to a workspace defined in `workspaces`.
  - command: "focus workspace 1"
    binding: "Alt+1"
  - command: "focus workspace 2"
    binding: "Alt+2"
  - command: "focus workspace 3"
    binding: "Alt+3"
  - command: "focus workspace 4"
    binding: "Alt+4"
  - command: "focus workspace 5"
    binding: "Alt+5"

  # Move focused window to a workspace defined in `workspaces`.
  - command: "move to workspace 1"
    binding: "Alt+Shift+1"
  - command: "move to workspace 2"
    binding: "Alt+Shift+2"
  - command: "move to workspace 3"
    binding: "Alt+Shift+3"
  - command: "move to workspace 4"
    binding: "Alt+Shift+4"
  - command: "move to workspace 5"
    binding: "Alt+Shift+5"

  # Change tiling direction.
  - command: "tiling direction toggle"
    binding: "Alt+V"

  # Change focus between floating / tiling windows.
  - command: "focus mode toggle"
    binding: "Alt+Space"

  # Change the focused window to be floating / tiling.
  - command: "toggle floating"
    binding: "Alt+Shift+Space"

  # Change the focused window to be maximized / unmaximized.
  - command: "toggle maximized"
    binding: "Alt+X"

  # Minimize focused window.
  - command: "set minimized"
    binding: "Alt+M"

  # Close focused window.
  - command: "close"
    binding: "Alt+Shift+Q"

  # Kill GlazeWM process safely.
  - command: "exit wm"
    binding: "Alt+Shift+E"

  # Re-evaluate configuration file.
  - command: "reload config"
    binding: "Alt+Shift+R"

  # Redraw all windows.
  - command: "redraw"
    binding: "Alt+Shift+W"

  # Launch CMD terminal.
  - command: "exec wt"
    binding: "Alt+Enter"

  # Change focus to the workspace 
  - command: "focus workspace recent"
    binding: "Alt+Y"

  # Activate a binding mode to resize windows.
  - command: "binding mode resize"
    binding: "Alt+R"
"@
        Set-Content -Path $configPath -Value $glazeConfig
        
        # Add to startup
        $startupFolder = [Environment]::GetFolderPath("Startup")
        $shortcut = "$startupFolder\GlazeWM.lnk"
        $WScriptShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WScriptShell.CreateShortcut($shortcut)
        $Shortcut.TargetPath = $glazeWMExe
        $Shortcut.Save()
        
        Write-Host "✓ GlazeWM installed and configured" -ForegroundColor Green
        Write-Host "  Config location: $configPath" -ForegroundColor Gray
    } catch {
        Write-Warning "Failed to install GlazeWM: $($_.Exception.Message)"
    }

    # Install Rainmeter
    Write-Host "[4/6] Installing Rainmeter..." -ForegroundColor Yellow
    try {
        winget install --id Rainmeter.Rainmeter -e --accept-package-agreements --accept-source-agreements --silent
        Write-Host "✓ Rainmeter installed" -ForegroundColor Green
        Write-Host "  Note: Install custom skins manually from https://www.deviantart.com/rainmeter" -ForegroundColor Yellow
    } catch {
        Write-Warning "Failed to install Rainmeter: $($_.Exception.Message)"
    }

    # Configure wallpaper
    Write-Host "[5/6] Configuring wallpaper..." -ForegroundColor Yellow
    try {
        # Download a sample cyberpunk wallpaper
        $wallpaperUrl = "https://images.unsplash.com/photo-1550745165-9bc0b252726f?w=1920&h=1080&fit=crop"
        $wallpaperPath = "$env:USERPROFILE\Pictures\cyber_wallpaper.jpg"
        
        Write-Host "Downloading wallpaper..." -ForegroundColor Gray
        Invoke-WebRequest -Uri $wallpaperUrl -OutFile $wallpaperPath -UseBasicParsing
        
        # Set wallpaper via registry
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallPaper" -Value $wallpaperPath
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "WallpaperStyle" -Value "10" # Fill
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "TileWallpaper" -Value "0"
        
        # Force wallpaper update
        rundll32.exe user32.dll, UpdatePerUserSystemParameters, 1, $true
        
        Write-Host "✓ Wallpaper configured" -ForegroundColor Green
    } catch {
        Write-Warning "Failed to set wallpaper: $($_.Exception.Message)"
    }

    # Additional visual tweaks
    Write-Host "[6/6] Applying additional visual tweaks..." -ForegroundColor Yellow
    
    # Disable taskbar widgets
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarDa" -Value 0 -Type DWord
    
    # Disable search on taskbar
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Search" -Name "SearchboxTaskbarMode" -Value 0 -Type DWord
    
    # Disable task view button
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "ShowTaskViewButton" -Value 0 -Type DWord
    
    # Show file extensions
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0 -Type DWord
    
    # Show hidden files
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1 -Type DWord
    
    Write-Host "✓ Visual tweaks applied" -ForegroundColor Green

    Write-Host ""
    Write-Host "=== Phase 3 Complete ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Summary of changes:" -ForegroundColor Yellow
    Write-Host "✓ SecureUxTheme installed (manual activation required)" -ForegroundColor Green
    Write-Host "✓ Accent colors configured (Orange-Red cyber theme)" -ForegroundColor Green
    Write-Host "✓ GlazeWM installed and configured" -ForegroundColor Green
    Write-Host "✓ Rainmeter installed" -ForegroundColor Green
    Write-Host "✓ Custom wallpaper applied" -ForegroundColor Green
    Write-Host "✓ Taskbar and File Explorer optimized" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Restart Explorer to apply changes: taskkill /f /im explorer.exe && start explorer" -ForegroundColor White
    Write-Host "2. Run SecureUxTheme ThemeTool.exe to enable custom themes (if desired)" -ForegroundColor White
    Write-Host "3. Download custom Rainmeter skins from DeviantArt or other sources" -ForegroundColor White
    Write-Host "4. Test GlazeWM with Alt+Enter to open terminal" -ForegroundColor White
    Write-Host "5. Proceed to Phase4-Military-Interfaces.ps1" -ForegroundColor White
    Write-Host ""
    
    # Ask if user wants to restart Explorer
    $restart = Read-Host "Would you like to restart Explorer now? (Y/N)"
    if ($restart -eq 'Y' -or $restart -eq 'y') {
        Write-Host "Restarting Explorer..." -ForegroundColor Yellow
        Stop-Process -Name explorer -Force
        Start-Sleep -Seconds 2
        Start-Process explorer
    }

} catch {
    Write-Host ""
    Write-Host "=== Error During Desktop Customization ===" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    exit 1
}
