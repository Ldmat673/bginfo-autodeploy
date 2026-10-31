<#
.SYNOPSIS
    Configures and validates permissions for the BGInfo installation folder.

.DESCRIPTION
    Applies secure permissions to C:\BGInfo so BGInfo can be used
    by all local Windows user sessions.

    Permissions:
        SYSTEM         - Full Control
        Administrators - Full Control
        Users           - Read and Execute

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

# ------------------------------------------------------------
# Validate folder
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $BGInfoFolder)) {

    Write-Host "[INFO] BGInfo folder does not exist. Creating..." -ForegroundColor Yellow

    New-Item `
        -Path $BGInfoFolder `
        -ItemType Directory `
        -Force | Out-Null
}

Write-Host "[OK] BGInfo folder exists: $BGInfoFolder" -ForegroundColor Green

# ------------------------------------------------------------
# Resolve well-known SIDs
# This avoids problems with localized Windows installations
# ------------------------------------------------------------

$SystemSID = New-Object System.Security.Principal.SecurityIdentifier(
    "S-1-5-18"
)

$AdministratorsSID = New-Object System.Security.Principal.SecurityIdentifier(
    "S-1-5-32-544"
)

$UsersSID = New-Object System.Security.Principal.SecurityIdentifier(
    "S-1-5-32-545"
)

$SystemAccount = $SystemSID.Translate(
    [System.Security.Principal.NTAccount]
)

$AdministratorsAccount = $AdministratorsSID.Translate(
    [System.Security.Principal.NTAccount]
)

$UsersAccount = $UsersSID.Translate(
    [System.Security.Principal.NTAccount]
)

Write-Host "[OK] SYSTEM resolved         : $SystemAccount" -ForegroundColor Green
Write-Host "[OK] Administrators resolved : $AdministratorsAccount" -ForegroundColor Green
Write-Host "[OK] Users resolved          : $UsersAccount" -ForegroundColor Green

# ------------------------------------------------------------
# Get current ACL
# ------------------------------------------------------------

$ACL = Get-Acl -LiteralPath $BGInfoFolder

# Disable inheritance and remove inherited permissions.
# BGInfo files are managed only by Administrators and SYSTEM.
$ACL.SetAccessRuleProtection($true, $false)

# ------------------------------------------------------------
# Define required rules
# ------------------------------------------------------------

$InheritanceFlags = `
    [System.Security.AccessControl.InheritanceFlags]"ContainerInherit, ObjectInherit"

$PropagationFlags = `
    [System.Security.AccessControl.PropagationFlags]::None

$Allow = `
    [System.Security.AccessControl.AccessControlType]::Allow

$SystemRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $SystemAccount,
    [System.Security.AccessControl.FileSystemRights]::FullControl,
    $InheritanceFlags,
    $PropagationFlags,
    $Allow
)

$AdministratorsRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $AdministratorsAccount,
    [System.Security.AccessControl.FileSystemRights]::FullControl,
    $InheritanceFlags,
    $PropagationFlags,
    $Allow
)

$UsersRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $UsersAccount,
    [System.Security.AccessControl.FileSystemRights]::ReadAndExecute,
    $InheritanceFlags,
    $PropagationFlags,
    $Allow
)

# ------------------------------------------------------------
# Apply ACL
# ------------------------------------------------------------

try {

    $ACL.SetAccessRule($SystemRule)
    $ACL.SetAccessRule($AdministratorsRule)
    $ACL.SetAccessRule($UsersRule)

    Set-Acl `
        -LiteralPath $BGInfoFolder `
        -AclObject $ACL

    Write-Host ""
    Write-Host "[OK] BGInfo ACL configured successfully" -ForegroundColor Green

}
catch {

    Write-Host ""
    Write-Host "[ERROR] Unable to configure BGInfo ACL." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    exit 1
}

# ------------------------------------------------------------
# Validate ACL
# ------------------------------------------------------------

Write-Host ""
Write-Host "Validating permissions..." -ForegroundColor Cyan
Write-Host ""

$ValidatedACL = Get-Acl -LiteralPath $BGInfoFolder

$RequiredAccounts = @(
    $SystemAccount.Value,
    $AdministratorsAccount.Value,
    $UsersAccount.Value
)

foreach ($Account in $RequiredAccounts) {

    $Rules = $ValidatedACL.Access |
        Where-Object {
            $_.IdentityReference.Value -eq $Account
        }

    if ($Rules) {

        foreach ($Rule in $Rules) {

            Write-Host "[OK] $($Rule.IdentityReference)" -ForegroundColor Green
            Write-Host "     Rights : $($Rule.FileSystemRights)"
            Write-Host "     Type   : $($Rule.AccessControlType)"
        }

    }
    else {

        Write-Host "[WARNING] ACL entry not found: $Account" -ForegroundColor Yellow
    }
}

# ------------------------------------------------------------
# Final result
# ------------------------------------------------------------

Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host "BGInfo ACL configuration completed." -ForegroundColor Green
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

Write-Host "Folder:"
Write-Host "  $BGInfoFolder"
Write-Host ""

Write-Host "Required permissions:"
Write-Host "  SYSTEM         : Full Control"
Write-Host "  Administrators : Full Control"
Write-Host "  Users          : Read and Execute"
Write-Host ""
