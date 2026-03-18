# windows-debloat

A PowerShell script to selectively remove built-in Windows 11 apps, disable telemetry, and block silent app reinstallation — designed for technical workstation environments (CAD, 3D printing, engineering tools).

## Features

- Removes unused Microsoft and OEM preinstalled apps
- Disables telemetry and diagnostic data collection
- Removes Bing from Start menu search
- Disables Copilot and Widgets
- Blocks silent reinstallation of removed apps after Windows Updates
- Enables official Edge uninstall via DMA (Digital Markets Act) policy
- Creates a System Restore Point before making any changes

## What is preserved

| Component | Reason |
|---|---|
| Windows Defender | Security |
| Windows Update | Security patches |
| File Explorer | Core shell |
| Microsoft Photos | Lightweight image viewer |
| Notepad | Used by some CAD/driver installers |
| Clock / Alarms | System utility |
| Snipping Tool | Required by Win+Shift+S shortcut |
| Narrator / Magnifier | Accessibility |
| Windows Media Player (legacy) | Some audio drivers depend on it |
| Edge WebView2 Runtime | Shared engine used by many third-party apps |
| DirectX | Required for 3D rendering |
| .NET Runtime | Required by most modern apps |
| Visual C++ Redistributables | Required by most third-party software |

## What is removed

| Category | Apps |
|---|---|
| Media (Store) | Groove Music, Movies & TV, Media Player (Store) |
| Productivity | Paint, Paint 3D, 3D Viewer, Sticky Notes, To Do, Calculator |
| Communication | Skype, Microsoft Teams, Mail & Calendar, Outlook (Store) |
| Cloud | OneDrive |
| Gaming | Xbox App, Xbox Game Bar, Xbox Identity Provider, Gaming App |
| Microsoft consumer | Cortana, Bing News/Weather/Finance/Sports, Maps, Solitaire, Feedback Hub, Tips, Mixed Reality, Phone Link, Power Automate, Clipchamp, Quick Assist, Sound Recorder |
| AI / UI | Copilot, Widgets |
| OEM / third-party | Candy Crush, Spotify, Disney+, Netflix, Amazon Video, Facebook, Twitter, TikTok, WhatsApp (if preinstalled) |

## Requirements

- Windows 11 (tested on 22H2, 23H2, 24H2)
- PowerShell 5.1 or later
- Administrator privileges

## Usage

### Option 1 — Right-click

Right-click `debloat-windows.ps1` → **Run with PowerShell**

### Option 2 — PowerShell (bypass execution policy for current session only)

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\debloat-windows.ps1
```

### Option 3 — From an elevated PowerShell prompt

```powershell
# Navigate to the script directory
cd C:\path\to\script

# Run
.\debloat-windows.ps1
```

## Edge removal

The script applies the EdgeUpdate Group Policy that enables the official uninstall option for Microsoft Edge on EEA-region devices (Digital Markets Act compliance).

After rebooting, complete the removal manually:

> **Settings → Apps → Installed Apps → Microsoft Edge → ⋯ → Uninstall**

> ⚠️ Do **not** remove **Microsoft Edge WebView2 Runtime**. It is a shared browser engine used internally by many third-party applications and is independent from the Edge browser itself.

## Reverting changes

A System Restore Point is created automatically at the start of the script.

To restore:

```
Win + R → sysdm.cpl → System Protection → System Restore
```

Apps removed via `Remove-AppxPackage` can generally be reinstalled from the Microsoft Store.

## Disclaimer

This script modifies system settings and removes built-in applications. It is provided as-is, without warranty of any kind. Always review the script before running it and ensure you have a backup or restore point.

Removing apps from the list of preserved components is not recommended and may affect system stability or third-party software compatibility.

## License

GPL 3.0 — see [LICENSE](LICENSE)
