<#
.SYNOPSIS
    Detects the hardware family and selects a random BGInfo wallpaper.

.NOTES
    Project: BGInfo AutoDeploy
    Component: Set-RandomWallpaper
    Version: 0.1
#>

#Requires -RunAsAdministrator

$ErrorActionPreference = "Stop"

$BGInfoFolder = "C:\BGInfo"
$Destination  = Join-Path $BGInfoFolder "wallpaper.jpg"

$RepoRaw = "https://raw.githubusercontent.com/Ldmat673/bginfo-autodeploy/main"

# ============================================================
# Hardware detection
# ============================================================

$ComputerSystem  = Get-CimInstance Win32_ComputerSystem
$ComputerProduct = Get-CimInstance Win32_ComputerSystemProduct

$Manufacturer    = $ComputerSystem.Manufacturer
$Model           = $ComputerSystem.Model
$SystemFamily    = $ComputerSystem.SystemFamily
$SystemSKUNumber = $ComputerSystem.SystemSKUNumber
$ProductName     = $ComputerProduct.Name
$ProductVersion  = $ComputerProduct.Version

$Brand  = "Generic"
$Family = "Generic"

$DetectionString = "$Model $SystemFamily $SystemSKUNumber $ProductName $ProductVersion"

# ============================================================
# Brand / Family detection
# ============================================================

switch -Regex ($Manufacturer) {

    "LENOVO" {

        $Brand = "Lenovo"

        switch -Regex ($DetectionString) {

            "ThinkPad" {
                $Family = "ThinkPad"
                break
            }

            "IdeaPad" {
                $Family = "IdeaPad"
                break
            }

            "Legion" {
                $Family = "Legion"
                break
            }

            "Yoga" {
                $Family = "Yoga"
                break
            }

            default {
                $Family = "Generic"
            }
        }

        break
    }

    default {
        $Brand  = "Generic"
        $Family = "Generic"
    }
}

Write-Host ""
Write-Host "============================================" -ForegroundColor Cyan
Write-Host "       BGInfo Wallpaper Selection" -ForegroundColor Cyan
Write-Host "============================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "[OK] Manufacturer : $Manufacturer" -ForegroundColor Green
Write-Host "[OK] Model        : $Model" -ForegroundColor Green
Write-Host "[OK] System Family: $SystemFamily" -ForegroundColor Green
Write-Host "[OK] Brand        : $Brand" -ForegroundColor Green
Write-Host "[OK] Family       : $Family" -ForegroundColor Green

# ============================================================
# Find available wallpapers
# ============================================================

$WallpaperCandidates = 1..20 | ForEach-Object {
    "wallpaper-{0:D2}.jpg" -f $_
}

$AvailableWallpapers = @()

Write-Host ""
Write-Host "[INFO] Searching wallpapers..." -ForegroundColor Cyan

foreach ($Wallpaper in $WallpaperCandidates) {

    $URL = "$RepoRaw/Wallpapers/$Brand/$Family/$Wallpaper"

    try {

        $Response = Invoke-WebRequest `
            -Uri $URL `
            -Method Head `
            -UseBasicParsing `
            -ErrorAction Stop

        if ($Response.StatusCode -eq 200) {

            $AvailableWallpapers += $Wallpaper

            Write-Host "[OK] Found: $Wallpaper" -ForegroundColor Green
        }
    }
    catch {
        # Candidate does not exist.
    }
}

# ============================================================
# Select random wallpaper
# ============================================================

if ($AvailableWallpapers.Count -eq 0) {

    Write-Host ""
    Write-Host "[ERROR] No wallpapers found for $Brand / $Family" -ForegroundColor Red

    exit 1
}

$SelectedWallpaper = Get-Random -InputObject $AvailableWallpapers

$SelectedURL = "$RepoRaw/Wallpapers/$Brand/$Family/$SelectedWallpaper"

Write-Host ""
Write-Host "[OK] Wallpapers available : $($AvailableWallpapers.Count)" -ForegroundColor Green
Write-Host "[OK] Selected wallpaper   : $SelectedWallpaper" -ForegroundColor Green

# ============================================================
# Download selected wallpaper
# ============================================================

if (-not (Test-Path $BGInfoFolder)) {

    New-Item `
        -Path $BGInfoFolder `
        -ItemType Directory `
        -Force | Out-Null
}

try {

    Invoke-WebRequest `
        -Uri $SelectedURL `
        -OutFile $Destination `
        -UseBasicParsing `
        -ErrorAction Stop

    Write-Host ""
    Write-Host "[OK] Wallpaper downloaded successfully" -ForegroundColor Green
    Write-Host "     $Destination"

}
catch {

    Write-Host ""
    Write-Host "[ERROR] Wallpaper download failed" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red

    exit 1
}

Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host "Wallpaper selection completed." -ForegroundColor Green
Write-Host "--------------------------------------------" -ForegroundColor DarkGray
Write-Host ""

Write-Host "Brand:"
Write-Host "  $Brand"

Write-Host "Family:"
Write-Host "  $Family"

Write-Host "Selected:"
Write-Host "  $SelectedWallpaper"

Write-Host "Installed as:"
Write-Host "  $Destination"
Write-Host ""
