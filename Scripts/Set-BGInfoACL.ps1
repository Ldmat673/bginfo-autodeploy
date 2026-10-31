<#
.SYNOPSIS
    Configures and validates permissions for the BGInfo installation folder.

.DESCRIPTION
    Creates a controlled ACL for C:\BGInfo.

    Required permissions:
        SYSTEM         - Full Control
        Administrators - Full Control
        Users           - Read and Execute

    Inheritance from C:\ is disabled.

.NOTES
    Project: BGInfo AutoDeploy
    Component: Set-BGInfoACL
    Version: 0.2
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
# Create folder if necessary
# ------------------------------------------------------------

if (-not (Test-Path -LiteralPath $BGInfoFolder)) {

    Write-Host "[INFO] Creating $BGInfoFolder..." -ForegroundColor Yellow

    New-Item `
        -Path $BGInfoFolder `
        -ItemType Directory `
        -Force | Out-Null
}

Write-Host "[OK] BGInfo folder exists: $BGInfoFolder" -ForegroundColor Green


# ------------------------------------------------------------
# Resolve Windows built-in accounts using SIDs
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
# Create clean ACL
# ------------------------------------------------------------

Write-Host ""
Write-Host "[INFO] Creating controlled ACL..." -ForegroundColor Cyan

$ACL = New-Object System.Security.AccessControl.DirectorySecurity

# Disable inheritance
$ACL.SetAccessRuleProtection(
    $true,
    $false
)

$InheritanceFlags = `
    [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor `
    [System.Security.AccessControl.InheritanceFlags]::ObjectInherit

$PropagationFlags = `
    [System.Security.AccessControl.PropagationFlags]::None

$Allow = `
    [System.Security.AccessControl.AccessControlType]::Allow


# ------------------------------------------------------------
# SYSTEM - Full Control
# ------------------------------------------------------------

$SystemRule = New-Object `
    System.Security.AccessControl.FileSystemAccessRule(
        $SystemAccount,
        [System.Security.AccessControl.FileSystemRights]::FullControl,
        $InheritanceFlags,
        $PropagationFlags,
        $Allow
    )

$ACL.AddAccessRule($SystemRule)


# ------------------------------------------------------------
# Administrators - Full Control
# ------------------------------------------------------------

$AdministratorsRule = New-Object `
    System.Security.AccessControl.FileSystemAccessRule(
        $AdministratorsAccount,
        [System.Security.AccessControl.FileSystemRights]::FullControl,
        $InheritanceFlags,
        $PropagationFlags,
        $Allow
    )

$ACL.AddAccessRule($AdministratorsRule)


# ------------------------------------------------------------
# Users - Read and Execute
# ------------------------------------------------------------

$UsersRule = New-Object `
    System.Security.AccessControl.FileSystemAccessRule(
        $UsersAccount,
        [System.Security.AccessControl.FileSystemRights]::ReadAndExecute,
        $InheritanceFlags,
        $PropagationFlags,
        $Allow
    )

$ACL.AddAccessRule($UsersRule)


# ------------------------------------------------------------
# Apply ACL
# ------------------------------------------------------------

try {

    Set-Acl `
        -LiteralPath $BGInfoFolder `
        -AclObject $ACL

    Write-Host "[OK] Controlled ACL applied successfully" -ForegroundColor Green

}
catch {

    Write-Host ""
    Write-Host "[ERROR] Failed to configure ACL." -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    exit 1
}


# ------------------------------------------------------------
# Validate
# ------------------------------------------------------------

Write-Host ""
Write-Host "Validating permissions..." -ForegroundColor Cyan
Write-Host ""

$ResultACL = Get-Acl -LiteralPath $BGInfoFolder

$ExpectedPermissions = @{

    $SystemAccount.Value = "FullControl"

    $AdministratorsAccount.Value = "FullControl"

    $UsersAccount.Value = "ReadAndExecute"
}


foreach ($Account in $ExpectedPermissions.Keys) {

    $Rules = $ResultACL.Access |
        Where-Object {
            $_.IdentityReference.Value -eq $Account -and
            $_.IsInherited -eq $false
        }

    if ($Rules) {

        foreach ($Rule in $Rules) {

            Write-Host "[OK] $($Rule.IdentityReference)" -ForegroundColor Green
            Write-Host "     Rights    : $($Rule.FileSystemRights)"
            Write-Host "     Type      : $($Rule.AccessControlType)"
            Write-Host "     Inherited : $($Rule.IsInherited)"
        }

    }
    else {

        Write-Host "[ERROR] Missing ACL: $Account" -ForegroundColor Red
    }
}


# ------------------------------------------------------------
# Check inheritance
# ------------------------------------------------------------

Write-Host ""

if ($ResultACL.AreAccessRulesProtected) {

    Write-Host "[OK] ACL inheritance disabled" -ForegroundColor Green

}
else {

    Write-Host "[ERROR] ACL inheritance is still enabled" -ForegroundColor Red
}


# ------------------------------------------------------------
# Final output
# ------------------------------------------------------------

Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host "BGInfo ACL configuration completed." -ForegroundColor Green
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

Write-Host "Folder:"
Write-Host "  $BGInfoFolder"
Write-Host ""

Write-Host "Permissions:"
Write-Host "  SYSTEM         : Full Control"
Write-Host "  Administrators : Full Control"
Write-Host "  Users          : Read and Execute"
Write-Host ""

Write-Host "Inheritance:"
Write-Host "  Disabled"
Write-Host ""
