# Convert-PowerShellToBatch

This PowerShell script converts `.ps1` PowerShell scripts into hidden `.bat` launchers using base64 encoding and Windows scripting. It is intended for automation or deployment scenarios where silent script execution is preferred.

---

## 🧩 Features

- 🔐 Encodes PowerShell scripts as Base64 for hidden execution.
- 📁 Copies the batch file to `%APPDATA%\SVCDef`.
- 📜 Creates a `.vbs` file that runs the batch silently (no console window).
- 🧠 Registers the `.vbs` in `HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce` for one-time execution on next login.
- 📦 Supports processing multiple `.ps1` files using wildcards.

---

## ⚙️ Requirements

- Windows OS
- PowerShell 5.1 or higher
- Admin rights not required (writes only to user-level paths and registry)

