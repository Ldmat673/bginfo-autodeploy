<#
.SYNOPSIS
    BGInfo AutoDeploy

.DESCRIPTION
    Automated BGInfo deployment for Windows Server and Windows workstations.

    Features:
    - Windows Server / Workstation detection
    - Hardware manufacturer and model detection
    - Automatic wallpaper selection
    - BGInfo installation in C:\BGInfo
    - Secure ACL configuration for multiple Windows users
    - Automatic BGInfo execution at user logon

.NOTES
    Project: BGInfo AutoDeploy
    Version: 0.1
    Repository: bginfo-autodeploy
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

# ============================================================
# Configuration
# ============================================================

$BGInfoFolder = "C:\BGInfo"

# ============================================================
# Header
# ============================================================

Clear-Host

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "           BGInfo AutoDeploy" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# ============================================================
# Validate Administrator
# ============================================================

$CurrentPrincipal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)

if (-not $CurrentPrincipal.IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator
)) {
    Write-Host "[ERROR] Run PowerShell as Administrator." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Administrator privileges" -ForegroundColor Green

# ============================================================
# Detect operating system
# ============================================================

$OS = Get-CimInstance Win32_OperatingSystem

if ($OS.ProductType -eq 1) {
    $OSType = "Workstation"
}
else {
    $OSType = "Server"
}

Write-Host "[OK] Operating System : $($OS.Caption)" -ForegroundColor Green
Write-Host "[OK] OS Type          : $OSType" -ForegroundColor Green

# ============================================================
# Detect computer
# ============================================================

$ComputerSystem = Get-CimInstance Win32_ComputerSystem
$BIOS = Get-CimInstance Win32_BIOS

$Manufacturer = $ComputerSystem.Manufacturer
$Model = $ComputerSystem.Model
$SerialNumber = $BIOS.SerialNumber

Write-Host "[OK] Computer Name    : $env:COMPUTERNAME" -ForegroundColor Green
Write-Host "[OK] Manufacturer     : $Manufacturer" -ForegroundColor Green
Write-Host "[OK] Model            : $Model" -ForegroundColor Green
Write-Host "[OK] Serial Number    : $SerialNumber" -ForegroundColor Green

# ============================================================
# Detect manufacturer profile
# ============================================================

switch -Regex ($Manufacturer) {

    "Dell" {

        if ($Model -match "Alienware") {
            $Brand = "Dell-Alienware"
        }
        else {
            $Brand = "Dell"
        }
    }

    "HP|Hewlett-Packard" {

        if ($Model -match "OMEN") {
            $Brand = "HP-OMEN"
        }
        else {
            $Brand = "HP"
        }
    }

    "Lenovo" {

        if ($Model -match "Legion") {
            $Brand = "Lenovo-Legion"
        }
        else {
            $Brand = "Lenovo"
        }
    }

    "ASUSTeK|ASUS" {

        if ($Model -match "ROG") {
            $Brand = "ASUS-ROG"
        }
        else {
            $Brand = "ASUS"
        }
    }

    "Micro-Star|MSI" {
        $Brand = "MSI"
    }

    "Gigabyte" {
        $Brand = "Gigabyte"
    }

    "Acer" {
        $Brand = "Acer"
    }

    "Microsoft" {
        $Brand = "Microsoft-Surface"
    }

    "Samsung" {
        $Brand = "Samsung"
    }

    default {
        $Brand = "Generic"
    }
}

Write-Host "[OK] BGInfo Profile   : $Brand" -ForegroundColor Green

# ============================================================
# Create BGInfo directory
# ============================================================

if (-not (Test-Path $BGInfoFolder)) {

    New-Item `
        -Path $BGInfoFolder `
        -ItemType Directory `
        -Force | Out-Null

    Write-Host "[OK] Created $BGInfoFolder" -ForegroundColor Green
}
else {

    Write-Host "[OK] $BGInfoFolder already exists" -ForegroundColor Green
}

# ============================================================
# Finished
# ============================================================

Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host "Detection completed successfully." -ForegroundColor Green
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

Write-Host "OS Type      : $OSType"
Write-Host "Manufacturer : $Manufacturer"
Write-Host "Model        : $Model"
Write-Host "Profile      : $Brand"
Write-Host "BGInfo Path  : $BGInfoFolder"
Write-Host ""
