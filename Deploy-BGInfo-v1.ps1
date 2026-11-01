<#
.SYNOPSIS
    BGInfo AutoDeploy - Master deployment script.

.DESCRIPTION
    Complete automated BGInfo deployment for Windows workstations.

    The script performs:
    - Administrator validation
    - Windows detection
    - Manufacturer and hardware family detection
    - Microsoft Sysinternals BGInfo installation
    - Download of customized Workstation.bgi
    - Download of custom BGInfo scripts
    - Manufacturer/family wallpaper selection
    - Generic wallpaper fallback
    - Real JPEG validation
    - BGInfo AutoStart configuration for all users
    - Removal of legacy BGInfo AutoStart
    - BGInfo execution
    - Secure ACL configuration

.NOTES
    Project: BGInfo AutoDeploy
    Version: 1.0
    Repository: Ldmat673/bginfo-autodeploy
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

# ============================================================
# Configuration
# ============================================================

$ProjectVersion = "1.0"

$BGInfoFolder = "C:\BGInfo"

$RepoOwner  = "Ldmat673"
$RepoName   = "bginfo-autodeploy"
$RepoBranch = "main"

$RepoRaw   = "https://raw.githubusercontent.com/$RepoOwner/$RepoName/$RepoBranch"

$BGInfoURL = "https://download.sysinternals.com/files/BGInfo.zip"
$BGInfoZIP = Join-Path $env:TEMP "BGInfo.zip"

$BGInfoExecutable = Join-Path $BGInfoFolder "Bginfo64.exe"
$BGIFile          = Join-Path $BGInfoFolder "Workstation.bgi"
$VBScriptFile     = Join-Path $BGInfoFolder "C-Disk-Space.vbs"
$WallpaperFile    = Join-Path $BGInfoFolder "wallpaper.jpg"

# ============================================================
# Functions
# ============================================================

function Write-Section {

    param(
        [Parameter(Mandatory)]
        [string]$Title
    )

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host " $Title" -ForegroundColor Cyan
    Write-Host "============================================" -ForegroundColor Cyan
    Write-Host ""
}

function Write-OK {

    param([string]$Message)

    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Info {

    param([string]$Message)

    Write-Host "[INFO] $Message" -ForegroundColor Cyan
}

function Write-WarningMessage {

    param([string]$Message)

    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Stop-Deployment {

    param([string]$Message)

    Write-Host ""
    Write-Host "[ERROR] $Message" -ForegroundColor Red
    Write-Host ""

    exit 1
}

function Invoke-Download {

    param(
        [Parameter(Mandatory)]
        [string]$Uri,

        [Parameter(Mandatory)]
        [string]$Destination
    )

    Invoke-WebRequest `
        -Uri $Uri `
        -OutFile $Destination `
        -UseBasicParsing `
        -ErrorAction Stop
}

function Test-JPEG {

    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

    if (-not (Test-Path -LiteralPath $Path)) {
        return $false
    }

    $FileInfo = Get-Item -LiteralPath $Path

    if ($FileInfo.Length -lt 4) {
        return $false
    }

    $Stream = [System.IO.File]::OpenRead($Path)

    try {

        $Byte1 = $Stream.ReadByte()
        $Byte2 = $Stream.ReadByte()
        $Byte3 = $Stream.ReadByte()

        return (
            $Byte1 -eq 0xFF -and
            $Byte2 -eq 0xD8 -and
            $Byte3 -eq 0xFF
        )
    }
    finally {
        $Stream.Dispose()
    }
}


function Set-BGInfoControlledACL {

    param(
        [Parameter(Mandatory)]
        [string]$Path
    )

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

    $ACL = New-Object System.Security.AccessControl.DirectorySecurity

    # Disable inheritance and remove inherited entries.
    $ACL.SetAccessRuleProtection($true, $false)

    $InheritanceFlags = `
        [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor `
        [System.Security.AccessControl.InheritanceFlags]::ObjectInherit

    $PropagationFlags = `
        [System.Security.AccessControl.PropagationFlags]::None

    $Allow = `
        [System.Security.AccessControl.AccessControlType]::Allow

    $SystemRule = New-Object `
        System.Security.AccessControl.FileSystemAccessRule(
            $SystemAccount,
            [System.Security.AccessControl.FileSystemRights]::FullControl,
            $InheritanceFlags,
            $PropagationFlags,
            $Allow
        )

    $AdministratorsRule = New-Object `
        System.Security.AccessControl.FileSystemAccessRule(
            $AdministratorsAccount,
            [System.Security.AccessControl.FileSystemRights]::FullControl,
            $InheritanceFlags,
            $PropagationFlags,
            $Allow
        )

    $UsersRule = New-Object `
        System.Security.AccessControl.FileSystemAccessRule(
            $UsersAccount,
            [System.Security.AccessControl.FileSystemRights]::ReadAndExecute,
            $InheritanceFlags,
            $PropagationFlags,
            $Allow
        )

    $ACL.AddAccessRule($SystemRule)
    $ACL.AddAccessRule($AdministratorsRule)
    $ACL.AddAccessRule($UsersRule)

    Set-Acl `
        -LiteralPath $Path `
        -AclObject $ACL
}

# ============================================================
# Start
# ============================================================

Clear-Host

Write-Section "BGInfo AutoDeploy v$ProjectVersion"

Write-OK "Administrator privileges"
Write-Info "Repository: $RepoOwner/$RepoName"

# TLS 1.2 for compatibility with older Windows versions.
[Net.ServicePointManager]::SecurityProtocol = `
    [Net.ServicePointManager]::SecurityProtocol -bor `
    [Net.SecurityProtocolType]::Tls12

# ============================================================
# Operating System Detection
# ============================================================

Write-Section "Operating System Detection"

$OS = Get-CimInstance Win32_OperatingSystem

if ($OS.ProductType -eq 1) {
    $OSType = "Workstation"
}
else {
    $OSType = "Server"
}

Write-OK "Operating System : $($OS.Caption)"
Write-OK "OS Type          : $OSType"
Write-OK "OS Build         : $($OS.BuildNumber)"
Write-OK "Architecture     : $($OS.OSArchitecture)"

if ($OSType -ne "Workstation") {

    Write-WarningMessage "Windows Server detected."
    Write-WarningMessage "Version 1.0 currently uses Workstation.bgi."
}

# ============================================================
# Hardware Detection
# ============================================================

Write-Section "Hardware Detection"

$ComputerSystem  = Get-CimInstance Win32_ComputerSystem
$ComputerProduct = Get-CimInstance Win32_ComputerSystemProduct
$BIOS            = Get-CimInstance Win32_BIOS

$Manufacturer    = $ComputerSystem.Manufacturer
$Model           = $ComputerSystem.Model
$SystemFamily    = $ComputerSystem.SystemFamily
$SystemSKUNumber = $ComputerSystem.SystemSKUNumber

$ProductName     = $ComputerProduct.Name
$ProductVersion  = $ComputerProduct.Version
$SerialNumber    = $BIOS.SerialNumber

$DetectionString = @(
    $Model
    $SystemFamily
    $SystemSKUNumber
    $ProductName
    $ProductVersion
) -join " "

$Brand  = "Generic"
$Family = "Generic"

switch -Regex ($Manufacturer) {

    "LENOVO" {

        $Brand = "Lenovo"

        switch -Regex ($DetectionString) {

            "ThinkPad" { $Family = "ThinkPad"; break }
            "IdeaPad"  { $Family = "IdeaPad";  break }
            "Legion"   { $Family = "Legion";   break }
            "Yoga"     { $Family = "Yoga";     break }

            default {
                $Family = "Generic"
            }
        }

        break
    }

    "Dell" {

        $Brand = "Dell"

        switch -Regex ($DetectionString) {

            "Alienware" { $Family = "Alienware"; break }
            "Latitude"  { $Family = "Latitude";  break }
            "Precision" { $Family = "Precision"; break }
            "XPS"       { $Family = "XPS";       break }

            default {
                $Family = "Generic"
            }
        }

        break
    }

    "HP|Hewlett-Packard" {

        $Brand = "HP"

        switch -Regex ($DetectionString) {

            "EliteBook" { $Family = "EliteBook"; break }
            "ProBook"   { $Family = "ProBook";   break }
            "ZBook"     { $Family = "ZBook";     break }
            "Pavilion"  { $Family = "Pavilion";  break }
            "OMEN"      { $Family = "OMEN";      break }

            default {
                $Family = "Generic"
            }
        }

        break
    }

    "ASUSTeK|ASUS" {

        $Brand = "ASUS"

        switch -Regex ($DetectionString) {

            "ExpertBook" { $Family = "ExpertBook"; break }
            "Zenbook"    { $Family = "Zenbook";    break }
            "VivoBook"   { $Family = "VivoBook";   break }
            "ROG"        { $Family = "ROG";        break }
            "TUF"        { $Family = "TUF";        break }

            default {
                $Family = "Generic"
            }
        }

        break
    }

    "Acer" {

        $Brand = "Acer"

        switch -Regex ($DetectionString) {

            "Aspire"     { $Family = "Aspire";     break }
            "TravelMate" { $Family = "TravelMate"; break }
            "Predator"   { $Family = "Predator";   break }
            "Nitro"      { $Family = "Nitro";      break }

            default {
                $Family = "Generic"
            }
        }

        break
    }

    "Micro-Star|MSI" {

        $Brand = "MSI"

        switch -Regex ($DetectionString) {

            "Creator"  { $Family = "Creator";  break }
            "Business" { $Family = "Business"; break }
            "Gaming"   { $Family = "Gaming";   break }

            default {
                $Family = "Generic"
            }
        }

        break
    }

    "Gigabyte" {

        $Brand = "Gigabyte"

        switch -Regex ($DetectionString) {

            "AORUS" { $Family = "AORUS"; break }
            "AERO"  { $Family = "AERO";  break }

            default {
                $Family = "Generic"
            }
        }

        break
    }

    "Microsoft" {

        $Brand = "Microsoft"

        if ($DetectionString -match "Surface") {
            $Family = "Surface"
        }
        else {
            $Family = "Generic"
        }

        break
    }

    "Samsung" {

        $Brand = "Samsung"

        if ($DetectionString -match "Galaxy") {
            $Family = "GalaxyBook"
        }
        else {
            $Family = "Generic"
        }

        break
    }

    default {

        $Brand  = "Generic"
        $Family = "Generic"
    }
}

Write-OK "Computer Name : $env:COMPUTERNAME"
Write-OK "Manufacturer  : $Manufacturer"
Write-OK "Model         : $Model"
Write-OK "System Family : $SystemFamily"
Write-OK "Serial Number : $SerialNumber"
Write-OK "Brand         : $Brand"
Write-OK "Family        : $Family"

# ============================================================
# Prepare BGInfo Folder
# ============================================================

Write-Section "BGInfo Installation"

if (-not (Test-Path -LiteralPath $BGInfoFolder)) {

    New-Item `
        -Path $BGInfoFolder `
        -ItemType Directory `
        -Force | Out-Null

    Write-OK "Created $BGInfoFolder"
}
else {

    Write-OK "$BGInfoFolder already exists"
}

# ============================================================
# Download and Extract BGInfo
# ============================================================

Remove-Item `
    -LiteralPath $BGInfoZIP `
    -Force `
    -ErrorAction SilentlyContinue

Write-Info "Downloading Microsoft Sysinternals BGInfo"

try {

    Invoke-Download `
        -Uri $BGInfoURL `
        -Destination $BGInfoZIP

    if ((Get-Item $BGInfoZIP).Length -le 0) {
        Stop-Deployment "BGInfo downloaded package is empty."
    }

    Expand-Archive `
        -LiteralPath $BGInfoZIP `
        -DestinationPath $BGInfoFolder `
        -Force

    Remove-Item `
        -LiteralPath $BGInfoZIP `
        -Force `
        -ErrorAction SilentlyContinue
}
catch {

    Stop-Deployment "BGInfo installation failed: $($_.Exception.Message)"
}

if (-not (Test-Path -LiteralPath $BGInfoExecutable)) {
    Stop-Deployment "Bginfo64.exe was not found after extraction."
}

$BGInfoVersion = (
    Get-Item $BGInfoExecutable
).VersionInfo.FileVersion

Write-OK "BGInfo installed"
Write-OK "BGInfo version: $BGInfoVersion"

# ============================================================
# Configuration Download
# ============================================================

Write-Section "Configuration Download"

$BGIURL = "$RepoRaw/Config/Workstation.bgi"
$VBSURL = "$RepoRaw/Scripts/Custom/C-Disk-Space.vbs"

try {

    Invoke-Download `
        -Uri $BGIURL `
        -Destination $BGIFile

    Write-OK "Workstation.bgi downloaded"

    Invoke-Download `
        -Uri $VBSURL `
        -Destination $VBScriptFile

    Write-OK "C-Disk-Space.vbs downloaded"
}
catch {

    Stop-Deployment "Configuration download failed: $($_.Exception.Message)"
}

if (-not (Test-Path -LiteralPath $BGIFile)) {
    Stop-Deployment "Workstation.bgi is missing."
}

if (-not (Test-Path -LiteralPath $VBScriptFile)) {
    Stop-Deployment "C-Disk-Space.vbs is missing."
}

# ============================================================
# Wallpaper Selection
# ============================================================

Write-Section "Wallpaper Selection"

$WallpaperPaths = @()

# Preferred manufacturer/family collection.
if ($Brand -ne "Generic" -and $Family -ne "Generic") {
    $WallpaperPaths += "Wallpapers/$Brand/$Family"
}

# Manufacturer fallback.
if ($Brand -ne "Generic") {
    $WallpaperPaths += "Wallpapers/$Brand/Generic"
}

# Global fallback.
$WallpaperPaths += "Wallpapers/Generic"

$SelectedCollection = $null
$SelectedWallpaper  = $null
$ValidWallpaperFound = $false

# Supports up to 20 wallpapers per collection.
$WallpaperCandidates = 1..20 | ForEach-Object {
    "wallpaper-{0:D2}.jpg" -f $_
}

foreach ($Collection in $WallpaperPaths) {

    Write-Info "Checking $Collection"

    # Randomize the wallpapers so each deployment can select a different one.
    $RandomCandidates = $WallpaperCandidates | Sort-Object { Get-Random }

    foreach ($WallpaperName in $RandomCandidates) {

        $WallpaperURL = "$RepoRaw/$Collection/$WallpaperName"

        $TemporaryWallpaper = Join-Path `
            $env:TEMP `
            ("BGInfo-" + $WallpaperName)

        Remove-Item `
            -LiteralPath $TemporaryWallpaper `
            -Force `
            -ErrorAction SilentlyContinue

        try {

            Invoke-WebRequest `
                -Uri $WallpaperURL `
                -OutFile $TemporaryWallpaper `
                -UseBasicParsing `
                -ErrorAction Stop

            # Make sure GitHub actually returned a valid JPEG.
            if (Test-JPEG -Path $TemporaryWallpaper) {

                Copy-Item `
                    -LiteralPath $TemporaryWallpaper `
                    -Destination $WallpaperFile `
                    -Force

                $SelectedCollection  = $Collection
                $SelectedWallpaper   = $WallpaperName
                $ValidWallpaperFound = $true

                Write-OK "Wallpaper collection: $Collection"
                Write-OK "Valid JPEG selected: $WallpaperName"

                break
            }
            else {

                Write-WarningMessage "$WallpaperName is not a real JPEG. Skipping."
            }
        }
        catch {

            # Normally means that candidate does not exist.
            # Silently continue searching.
        }
        finally {

            Remove-Item `
                -LiteralPath $TemporaryWallpaper `
                -Force `
                -ErrorAction SilentlyContinue
        }
    }

    if ($ValidWallpaperFound) {
        break
    }
}

if (-not $ValidWallpaperFound) {

    Stop-Deployment "No valid wallpaper was found in any collection."
}

if (-not (Test-JPEG -Path $WallpaperFile)) {

    Stop-Deployment "Final wallpaper validation failed."
}

Write-OK "Wallpaper installed: $WallpaperFile"

# ============================================================
# AutoStart Configuration
# ============================================================

Write-Section "AutoStart Configuration"

$RunPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"

# Remove AutoStart created by older BGInfo deployment.
$LegacyRun = Get-ItemProperty `
    -Path $RunPath `
    -Name "BgInfo" `
    -ErrorAction SilentlyContinue

if ($null -ne $LegacyRun) {

    Remove-ItemProperty `
        -Path $RunPath `
        -Name "BgInfo" `
        -Force `
        -ErrorAction SilentlyContinue

    Write-OK "Legacy BgInfo AutoStart entry removed"
}
else {

    Write-OK "No legacy BgInfo AutoStart entry detected"
}

$RunName = "BGInfoAutoDeploy"

$RunCommand = `
    '"C:\BGInfo\Bginfo64.exe" "C:\BGInfo\Workstation.bgi" /timer:0 /nolicprompt'

New-ItemProperty `
    -Path $RunPath `
    -Name $RunName `
    -PropertyType String `
    -Value $RunCommand `
    -Force | Out-Null

$SavedRunCommand = (
    Get-ItemProperty `
        -Path $RunPath `
        -Name $RunName
).$RunName

if ($SavedRunCommand -ne $RunCommand) {
    Stop-Deployment "AutoStart registry validation failed."
}

Write-OK "AutoStart configured for all users"
Write-OK $SavedRunCommand

# ============================================================
# Apply BGInfo
# ============================================================

Write-Section "Apply BGInfo"

try {

    Start-Process `
        -FilePath $BGInfoExecutable `
        -ArgumentList "`"$BGIFile`" /timer:0 /nolicprompt" `
        -Wait

    Write-OK "BGInfo applied successfully"
}
catch {

    Stop-Deployment "BGInfo execution failed: $($_.Exception.Message)"
}

# ============================================================
# ACL Configuration
# ============================================================

Write-Section "ACL Configuration"

try {

    Set-BGInfoControlledACL `
        -Path $BGInfoFolder

    $ResultACL = Get-Acl -LiteralPath $BGInfoFolder

    if (-not $ResultACL.AreAccessRulesProtected) {
        Stop-Deployment "ACL inheritance is still enabled."
    }

    Write-OK "ACL inheritance disabled"
    Write-OK "SYSTEM: Full Control"
    Write-OK "Administrators: Full Control"
    Write-OK "Users: Read and Execute"
}
catch {

    Stop-Deployment "ACL configuration failed: $($_.Exception.Message)"
}

# ============================================================
# Final Validation
# ============================================================

Write-Section "Deployment Completed"

$RequiredFiles = @(
    $BGInfoExecutable
    $BGIFile
    $VBScriptFile
    $WallpaperFile
)

$ValidationFailed = $false

foreach ($File in $RequiredFiles) {

    if (Test-Path -LiteralPath $File) {

        Write-OK $File
    }
    else {

        Write-Host "[ERROR] Missing: $File" -ForegroundColor Red
        $ValidationFailed = $true
    }
}

if ($ValidationFailed) {
    Stop-Deployment "Deployment finished with missing files."
}

Write-Host ""
Write-Host "Computer:" -ForegroundColor Cyan
Write-Host "  $env:COMPUTERNAME"

Write-Host "Operating System:" -ForegroundColor Cyan
Write-Host "  $($OS.Caption)"

Write-Host "Hardware:" -ForegroundColor Cyan
Write-Host "  Manufacturer : $Manufacturer"
Write-Host "  Model        : $Model"
Write-Host "  Family       : $SystemFamily"

Write-Host "Detected Profile:" -ForegroundColor Cyan
Write-Host "  Brand        : $Brand"
Write-Host "  Family       : $Family"

Write-Host "Wallpaper:" -ForegroundColor Cyan
Write-Host "  Collection   : $SelectedCollection"
Write-Host "  Selected     : $SelectedWallpaper"
Write-Host "  Installed    : $WallpaperFile"

Write-Host "BGInfo:" -ForegroundColor Cyan
Write-Host "  Version      : $BGInfoVersion"
Write-Host "  Config       : $BGIFile"

Write-Host ""
Write-Host "BGInfo AutoDeploy v$ProjectVersion completed successfully." -ForegroundColor Green
Write-Host ""