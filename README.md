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
- PowerShell
- Admin rights not required (writes only to user-level paths and registry)
Why No Admin Needed:
    HKCU stands for HKEY_CURRENT_USER — it only affects the currently logged-in user.
    Any standard user account can read and write to their own HKCU keys without elevation.
    This is commonly used for user-specific auto-start tasks (like launching apps after login) ;).
