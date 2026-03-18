# windows-debloat

A collection of PowerShell and batch scripts to clean up Windows 11 for technical workstation environments: CAD, 3D printing, engineering tools.

## Scripts

| Script | Type | Purpose |
|---|---|---|
| `debloat-windows.ps1` | PowerShell | Remove bloatware, disable telemetry, block silent reinstallation |
| `rendering-optimizer.bat` | Batch | Optimize system before a 3D slicer rendering session |
| `rendering-restore.bat` | Batch | Revert session changes after rendering |

---

## debloat-windows.ps1

### Features

- Removes unused Microsoft and OEM preinstalled apps
- Disables telemetry and diagnostic data collection
- Removes Bing from Start menu search
- Disables Copilot and Widgets
- Blocks silent reinstallation of removed apps after Windows Updates
- Enables official Edge uninstall via DMA (Digital Markets Act) policy
- Creates a System Restore Point before making any changes

### What is preserved

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

### What is removed

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

### Requirements

- Windows 11 (tested on 22H2, 23H2, 24H2)
- PowerShell 5.1 or later
- Administrator privileges

### Usage

**Option 1 — Right-click**

Right-click `debloat-windows.ps1` → **Run with PowerShell**

**Option 2 — Bypass execution policy for current session only**

```powershell
Set-ExecutionPolicy Bypass -Scope Process -Force
.\debloat-windows.ps1
```

### Edge removal

The script applies the EdgeUpdate Group Policy that enables the official uninstall option for Microsoft Edge on EEA-region devices (Digital Markets Act compliance).

After rebooting, complete the removal manually:

> **Settings → Apps → Installed Apps → Microsoft Edge → ⋯ → Uninstall**

> ⚠️ Do **not** remove **Microsoft Edge WebView2 Runtime**. It is a shared browser engine used internally by many third-party applications and is independent from the Edge browser itself.

### Reverting changes

A System Restore Point is created automatically at the start of the script.

To restore:

```
Win + R → sysdm.cpl → System Protection → System Restore
```

Apps removed via `Remove-AppxPackage` can generally be reinstalled from the Microsoft Store.

---

## rendering-optimizer.bat / rendering-restore.bat

Companion scripts for 3D slicer workloads on systems **without a dedicated GPU**.

On integrated GPU (iGPU) systems, the CPU and GPU share the same system RAM. The default Windows power plan throttles both, and the default GPU timeout (2 seconds) frequently causes driver resets during heavy rendering sessions in slicers such as BambuStudio or Chitubox.

### What rendering-optimizer.bat does

| Step | Action | Persistent |
|---|---|---|
| 1 | Switches to High Performance power plan | Session only |
| 2 | Raises GPU TDR timeout to 60 seconds | Yes (reboot required on first run) |
| 3 | Frees RAM (increases memory available to iGPU) | Session only |
| 4 | Suspends Windows Search and SysMain | Session only |
| 5 | Launches selected slicer with High process priority | — |

### What rendering-restore.bat does

- Restores the Balanced power plan
- Restarts only services that were active before the optimizer ran
- Leaves TDR timeout at 60 seconds (safe and beneficial to keep)

> To manually revert the TDR timeout to the Windows default:
> ```
> reg add "HKLM\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" /v TdrDelay /t REG_DWORD /d 2 /f
> ```

### Usage

1. Before starting a rendering session, run `rendering-optimizer.bat` as Administrator
2. Select the slicer to launch (BambuStudio, Chitubox, both, or none)
3. When done, run `rendering-restore.bat` as Administrator

> ⚠️ Edit the installation paths inside `rendering-optimizer.bat` if your slicer is installed in a non-default location.

### Requirements

- Windows 10 / 11
- Administrator privileges
- Supported slicers: BambuStudio, Chitubox (paths editable in script)

---

## Disclaimer

These scripts modify system settings and remove built-in applications. They are provided as-is, without warranty of any kind. Always review scripts before running them and ensure you have a backup or restore point.

Removing components from the preserved list in `debloat-windows.ps1` is not recommended and may affect system stability or third-party software compatibility.

## License

GPL-3.0 — see [LICENSE](LICENSE)

🇮🇹 [Leggi in italiano](README.it.md) 
