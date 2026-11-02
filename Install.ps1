<#
.SYNOPSIS
    BGInfo AutoDeploy Bootstrap Installer

.DESCRIPTION
    Downloads and executes the latest BGInfo AutoDeploy deployment
    script from the GitHub repository.

.NOTES
    Project: BGInfo AutoDeploy
    Repository: Ldmat673/bginfo-autodeploy
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$DeployURL = "https://raw.githubusercontent.com/Ldmat673/bginfo-autodeploy/main/Deploy-BGInfo-v1.ps1"

$TempFolder = "C:\Temp"
$DeployScript = Join-Path $TempFolder "Deploy-BGInfo-v1.ps1"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "       BGInfo AutoDeploy Installer" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

# Create temporary folder

if (-not (Test-Path $TempFolder)) {

    New-Item `
        -Path $TempFolder `
        -ItemType Directory `
        -Force | Out-Null
}

Write-Host "[OK] Temporary folder ready" -ForegroundColor Green

# Remove old deployment copy

Remove-Item `
    -LiteralPath $DeployScript `
    -Force `
    -ErrorAction SilentlyContinue

# Enable TLS 1.2

[Net.ServicePointManager]::SecurityProtocol = `
    [Net.ServicePointManager]::SecurityProtocol -bor `
    [Net.SecurityProtocolType]::Tls12

# Download deployment script

Write-Host "[INFO] Downloading BGInfo AutoDeploy..." -ForegroundColor Cyan

try {

    Invoke-WebRequest `
        -Uri $DeployURL `
        -OutFile $DeployScript `
        -UseBasicParsing `
        -ErrorAction Stop

}
catch {

    Write-Host "[ERROR] Unable to download BGInfo AutoDeploy." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    exit 1
}

if (-not (Test-Path $DeployScript)) {

    Write-Host "[ERROR] Deployment script was not downloaded." -ForegroundColor Red
    exit 1
}

if ((Get-Item $DeployScript).Length -eq 0) {

    Write-Host "[ERROR] Downloaded deployment script is empty." -ForegroundColor Red
    exit 1
}

Write-Host "[OK] Deployment script downloaded" -ForegroundColor Green

# Execute deployment

Write-Host ""
Write-Host "[INFO] Starting BGInfo AutoDeploy..." -ForegroundColor Cyan
Write-Host ""

try {

    & powershell.exe `
        -NoProfile `
        -ExecutionPolicy Bypass `
        -File $DeployScript

    if ($LASTEXITCODE -ne 0) {

        Write-Host ""
        Write-Host "[ERROR] BGInfo AutoDeploy returned exit code $LASTEXITCODE" -ForegroundColor Red

        exit $LASTEXITCODE
    }

}
catch {

    Write-Host ""
    Write-Host "[ERROR] Unable to execute BGInfo AutoDeploy." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Green
Write-Host "     BGInfo AutoDeploy completed" -ForegroundColor Green
Write-Host "============================================" -ForegroundColor Green
Write-Host ""