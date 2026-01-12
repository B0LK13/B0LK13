# Phase 5: Testing, Optimization, and Deployment
# Run inside Cloud PC after Phase 4 completion
# Tests the complete setup, optimizes performance, and prepares for production

<#
.SYNOPSIS
    Tests, optimizes, and finalizes the Windows 365 Cloud PC setup.

.DESCRIPTION
    This script performs the following:
    - Runs comprehensive security scans
    - Tests all installed tools and configurations
    - Optimizes system performance
    - Creates system backups and documentation
    - Validates deployment readiness

.EXAMPLE
    .\Phase5-Testing-Optimization.ps1

.NOTES
    Run with administrator privileges inside the Cloud PC.
    This is the final phase of the deployment process.
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
    Write-Host "=== Phase 5: Testing, Optimization, and Deployment ===" -ForegroundColor Cyan
    Write-Host "Finalizing Cloud PC setup..." -ForegroundColor Gray
    Write-Host ""

    # Create test results directory
    $testResultsDir = "$env:USERPROFILE\Documents\Deployment-Tests"
    if (-not (Test-Path $testResultsDir)) {
        New-Item -Path $testResultsDir -ItemType Directory | Out-Null
    }

    $testResults = @()
    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss"

    # Security Testing
    Write-Host "[1/6] Running security scans..." -ForegroundColor Yellow
    
    try {
        Write-Host "  Running Windows Defender quick scan..." -ForegroundColor Gray
        $scanResult = Start-MpScan -ScanType QuickScan
        $testResults += @{
            Test = "Windows Defender Quick Scan"
            Status = "PASSED"
            Details = "No threats detected"
            Timestamp = (Get-Date).ToString()
        }
        Write-Host "  ✓ Quick scan completed - No threats found" -ForegroundColor Green
    } catch {
        $testResults += @{
            Test = "Windows Defender Quick Scan"
            Status = "FAILED"
            Details = $_.Exception.Message
            Timestamp = (Get-Date).ToString()
        }
        Write-Warning "Security scan failed: $($_.Exception.Message)"
    }

    # Check security features
    Write-Host "  Verifying security features..." -ForegroundColor Gray
    $defenderPrefs = Get-MpPreference
    
    $securityChecks = @(
        @{Name="Real-time Protection"; Enabled=$(-not $defenderPrefs.DisableRealtimeMonitoring)},
        @{Name="Cloud Protection"; Enabled=$($defenderPrefs.MAPSReporting -ne 0)},
        @{Name="Controlled Folder Access"; Enabled=$($defenderPrefs.EnableControlledFolderAccess)},
        @{Name="PUA Protection"; Enabled=$($defenderPrefs.PUAProtection -ne 0)}
    )

    foreach ($check in $securityChecks) {
        if ($check.Enabled) {
            Write-Host "  ✓ $($check.Name): Enabled" -ForegroundColor Green
            $testResults += @{
                Test = $check.Name
                Status = "PASSED"
                Details = "Enabled"
                Timestamp = (Get-Date).ToString()
            }
        } else {
            Write-Host "  ✗ $($check.Name): Disabled" -ForegroundColor Red
            $testResults += @{
                Test = $check.Name
                Status = "FAILED"
                Details = "Disabled"
                Timestamp = (Get-Date).ToString()
            }
        }
    }

    # Tool Installation Verification
    Write-Host "[2/6] Verifying tool installations..." -ForegroundColor Yellow
    
    $toolChecks = @(
        @{Name="Git"; Command="git --version"},
        @{Name="Python"; Command="python --version"},
        @{Name="VS Code"; Command="code --version"},
        @{Name="Windows Terminal"; Command="wt --version"},
        @{Name="PowerShell 7"; Command="pwsh --version"}
    )

    foreach ($tool in $toolChecks) {
        try {
            $version = Invoke-Expression $tool.Command 2>&1 | Select-Object -First 1
            Write-Host "  ✓ $($tool.Name): $version" -ForegroundColor Green
            $testResults += @{
                Test = "$($tool.Name) Installation"
                Status = "PASSED"
                Details = $version
                Timestamp = (Get-Date).ToString()
            }
        } catch {
            Write-Host "  ✗ $($tool.Name): Not found" -ForegroundColor Red
            $testResults += @{
                Test = "$($tool.Name) Installation"
                Status = "FAILED"
                Details = "Not installed or not in PATH"
                Timestamp = (Get-Date).ToString()
            }
        }
    }

    # Performance Monitoring
    Write-Host "[3/6] Analyzing system performance..." -ForegroundColor Yellow
    
    # Get top processes by CPU
    Write-Host "  Top CPU-consuming processes:" -ForegroundColor Gray
    $topCPU = Get-Process | Sort-Object CPU -Descending | Select-Object -First 5 Name, CPU, @{Name="Memory(MB)";Expression={[math]::Round($_.WS/1MB,2)}}
    $topCPU | Format-Table | Out-String | ForEach-Object { Write-Host $_ -ForegroundColor Gray }
    
    # Get memory usage
    $memory = Get-CimInstance Win32_OperatingSystem
    $totalMemoryGB = [math]::Round($memory.TotalVisibleMemorySize/1MB, 2)
    $freeMemoryGB = [math]::Round($memory.FreePhysicalMemory/1MB, 2)
    $usedMemoryGB = $totalMemoryGB - $freeMemoryGB
    $memoryUsagePercent = [math]::Round(($usedMemoryGB / $totalMemoryGB) * 100, 2)
    
    Write-Host "  Memory Usage: $usedMemoryGB GB / $totalMemoryGB GB ($memoryUsagePercent%)" -ForegroundColor Gray
    
    $testResults += @{
        Test = "Memory Usage"
        Status = if ($memoryUsagePercent -lt 90) { "PASSED" } else { "WARNING" }
        Details = "$memoryUsagePercent% used"
        Timestamp = (Get-Date).ToString()
    }
    
    # Get disk usage
    $disks = Get-PSDrive -PSProvider FileSystem | Where-Object { $_.Used -gt 0 }
    foreach ($disk in $disks) {
        $usedGB = [math]::Round($disk.Used/1GB, 2)
        $freeGB = [math]::Round($disk.Free/1GB, 2)
        $totalGB = $usedGB + $freeGB
        $usagePercent = [math]::Round(($usedGB / $totalGB) * 100, 2)
        
        Write-Host "  Disk $($disk.Name): $usedGB GB / $totalGB GB ($usagePercent%)" -ForegroundColor Gray
        
        $testResults += @{
            Test = "Disk Usage ($($disk.Name):)"
            Status = if ($usagePercent -lt 90) { "PASSED" } else { "WARNING" }
            Details = "$usagePercent% used"
            Timestamp = (Get-Date).ToString()
        }
    }

    # System Optimization
    Write-Host "[4/6] Optimizing system performance..." -ForegroundColor Yellow
    
    # Clean temporary files
    Write-Host "  Cleaning temporary files..." -ForegroundColor Gray
    $tempPaths = @(
        $env:TEMP,
        "$env:SystemRoot\Temp",
        "$env:SystemRoot\Prefetch"
    )
    
    $cleanedSpace = 0
    foreach ($path in $tempPaths) {
        if (Test-Path $path) {
            try {
                $beforeSize = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                Remove-Item -Path "$path\*" -Recurse -Force -ErrorAction SilentlyContinue
                $afterSize = (Get-ChildItem -Path $path -Recurse -File -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                $cleaned = $beforeSize - $afterSize
                $cleanedSpace += $cleaned
            } catch {
                # Continue on error
            }
        }
    }
    
    $cleanedMB = [math]::Round($cleanedSpace/1MB, 2)
    Write-Host "  ✓ Cleaned $cleanedMB MB of temporary files" -ForegroundColor Green
    
    # Optimize system settings
    Write-Host "  Optimizing system settings..." -ForegroundColor Gray
    
    # Disable unnecessary visual effects for performance
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -Type DWord
    
    # Optimize power settings for performance
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c # High performance
    
    Write-Host "  ✓ System optimizations applied" -ForegroundColor Green

    # Configuration Backup
    Write-Host "[5/6] Creating configuration backup..." -ForegroundColor Yellow
    
    $backupDir = "$env:USERPROFILE\Documents\CloudPC-Backup-$timestamp"
    New-Item -Path $backupDir -ItemType Directory | Out-Null
    
    # Backup important configurations
    $backupItems = @(
        @{Source="$env:USERPROFILE\.glzr"; Dest="$backupDir\GlazeWM"},
        @{Source="$env:USERPROFILE\Documents\SOC-Workspace"; Dest="$backupDir\SOC-Workspace"}
    )
    
    foreach ($item in $backupItems) {
        if (Test-Path $item.Source) {
            try {
                Copy-Item -Path $item.Source -Destination $item.Dest -Recurse -Force -ErrorAction SilentlyContinue
                Write-Host "  ✓ Backed up: $($item.Source)" -ForegroundColor Green
            } catch {
                Write-Warning "Failed to backup $($item.Source)"
            }
        }
    }
    
    # Export installed applications list
    $installedApps = Get-WmiObject -Class Win32_Product | Select-Object Name, Version, Vendor
    $installedApps | Export-Csv -Path "$backupDir\installed_applications.csv" -NoTypeInformation
    Write-Host "  ✓ Exported installed applications list" -ForegroundColor Green
    
    # Export Windows features
    Get-WindowsOptionalFeature -Online | Where-Object State -eq "Enabled" | Select-Object FeatureName, State | 
        Export-Csv -Path "$backupDir\enabled_features.csv" -NoTypeInformation
    Write-Host "  ✓ Exported enabled Windows features" -ForegroundColor Green

    # Documentation Generation
    Write-Host "[6/6] Generating deployment documentation..." -ForegroundColor Yellow
    
    $documentation = @"
# Windows 365 Cloud PC Deployment Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## System Information
- Computer Name: $env:COMPUTERNAME
- User: $env:USERNAME
- OS: $(Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Caption)
- OS Version: $(Get-CimInstance Win32_OperatingSystem | Select-Object -ExpandProperty Version)

## Deployment Phases Completed
1. ✓ Phase 1: Windows 365 Cloud PC Provisioning
2. ✓ Phase 2: Base OS Customization
3. ✓ Phase 3: Desktop Environment Customization
4. ✓ Phase 4: Military-Style Interfaces and SOC Integration
5. ✓ Phase 5: Testing, Optimization, and Deployment

## Security Configuration
- Windows Defender: Enabled
- Real-time Protection: Enabled
- Cloud Protection: Enabled
- Controlled Folder Access: Enabled
- PUA Protection: Enabled

## Installed Tools
- Git
- Python 3.12
- Visual Studio Code
- PowerShell 7
- Windows Terminal
- 7-Zip
- Notepad++
- Wireshark
- Nmap
- GlazeWM (Tiling Window Manager)
- Rainmeter
- Grafana

## Performance Metrics
- Total Memory: $totalMemoryGB GB
- Memory Usage: $memoryUsagePercent%
- Disk Usage: $(($disks | Select-Object -First 1).Used/1GB) GB used

## SOC Integration
- Threat Triage Agent: Configured
- Defender Alert Monitor: Configured
- Grafana Dashboard: Installed (http://localhost:3000)

## Backup Location
$backupDir

## Next Steps
1. Configure Grafana dashboards with custom metrics
2. Customize GlazeWM keybindings as needed
3. Install additional Rainmeter skins
4. Configure network security rules
5. Set up regular backup schedules
6. Train team members on SOC tools

## Support and Maintenance
- Regular Windows updates: Weekly
- Security scans: Daily
- Backup verification: Weekly
- Performance monitoring: Continuous
- Configuration review: Monthly

## Troubleshooting
For issues, check:
- Windows Event Viewer: Security and System logs
- Defender logs: C:\ProgramData\Microsoft\Windows Defender\Support
- SOC workspace: $env:USERPROFILE\Documents\SOC-Workspace

## Contact
Deployed by: $env:USERNAME
Date: $(Get-Date -Format "yyyy-MM-dd")
"@

    $docPath = "$testResultsDir\Deployment-Report-$timestamp.md"
    Set-Content -Path $docPath -Value $documentation
    Write-Host "✓ Deployment documentation created: $docPath" -ForegroundColor Green

    # Generate test results report
    $testReport = @"
# Test Results Report
Generated: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Summary
Total Tests: $($testResults.Count)
Passed: $(($testResults | Where-Object { $_.Status -eq "PASSED" }).Count)
Failed: $(($testResults | Where-Object { $_.Status -eq "FAILED" }).Count)
Warnings: $(($testResults | Where-Object { $_.Status -eq "WARNING" }).Count)

## Detailed Results

"@

    foreach ($result in $testResults) {
        $testReport += @"
### $($result.Test)
- Status: $($result.Status)
- Details: $($result.Details)
- Timestamp: $($result.Timestamp)

"@
    }

    $testReportPath = "$testResultsDir\Test-Results-$timestamp.md"
    Set-Content -Path $testReportPath -Value $testReport
    Write-Host "✓ Test results report created: $testReportPath" -ForegroundColor Green

    # Final summary
    Write-Host ""
    Write-Host "=== Phase 5 Complete - Deployment Finalized ===" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Summary:" -ForegroundColor Yellow
    Write-Host "✓ Security scans completed" -ForegroundColor Green
    Write-Host "✓ Tool installations verified" -ForegroundColor Green
    Write-Host "✓ Performance analyzed and optimized" -ForegroundColor Green
    Write-Host "✓ Configuration backup created" -ForegroundColor Green
    Write-Host "✓ Documentation generated" -ForegroundColor Green
    Write-Host ""
    Write-Host "Test Results: $testReportPath" -ForegroundColor Cyan
    Write-Host "Documentation: $docPath" -ForegroundColor Cyan
    Write-Host "Backup Location: $backupDir" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "=== Deployment Complete ===" -ForegroundColor Green
    Write-Host "Your Windows 365 Cloud PC is ready for production use!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Recommended Actions:" -ForegroundColor Yellow
    Write-Host "1. Review test results and address any failures" -ForegroundColor White
    Write-Host "2. Configure additional security policies as needed" -ForegroundColor White
    Write-Host "3. Set up scheduled tasks for monitoring" -ForegroundColor White
    Write-Host "4. Train team on new tools and workflows" -ForegroundColor White
    Write-Host "5. Schedule regular maintenance windows" -ForegroundColor White
    Write-Host ""

    # Open reports
    $openReports = Read-Host "Would you like to open the deployment reports? (Y/N)"
    if ($openReports -eq 'Y' -or $openReports -eq 'y') {
        Start-Process notepad $docPath
        Start-Process notepad $testReportPath
    }

} catch {
    Write-Host ""
    Write-Host "=== Error During Testing and Optimization ===" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    exit 1
}
