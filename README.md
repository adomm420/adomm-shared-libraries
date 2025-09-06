# ⚙️ adomm.psfl.ps1 — Shared PowerShell Functions

**adomm.psfl.ps1** is a portable utility module for PowerShell projects.  
It provides a set of shared helper functions for console control, repainting, logging, mute toggles, and networking.  

This script is used by **Ping Monitor**, **Clock Matrix**, and other personal tools as a single source of truth for core functions.

---

## ✨ Features

- 🖥 **Console utilities**
  - Resize console buffer width safely
  - Clear/reset screen without breaking cursor position
  - Window repaint logic for consistent output

- 📑 **Repaint + Log Handling**
  - `Repaint-ConsoleFromBottom` renders log files with alternating line colors
  - Highlights failures (`*`) in red, slow responses (`!`) in yellow
  - Updates PowerShell window title with error counts

- 🌍 **Networking**
  - `$mf.ping()` — reliable trimmed-mean ping with retries
  - `$mf.time_difference()` — formats delta between two timestamps

- 🔊 **Mute Controls**
  - `mute` — toggle system volume mute/unmute

- 🔗 **Helpers**
  - `timestamp` — consistent time stamps for logs
  - `Get-DaySuffix` — suffix-aware date formatting

---

## 📦 Installation

Simply copy **`adomm.psfl.ps1`** into your project folder and import it in your script:

```powershell
. "$PSScriptRoot\adomm.psfl.ps1"
```

---

## 🚀 Example Usage

### Console repaint
```powershell
Repaint-ConsoleFromBottom
```

### Reliable ping
```powershell
$mf.ping("google.com")
```

### Toggle mute
```powershell
mute
```

---

## 📜 Changelog (Condensed)

- **v1.1 (2025-07-02)** — Stable baseline:
  - Dynamic `$Global:Folder` from `$PSCommandPath`
  - Repaint uses `$Global:PingMonitorVersion` + `$Global:Folder`
  - Fixed alternating line colors
  - Integrated mute, timestamp, resize helpers
- Earlier versions — experimental utilities (superseded)

---

## 👤 Author

**Mantas Adomavičius**  
MIT License
