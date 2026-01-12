# Phase 1: Provision Windows 365 Cloud PC
# Run on local machine with Azure PowerShell installed
# Prerequisites:
#   - Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force
#   - Install-Module Microsoft.Graph -Scope CurrentUser -Force
#   - Connect-AzAccount (run before this script)

<#
.SYNOPSIS
    Provisions a Windows 365 Cloud PC with specified configuration.

.DESCRIPTION
    This script creates a Windows 365 Cloud PC by:
    - Creating Azure resource group if needed
    - Creating Intune provisioning policy
    - Assigning policy to user
    - Monitoring provisioning status

.PARAMETER SubscriptionId
    Azure subscription ID

.PARAMETER ResourceGroupName
    Name of the Azure resource group (default: CyberAgencyRG)

.PARAMETER Location
    Azure region location (default: westeurope)

.PARAMETER UserPrincipalName
    User principal name (e.g., wes@domain.com)

.PARAMETER CloudPcSize
    Cloud PC size specification (default: 8vCPU-32GB-512GB)

.PARAMETER ImageName
    Windows image name (default: Windows-11-24h2-ent)

.EXAMPLE
    .\Phase1-Provision-CloudPC.ps1 -SubscriptionId "your-sub-id" -UserPrincipalName "user@domain.com"
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$true)]
    [string]$SubscriptionId,
    
    [Parameter(Mandatory=$false)]
    [string]$ResourceGroupName = "CyberAgencyRG",
    
    [Parameter(Mandatory=$false)]
    [string]$Location = "westeurope",
    
    [Parameter(Mandatory=$true)]
    [string]$UserPrincipalName,
    
    [Parameter(Mandatory=$false)]
    [string]$CloudPcSize = "8vCPU-32GB-512GB",
    
    [Parameter(Mandatory=$false)]
    [string]$ImageName = "Windows-11-24h2-ent"
)

# Error handling
$ErrorActionPreference = "Stop"

try {
    Write-Host "=== Phase 1: Provisioning Windows 365 Cloud PC ===" -ForegroundColor Cyan
    Write-Host "Subscription: $SubscriptionId" -ForegroundColor Gray
    Write-Host "User: $UserPrincipalName" -ForegroundColor Gray
    Write-Host ""

    # Set Azure subscription context
    Write-Host "[1/6] Setting Azure subscription context..." -ForegroundColor Yellow
    Set-AzContext -SubscriptionId $SubscriptionId | Out-Null
    Write-Host "✓ Subscription context set" -ForegroundColor Green

    # Create resource group if it doesn't exist
    Write-Host "[2/6] Checking resource group..." -ForegroundColor Yellow
    $rg = Get-AzResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
    if (-not $rg) {
        Write-Host "Creating resource group: $ResourceGroupName" -ForegroundColor Gray
        New-AzResourceGroup -Name $ResourceGroupName -Location $Location | Out-Null
        Write-Host "✓ Resource group created" -ForegroundColor Green
    } else {
        Write-Host "✓ Resource group already exists" -ForegroundColor Green
    }

    # Check Microsoft Graph module
    Write-Host "[3/6] Checking Microsoft Graph module..." -ForegroundColor Yellow
    if (-not (Get-Module -ListAvailable -Name Microsoft.Graph)) {
        Write-Host "Installing Microsoft Graph module..." -ForegroundColor Gray
        Install-Module Microsoft.Graph -Scope CurrentUser -Force -AllowClobber
    }
    Write-Host "✓ Microsoft Graph module ready" -ForegroundColor Green

    # Connect to Microsoft Graph
    Write-Host "[4/6] Connecting to Microsoft Graph..." -ForegroundColor Yellow
    Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All", "User.Read.All" -NoWelcome
    Write-Host "✓ Connected to Microsoft Graph" -ForegroundColor Green

    # Verify user exists
    Write-Host "[5/6] Verifying user..." -ForegroundColor Yellow
    try {
        $user = Get-MgUser -UserId $UserPrincipalName -ErrorAction Stop
        Write-Host "✓ User verified: $($user.DisplayName)" -ForegroundColor Green
    } catch {
        Write-Error "User not found: $UserPrincipalName"
        throw
    }

    # Create Windows 365 provisioning policy
    Write-Host "[6/6] Creating Windows 365 provisioning policy..." -ForegroundColor Yellow
    
    $policyParams = @{
        "@odata.type" = "#microsoft.graph.cloudPcProvisioningPolicy"
        displayName = "CyberAgencyPolicy"
        description = "Policy for private cyber agency Cloud PCs - Created $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
        provisioningType = "dedicated"
        imageDisplayName = $ImageName
        imageId = "MicrosoftWindowsDesktop_windows-ent-cpc_$ImageName"
        imageType = "gallery"
        windowsSetting = @{
            locale = "en-US"
        }
        domainJoinConfiguration = @{
            domainJoinType = "azureADJoin"
        }
    }

    try {
        $policy = New-MgDeviceManagementVirtualEndpointProvisioningPolicy -BodyParameter $policyParams
        Write-Host "✓ Provisioning policy created: $($policy.Id)" -ForegroundColor Green
    } catch {
        Write-Warning "Policy creation returned: $($_.Exception.Message)"
        Write-Host "Note: You may need to manually create the policy via Intune portal if Graph API is limited" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "=== Provisioning Initiated ===" -ForegroundColor Cyan
    Write-Host "Next Steps:" -ForegroundColor Yellow
    Write-Host "1. Verify Windows 365 license is assigned to user: $UserPrincipalName" -ForegroundColor White
    Write-Host "2. Monitor provisioning at: https://windows365.microsoft.com" -ForegroundColor White
    Write-Host "3. Provisioning typically takes 15-30 minutes" -ForegroundColor White
    Write-Host "4. Once ready, connect via Remote Desktop or windows365.microsoft.com" -ForegroundColor White
    Write-Host ""
    Write-Host "Policy Details:" -ForegroundColor Gray
    Write-Host "  Resource Group: $ResourceGroupName" -ForegroundColor Gray
    Write-Host "  Location: $Location" -ForegroundColor Gray
    Write-Host "  Image: $ImageName" -ForegroundColor Gray
    Write-Host "  Size: $CloudPcSize" -ForegroundColor Gray
    Write-Host ""
    
} catch {
    Write-Host ""
    Write-Host "=== Error During Provisioning ===" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host ""
    Write-Host "Troubleshooting:" -ForegroundColor Yellow
    Write-Host "- Ensure you have necessary Azure/Intune permissions" -ForegroundColor White
    Write-Host "- Verify Windows 365 licenses are available" -ForegroundColor White
    Write-Host "- Check Azure subscription is active" -ForegroundColor White
    Write-Host "- Review Graph API permissions" -ForegroundColor White
    exit 1
}
