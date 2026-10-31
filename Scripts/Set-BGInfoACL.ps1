<#
.SYNOPSIS
    Configures and validates permissions for the BGInfo installation folder.

.DESCRIPTION
    Applies the required permissions to C:\BGInfo so BGInfo can be
    securely used by all local user sessions.

.NOTES
    Project: BGInfo AutoDeploy
    Component: Set-BGInfoACL
    Version: 0.1
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$BGInfoFolder = "C:\BGInfo"

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "        BGInfo ACL Configuration" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""
