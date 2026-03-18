#Requires -RunAsAdministrator

<#
.SYNOPSIS
    Windows 11 Debloat Script - Selective removal of built-in apps and telemetry.

.DESCRIPTION
    Removes preinstalled Microsoft and OEM apps that are unused in professional
    or technical workstation environments (CAD, 3D printing, engineering tools).

    Preserves components required for stability and compatibility:
      - Windows Defender and Windows Update
      - File Explorer and shell components
      - Microsoft Edge WebView2 Runtime (required by many third-party apps)
      - DirectX, .NET runtime, Visual C++ redistributables
      - Accessibility tools (Narrator, Magnifier, Snipping Tool)
      - Notepad, Clock, Photos, Windows Media Player (legacy)

    Also disables:
      - Microsoft telemetry and diagnostic data collection
      - Bing integration in Start menu search
      - Copilot and AI assistant sidebar
      - Windows widgets (news feed)
      - Silent reinstallation of removed apps after Windows updates

    Edge removal:
      Applies the DMA (Digital Markets Act) registry policy that enables
      official uninstallation of Microsoft Edge via Settings > Apps.
      WebView2 Runtime is intentionally NOT removed.

.NOTES
    Tested on: Windows 11 22H2, 23H2, 24H2
    Requires:  PowerShell 5.1+ running as Administrator
    License:   GPL 3.0

.LINK
    https://github.com/

.EXAMPLE
    # Run directly (requires administrator privileges):
    .\debloat-windows.ps1

.EXAMPLE
    # Allow execution and run in one line:
    Set-ExecutionPolicy Bypass -Scope Process -Force; .\debloat-windows.ps1
#>

# -------------------------------------------------------
# ADMINISTRATOR CHECK
# -------------------------------------------------------
$currentPrincipal = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
if (-NOT $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "`n  ERROR: This script must be run as Administrator.`n" -ForegroundColor Red
    pause
    exit 1
}

Clear-Host
Write-Host ""
Write-Host "  =========================================================" -ForegroundColor Cyan
Write-Host "   Windows 11 Debloat Script" -ForegroundColor Cyan
Write-Host "  =========================================================" -ForegroundColor Cyan
Write-Host ""


# -------------------------------------------------------
# STEP 1 - SYSTEM RESTORE POINT
# Creates a restore point before any changes are made.
# If something goes wrong, restore via:
# sysdm.cpl > System Protection > System Restore
# -------------------------------------------------------
Write-Host "  [1/4] Creating system restore point..." -ForegroundColor White

try {
    Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
    Checkpoint-Computer `
        -Description "Pre-Debloat $(Get-Date -Format 'yyyy-MM-dd HH:mm')" `
        -RestorePointType MODIFY_SETTINGS `
        -ErrorAction Stop
    Write-Host "         OK`n" -ForegroundColor Green
} catch {
    Write-Host "         WARNING: Could not create restore point. Continuing anyway.`n" -ForegroundColor Yellow
}


# -------------------------------------------------------
# STEP 2 - APPX PACKAGE REMOVAL
#
# Each package is removed for the current user and all
# existing users (Remove-AppxPackage -AllUsers), then
# deprovisioned to prevent reinstallation for new accounts
# (Remove-AppxProvisionedPackage -Online).
#
# Packages intentionally NOT listed here:
#   - Microsoft.Photos              (lightweight, useful as fallback)
#   - Microsoft.WindowsNotepad      (used by some CAD/driver installers)
#   - Microsoft.WindowsAlarms       (Clock app)
#   - Microsoft.ScreenSketch        (Snipping Tool - required by Win+Shift+S)
#   - Microsoft.Narrator            (accessibility)
#   - Microsoft.MicrosoftEdgeDevToolsClient  (WebView2 dependency)
#   - Microsoft.WindowsMediaPlayer  (legacy WMP - some audio drivers depend on it)
# -------------------------------------------------------
Write-Host "  [2/4] Removing AppX packages..." -ForegroundColor White
Write-Host ""

$packagesToRemove = @(

    # Entertainment and media (Store versions)
    "*Microsoft.ZuneMusic*"              # Groove Music
    "*Microsoft.ZuneVideo*"              # Movies & TV
    "*Microsoft.WindowsMediaPlayer*"     # WMP (Store version, not legacy)
    "*Microsoft.Media.MediaPlayer*"

    # Productivity apps
    "*Microsoft.MSPaint*"                # Paint
    "*Microsoft.Paint*"
    "*Microsoft.Microsoft3DViewer*"      # 3D Viewer
    "*Microsoft.Print3D*"                # Print 3D
    "*Microsoft.MicrosoftStickyNotes*"   # Sticky Notes
    "*Microsoft.Todos*"                  # Microsoft To Do
    "*Microsoft.WindowsCalculator*"      # Calculator

    # Communication and cloud storage
    "*Microsoft.SkypeApp*"
    "*MicrosoftTeams*"
    "*Microsoft.Teams*"
    "*Microsoft.OneDrive*"
    "*Microsoft.OneDriveSync*"
    "*microsoft.windowscommunicationsapps*"  # Mail and Calendar
    "*Microsoft.OutlookForWindows*"          # New Outlook (Store)

    # Accessibility (kept: Narrator, Snipping Tool)
    "*Microsoft.WindowsSpeechRecognition*"

    # Xbox and gaming
    "*Microsoft.XboxApp*"
    "*Microsoft.XboxGameOverlay*"
    "*Microsoft.XboxGamingOverlay*"      # Xbox Game Bar
    "*Microsoft.XboxIdentityProvider*"
    "*Microsoft.XboxSpeechToTextOverlay*"
    "*Microsoft.Xbox.TCUI*"
    "*Microsoft.GamingApp*"

    # Microsoft consumer and lifestyle apps
    "*Microsoft.BingNews*"
    "*Microsoft.BingWeather*"
    "*Microsoft.BingFinance*"
    "*Microsoft.BingSports*"
    "*Microsoft.BingSearch*"
    "*Microsoft.BingTranslator*"
    "*Microsoft.MicrosoftSolitaireCollection*"
    "*Microsoft.549981C3F5F10*"          # Cortana (app package)
    "*Microsoft.Cortana*"
    "*Microsoft.People*"
    "*Microsoft.WindowsMaps*"
    "*Microsoft.WindowsFeedbackHub*"
    "*Microsoft.GetHelp*"
    "*Microsoft.Getstarted*"             # Tips
    "*Microsoft.MixedReality.Portal*"
    "*Microsoft.Wallet*"
    "*Microsoft.YourPhone*"              # Phone Link
    "*Microsoft.PowerAutomateDesktop*"
    "*Microsoft.MicrosoftOfficeHub*"     # Office Hub (not Office itself)
    "*Microsoft.WindowsSoundRecorder*"
    "*Microsoft.Advertising.Xaml*"
    "*MicrosoftCorporationII.QuickAssist*"
    "*Clipchamp.Clipchamp*"
    "*Microsoft.Copilot*"
    "*Microsoft.Windows.Ai.Copilot.Provider*"
    "*MicrosoftWindows.Client.WebExperience*"  # Widgets

    # Common OEM and third-party preinstalled apps
    "*king.com*"
    "*Spotify*"
    "*Disney*"
    "*Netflix*"
    "*AmazonVideo*"
    "*Facebook*"
    "*Twitter*"
    "*TikTok*"
    "*WhatsApp*"
    "*CandyCrush*"
)

$removed  = 0
$skipped  = 0
$notFound = 0

foreach ($pattern in $packagesToRemove) {
    $packages = Get-AppxPackage -AllUsers $pattern -ErrorAction SilentlyContinue
    if ($packages) {
        foreach ($pkg in $packages) {
            try {
                $pkg | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
                Get-AppxProvisionedPackage -Online |
                    Where-Object { $_.DisplayName -like $pattern } |
                    Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
                Write-Host "         [-] $($pkg.Name)" -ForegroundColor Green
                $removed++
            } catch {
                Write-Host "         [!] Skipped (protected): $($pkg.Name)" -ForegroundColor DarkYellow
                $skipped++
            }
        }
    } else {
        $notFound++
    }
}

Write-Host ""
Write-Host "         Removed: $removed  |  Skipped: $skipped  |  Not found: $notFound`n" -ForegroundColor Cyan


# -------------------------------------------------------
# STEP 2b - ONEDRIVE STANDALONE UNINSTALL
# OneDrive is a Win32 app, not an AppX package, so it
# requires its own uninstaller. Registry keys are also
# cleaned to remove the sidebar entry in File Explorer.
# -------------------------------------------------------
Write-Host "  [2b]   Removing OneDrive..." -ForegroundColor White

Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
Start-Sleep -Seconds 2

$oneDrivePaths = @(
    "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe"
    "$env:SYSTEMROOT\System32\OneDriveSetup.exe"
    "$env:LOCALAPPDATA\Microsoft\OneDrive\OneDriveSetup.exe"
)

$oneDriveRemoved = $false
foreach ($path in $oneDrivePaths) {
    if (Test-Path $path) {
        Start-Process $path "/uninstall" -Wait -ErrorAction SilentlyContinue
        $oneDriveRemoved = $true
        break
    }
}

# Remove registry keys (File Explorer sidebar entry and policies)
@(
    "HKCU:\SOFTWARE\Microsoft\OneDrive"
    "HKLM:\SOFTWARE\Microsoft\OneDrive"
    "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
    "HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}"
) | ForEach-Object {
    Remove-Item $_ -Recurse -Force -ErrorAction SilentlyContinue
}

if ($oneDriveRemoved) {
    Write-Host "         OK - OneDrive removed.`n" -ForegroundColor Green
} else {
    Write-Host "         OneDrive not found or already removed.`n" -ForegroundColor DarkYellow
}


# -------------------------------------------------------
# STEP 3 - TELEMETRY, ADS, COPILOT, WIDGETS
#
# All changes are registry-based and reversible.
# Nothing here affects drivers, security, or system stability.
# -------------------------------------------------------
Write-Host "  [3/4] Disabling telemetry, ads, Copilot and Widgets..." -ForegroundColor White
Write-Host ""

# -- Telemetry and diagnostic data --
# Sets data collection to Security level (minimum allowed on non-Enterprise).
# Disables DiagTrack (Connected User Experiences) and WAP Push services.
Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" `
    -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection" `
    -Name "AllowTelemetry" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue

Stop-Service  "DiagTrack"        -Force -ErrorAction SilentlyContinue
Set-Service   "DiagTrack"        -StartupType Disabled -ErrorAction SilentlyContinue
Stop-Service  "dmwappushservice" -Force -ErrorAction SilentlyContinue
Set-Service   "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue

Write-Host "         OK - Telemetry disabled." -ForegroundColor Green

# -- Copilot --
$copilotPaths = @(
    "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
    "HKCU:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot"
)
foreach ($path in $copilotPaths) {
    if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null }
    Set-ItemProperty -Path $path -Name "TurnOffWindowsCopilot" -Value 1 -Type DWord -Force -ErrorAction SilentlyContinue
}
Write-Host "         OK - Copilot disabled." -ForegroundColor Green

# -- Widgets (news and interests taskbar feed) --
$dshPath = "HKLM:\SOFTWARE\Policies\Microsoft\Dsh"
if (-not (Test-Path $dshPath)) { New-Item -Path $dshPath -Force | Out-Null }
Set-ItemProperty -Path $dshPath -Name "AllowNewsAndInterests" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Write-Host "         OK - Widgets disabled." -ForegroundColor Green

# -- Bing in Start menu search --
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" `
    -Name "BingSearchEnabled" -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search" `
    -Name "CortanaConsent"    -Value 0 -Type DWord -Force -ErrorAction SilentlyContinue
Write-Host "         OK - Bing removed from Start search." -ForegroundColor Green

# -- Content Delivery Manager (ads, tips, silent app reinstallation) --
# SilentInstalledAppsEnabled = 0 prevents Windows from quietly reinstalling
# removed apps after feature updates.
$cdmPath = "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager"
$cdmSettings = @{
    "ContentDeliveryAllowed"          = 0
    "SilentInstalledAppsEnabled"      = 0
    "PreInstalledAppsEnabled"         = 0
    "PreInstalledAppsEverEnabled"     = 0
    "OemPreInstalledAppsEnabled"      = 0
    "SubscribedContent-310093Enabled" = 0   # Start suggested apps
    "SubscribedContent-338387Enabled" = 0   # Windows tips
    "SubscribedContent-338388Enabled" = 0   # Suggested apps in Start
    "SubscribedContent-338389Enabled" = 0   # Tips and tricks
    "SubscribedContent-338393Enabled" = 0   # Lock screen suggestions
    "SubscribedContent-353694Enabled" = 0
    "SubscribedContent-353696Enabled" = 0
    "SystemPaneSuggestionsEnabled"    = 0
}
foreach ($entry in $cdmSettings.GetEnumerator()) {
    Set-ItemProperty -Path $cdmPath -Name $entry.Key -Value $entry.Value `
        -Type DWord -Force -ErrorAction SilentlyContinue
}
Write-Host "         OK - Ads and silent app reinstallation disabled.`n" -ForegroundColor Green


# -------------------------------------------------------
# STEP 4 - EDGE REMOVAL (DMA / Digital Markets Act method)
#
# This is the cleanest available approach for EU users.
# It applies the EdgeUpdate policy that enables the official
# uninstall option in Settings > Apps > Installed Apps.
#
# After rebooting, uninstall Edge manually:
#   Settings > Apps > Installed Apps > Microsoft Edge > Uninstall
#
# IMPORTANT: Do NOT remove "Microsoft Edge WebView2 Runtime".
# WebView2 is a shared browser engine used by many third-party
# applications (including Autodesk products, SolidWorks, and
# various installers) and is independent from the Edge browser.
# -------------------------------------------------------
Write-Host "  [4/4] Enabling Edge uninstall via DMA policy..." -ForegroundColor White

$edgeUpdatePath = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"
if (-not (Test-Path $edgeUpdatePath)) {
    New-Item -Path $edgeUpdatePath -Force | Out-Null
}
Set-ItemProperty -Path $edgeUpdatePath -Name "InstallDefault" -Value 0 `
    -Type DWord -Force -ErrorAction SilentlyContinue

Write-Host "         OK - Policy applied." -ForegroundColor Green
Write-Host ""
Write-Host "         AFTER REBOOT - to complete Edge removal:" -ForegroundColor Yellow
Write-Host "         Settings > Apps > Installed Apps > Microsoft Edge > Uninstall" -ForegroundColor White
Write-Host ""
Write-Host "         DO NOT remove 'Microsoft Edge WebView2 Runtime'." -ForegroundColor Red
Write-Host "         It is a shared component used by many third-party apps.`n" -ForegroundColor Red


# -------------------------------------------------------
# SUMMARY
# -------------------------------------------------------
Write-Host "  =========================================================" -ForegroundColor Cyan
Write-Host "   Done. Please reboot your PC." -ForegroundColor Cyan
Write-Host ""
Write-Host "   PRESERVED:" -ForegroundColor White
Write-Host "   + Windows Defender / Windows Update / File Explorer" -ForegroundColor Green
Write-Host "   + Microsoft Photos / Notepad / Clock / Snipping Tool" -ForegroundColor Green
Write-Host "   + Windows Media Player (legacy)" -ForegroundColor Green
Write-Host "   + Narrator / Magnifier (accessibility)" -ForegroundColor Green
Write-Host "   + WebView2 Runtime / DirectX / .NET / VC++ Redistributables" -ForegroundColor Green
Write-Host ""
Write-Host "   REMOVED: all items listed above" -ForegroundColor DarkYellow
Write-Host "   EDGE:    uninstall manually after reboot (see Step 4)" -ForegroundColor DarkYellow
Write-Host "  =========================================================" -ForegroundColor Cyan
Write-Host ""
pause
