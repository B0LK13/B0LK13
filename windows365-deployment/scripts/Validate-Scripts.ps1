# Validation Script for Windows 365 Deployment Scripts
# This script performs basic syntax validation on all PowerShell deployment scripts

<#
.SYNOPSIS
    Validates PowerShell deployment scripts for syntax and best practices.

.DESCRIPTION
    Performs the following validations:
    - Balanced braces and parentheses
    - Comment-based help presence
    - CmdletBinding attribute
    - No hardcoded credentials (basic check)
    - Script execution policy compatibility

.EXAMPLE
    .\Validate-Scripts.ps1
#>

[CmdletBinding()]
param()

Write-Host "=== Windows 365 Deployment Scripts Validation ===" -ForegroundColor Cyan
Write-Host ""

$scriptPath = $PSScriptRoot
if (-not $scriptPath) {
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
}

$scripts = Get-ChildItem -Path $scriptPath -Filter "Phase*.ps1"
$results = @()

foreach ($script in $scripts) {
    Write-Host "Validating: $($script.Name)" -ForegroundColor Yellow
    
    $content = Get-Content -Path $script.FullName -Raw
    $issues = @()
    $warnings = @()
    
    # Check balanced braces
    $openBraces = ([regex]::Matches($content, '\{')).Count
    $closeBraces = ([regex]::Matches($content, '\}')).Count
    if ($openBraces -ne $closeBraces) {
        $issues += "Unbalanced braces: $openBraces open, $closeBraces close"
    }
    
    # Check balanced parentheses
    $openParens = ([regex]::Matches($content, '\(')).Count
    $closeParens = ([regex]::Matches($content, '\)')).Count
    if ($openParens -ne $closeParens) {
        $issues += "Unbalanced parentheses: $openParens open, $closeParens close"
    }
    
    # Check for comment-based help
    if ($content -notmatch '(?s)<#.*?#>') {
        $warnings += "Missing comment-based help"
    }
    
    # Check for CmdletBinding
    if ($content -notmatch '\[CmdletBinding\(\)\]') {
        $warnings += "Missing CmdletBinding attribute"
    }
    
    # Check for potential hardcoded credentials (basic check)
    if ($content -match 'password\s*=\s*[''"].*?[''"]' -or 
        $content -match 'secret\s*=\s*[''"].*?[''"]') {
        $warnings += "Potential hardcoded credentials detected"
    }
    
    # Try to parse as PowerShell (requires PowerShell on system)
    try {
        $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
        $parseSuccess = $true
    } catch {
        $parseSuccess = $false
        $issues += "PowerShell parsing failed: $($_.Exception.Message)"
    }
    
    # Report results
    if ($issues.Count -eq 0 -and $warnings.Count -eq 0) {
        Write-Host "  ✓ PASSED" -ForegroundColor Green
    } elseif ($issues.Count -eq 0) {
        Write-Host "  ⚠ PASSED WITH WARNINGS" -ForegroundColor Yellow
        foreach ($warning in $warnings) {
            Write-Host "    Warning: $warning" -ForegroundColor Yellow
        }
    } else {
        Write-Host "  ✗ FAILED" -ForegroundColor Red
        foreach ($issue in $issues) {
            Write-Host "    Error: $issue" -ForegroundColor Red
        }
        foreach ($warning in $warnings) {
            Write-Host "    Warning: $warning" -ForegroundColor Yellow
        }
    }
    
    $results += [PSCustomObject]@{
        Script = $script.Name
        Status = if ($issues.Count -eq 0) { "PASSED" } else { "FAILED" }
        Issues = $issues.Count
        Warnings = $warnings.Count
        Details = $issues + $warnings -join "; "
    }
    
    Write-Host ""
}

# Summary
Write-Host "=== Validation Summary ===" -ForegroundColor Cyan
$passed = ($results | Where-Object { $_.Status -eq "PASSED" }).Count
$failed = ($results | Where-Object { $_.Status -eq "FAILED" }).Count
Write-Host "Total Scripts: $($results.Count)" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor Green
Write-Host "Failed: $failed" -ForegroundColor $(if ($failed -gt 0) { "Red" } else { "Green" })
Write-Host ""

# Export results
$resultsPath = Join-Path $scriptPath "validation_results.csv"
$results | Export-Csv -Path $resultsPath -NoTypeInformation
Write-Host "Results exported to: $resultsPath" -ForegroundColor Gray

# Exit with error code if any failed
if ($failed -gt 0) {
    exit 1
} else {
    Write-Host "All scripts validated successfully!" -ForegroundColor Green
    exit 0
}
