<#
.SYNOPSIS
    Downloads and installs Microsoft Sysinternals BGInfo.

.DESCRIPTION
    Downloads the official BGInfo package from Microsoft Sysinternals,
    extracts the required files into C:\BGInfo and validates the
    installation.

.NOTES
    Project: BGInfo AutoDeploy
    Component: Install-BGInfo
    Version: 0.1
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

# ============================================================
# Configuration
# ============================================================

$BGInfoFolder = "C:\BGInfo"

$BGInfoURL = "https://download.sysinternals.com/files/BGInfo.zip"

$BGInfoZIP = Join-Path $env:TEMP "BGInfo.zip"

$BGInfoExecutable = Join-Path $BGInfoFolder "Bginfo64.exe"


# ============================================================
# Header
# ============================================================

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "          BGInfo Installation" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""


# ============================================================
# Create BGInfo folder
# ============================================================

if (-not (Test-Path -LiteralPath $BGInfoFolder)) {

    Write-Host "[INFO] Creating $BGInfoFolder..." -ForegroundColor Yellow

    New-Item `
        -Path $BGInfoFolder `
        -ItemType Directory `
        -Force | Out-Null

    Write-Host "[OK] BGInfo folder created" -ForegroundColor Green

}
else {

    Write-Host "[OK] BGInfo folder exists" -ForegroundColor Green
}


# ============================================================
# Enable TLS 1.2
# Useful for older supported Windows environments
# ============================================================

try {

    [Net.ServicePointManager]::SecurityProtocol = `
        [Net.ServicePointManager]::SecurityProtocol -bor `
        [Net.SecurityProtocolType]::Tls12

    Write-Host "[OK] TLS configuration ready" -ForegroundColor Green

}
catch {

    Write-Host "[WARNING] Unable to explicitly configure TLS 1.2" -ForegroundColor Yellow
}


# ============================================================
# Remove previous temporary ZIP
# ============================================================

if (Test-Path -LiteralPath $BGInfoZIP) {

    Remove-Item `
        -LiteralPath $BGInfoZIP `
        -Force

    Write-Host "[OK] Previous temporary ZIP removed" -ForegroundColor Green
}


# ============================================================
# Download BGInfo
# ============================================================

Write-Host ""
Write-Host "[INFO] Downloading BGInfo from Microsoft Sysinternals..." -ForegroundColor Cyan

try {

    Invoke-WebRequest `
        -Uri $BGInfoURL `
        -OutFile $BGInfoZIP `
        -UseBasicParsing

}
catch {

    Write-Host "[ERROR] Failed to download BGInfo." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    exit 1
}


# ============================================================
# Validate ZIP
# ============================================================

if (-not (Test-Path -LiteralPath $BGInfoZIP)) {

    Write-Host "[ERROR] BGInfo ZIP was not downloaded." -ForegroundColor Red
    exit 1
}


$ZIPInfo = Get-Item -LiteralPath $BGInfoZIP


if ($ZIPInfo.Length -le 0) {

    Write-Host "[ERROR] Downloaded BGInfo ZIP is empty." -ForegroundColor Red

    Remove-Item `
        -LiteralPath $BGInfoZIP `
        -Force `
        -ErrorAction SilentlyContinue

    exit 1
}


Write-Host "[OK] BGInfo package downloaded" -ForegroundColor Green
Write-Host "     File : $BGInfoZIP"
Write-Host "     Size : $([math]::Round($ZIPInfo.Length / 1MB, 2)) MB"


# ============================================================
# Extract BGInfo
# ============================================================

Write-Host ""
Write-Host "[INFO] Extracting BGInfo..." -ForegroundColor Cyan

try {

    Expand-Archive `
        -LiteralPath $BGInfoZIP `
        -DestinationPath $BGInfoFolder `
        -Force

}
catch {

    Write-Host "[ERROR] Failed to extract BGInfo." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    exit 1
}


# ============================================================
# Validate executable
# ============================================================

if (-not (Test-Path -LiteralPath $BGInfoExecutable)) {

    Write-Host "[ERROR] Bginfo64.exe was not found after extraction." -ForegroundColor Red
    exit 1
}


Write-Host "[OK] Bginfo64.exe installed" -ForegroundColor Green


# ============================================================
# Show installed executable information
# ============================================================

$BGInfoFile = Get-Item -LiteralPath $BGInfoExecutable

try {

    $BGInfoVersion = $BGInfoFile.VersionInfo.FileVersion

    Write-Host "[OK] BGInfo version : $BGInfoVersion" -ForegroundColor Green

}
catch {

    Write-Host "[WARNING] Unable to determine BGInfo version" -ForegroundColor Yellow
}


# ============================================================
# Remove downloaded ZIP
# ============================================================

Remove-Item `
    -LiteralPath $BGInfoZIP `
    -Force `
    -ErrorAction SilentlyContinue


if (-not (Test-Path -LiteralPath $BGInfoZIP)) {

    Write-Host "[OK] Temporary ZIP removed" -ForegroundColor Green

}
else {

    Write-Host "[WARNING] Temporary ZIP could not be removed" -ForegroundColor Yellow
}


# ============================================================
# Final validation
# ============================================================

Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host "BGInfo installation completed." -ForegroundColor Green
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

Write-Host "Installation:"
Write-Host "  $BGInfoFolder"
Write-Host ""

Write-Host "Executable:"
Write-Host "  $BGInfoExecutable"
Write-Host ""

Write-Host "Version:"
Write-Host "  $BGInfoVersion"
Write-Host ""
