# PS2Bat - Advanced PowerShell to Batch Converter

A powerful PowerShell script that converts `.ps1` PowerShell scripts into hidden `.bat` launchers using base64 encoding and Windows scripting. Perfect for automation, deployment, and silent execution scenarios.

![Version](https://img.shields.io/badge/version-2.0-blue.svg)
![PowerShell](https://img.shields.io/badge/PowerShell-5.0+-blue.svg)
![Platform](https://img.shields.io/badge/platform-Windows-lightgrey.svg)

---

## 🚀 Features

### Core Functionality
- 🔐 **Base64 Encoding**: Encodes PowerShell scripts for hidden execution
- 📦 **Standalone Batch Files**: Creates portable `.bat` files that generate VBS launchers
- 📜 **VBS Launcher**: Creates silent VBS launchers for hidden PowerShell execution
- 🧠 **RunOnce Integration**: Registers VBS files in RunOnce registry for next login execution
- 📦 **Batch Processing**: Supports multiple `.ps1` files using wildcards

### Advanced Features
- ✅ **Enhanced Error Handling**: Comprehensive error checking and user-friendly messages
- 📊 **Detailed Logging**: Multi-level logging system with timestamps and color coding
- 🔍 **Syntax Validation**: PowerShell script syntax checking before conversion
- 🧪 **Test Mode**: Safe testing of generated batch files without execution
- 🧹 **Cleanup Functionality**: Remove generated files and registry entries
- ⚙️ **Custom Configuration**: Flexible output directories and behavior options
- 📈 **Progress Tracking**: Real-time progress indicators for batch operations
- 🛡️ **Security Features**: Execution policy checks and validation

---

## 📋 Requirements

- **Operating System**: Windows 7/8/10/11
- **PowerShell**: Version 5.0 or higher
- **Permissions**: No admin rights required (user-level operations only)
- **Registry Access**: HKCU (HKEY_CURRENT_USER) access for RunOnce integration

> **Why No Admin Rights Needed?**
> 
> HKCU (HKEY_CURRENT_USER) only affects the currently logged-in user. Any standard user account can read and write to their own HKCU keys without elevation. This is commonly used for user-specific auto-start tasks.

---

## 🛠️ Installation

1. **Download** the `ps2bat.ps1` script
2. **Place** it in your desired directory
3. **Run** PowerShell as your current user (no admin required)

---

## 📖 Usage

### Basic Usage

```powershell
# Convert a single PowerShell script
.\ps2bat.ps1 "C:\Scripts\MyScript.ps1"

# Convert multiple scripts using wildcards
.\ps2bat.ps1 "C:\Scripts\*.ps1"

# Interactive mode (prompts for file path)
.\ps2bat.ps1
```

### Advanced Usage

```powershell
# Enable verbose logging
.\ps2bat.ps1 "MyScript.ps1" -Verbose

# Test generated batch files without executing
.\ps2bat.ps1 "MyScript.ps1" -Test

# Use custom output directory
.\ps2bat.ps1 "MyScript.ps1" -OutputDir "C:\CustomPath"

# Skip PowerShell syntax validation
.\ps2bat.ps1 "MyScript.ps1" -SkipValidation

# Clean up generated files
.\ps2bat.ps1 -Cleanup

# Clean up specific files
.\ps2bat.ps1 "MyScript.ps1" -Cleanup

# Show help information
.\ps2bat.ps1 -Help
```

### Parameters

| Parameter | Type | Description | Example |
|-----------|------|-------------|---------|
| `Filepattern` | String | Path or pattern to PowerShell script(s) | `"C:\Scripts\*.ps1"` |
| `-Verbose` | Switch | Enable detailed logging output | `-Verbose` |
| `-Test` | Switch | Test generated batch files without executing | `-Test` |
| `-Cleanup` | Switch | Remove generated files and registry entries | `-Cleanup` |
| `-OutputDir` | String | Custom output directory | `-OutputDir "C:\Custom"` |
| `-SkipValidation` | Switch | Skip PowerShell syntax validation | `-SkipValidation` |
| `-Help` | Switch | Show help information | `-Help` |

---

## 📁 Generated Files

When you convert a PowerShell script, the following files are created:

### Primary Files
- **`ScriptName.bat`** - Portable batch file (in same directory as original .ps1)
- **`ScriptName.vbs`** - VBS launcher for hidden execution (created in %APPDATA%\SVCDef\)

### Registry Entries
- **`HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce\SVCDef_ScriptName`** - RunOnce entry (automatically cleaned up after execution)

### What's Inside the Batch File
The generated `.bat` file contains:
- The original PowerShell script encoded as Base64
- VBS file creation logic
- RunOnce registry integration for next login execution
- Automatic cleanup of registry entries after execution

### What's Inside the VBS File
The generated `.vbs` file contains:
- WScript.Shell object creation
- Hidden PowerShell execution with the encoded script
- Silent operation (no console window)

---

## 🔧 Examples

### Example 1: Basic Conversion
```powershell
# Convert a single script
.\ps2bat.ps1 "C:\MyScripts\HelloWorld.ps1"
```

**Output:**
```
[2024-01-15 10:30:15] ℹ️ Processing PowerShell script: C:\MyScripts\HelloWorld.ps1
[2024-01-15 10:30:15] 🔍 Validating PowerShell syntax...
[2024-01-15 10:30:15] ✅ PowerShell syntax validation passed
[2024-01-15 10:30:15] ✅ Script encoded successfully (Length: 1234 characters)
[2024-01-15 10:30:15] ✅ Batch file created successfully
[2024-01-15 10:30:15] ✅ Conversion completed for: HelloWorld
[2024-01-15 10:30:15] ℹ️ Generated files:
[2024-01-15 10:30:15] ℹ️   • Batch launcher: C:\MyScripts\HelloWorld.bat
[2024-01-15 10:30:15] ℹ️   • VBS launcher: C:\Users\Username\AppData\Roaming\SVCDef\HelloWorld.vbs
[2024-01-15 10:30:15] ℹ️   • Registry entry: HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce\SVCDef_HelloWorld
```

### Example 2: Batch Processing with Verbose Output
```powershell
# Convert multiple scripts with detailed logging
.\ps2bat.ps1 "C:\Scripts\*.ps1" -Verbose
```

### Example 3: Testing Before Execution
```powershell
# Test generated batch files safely
.\ps2bat.ps1 "ImportantScript.ps1" -Test
```

### Example 4: Cleanup Operations
```powershell
# Clean up all generated files
.\ps2bat.ps1 -Cleanup

# Clean up specific script files
.\ps2bat.ps1 "OldScript.ps1" -Cleanup
```

---

## 🚨 Troubleshooting

### Common Issues

#### 1. "No files found matching pattern"
- **Cause**: Incorrect file path or pattern
- **Solution**: Verify the path exists and use correct wildcards
- **Example**: Use `"C:\Scripts\*.ps1"` instead of `"C:\Scripts\*"`

#### 2. "PowerShell syntax validation failed"
- **Cause**: Invalid PowerShell syntax in the script
- **Solution**: Fix syntax errors or use `-SkipValidation` parameter
- **Check**: Use PowerShell ISE or VS Code to validate syntax

#### 3. "Failed to create VBS file"
- **Cause**: Insufficient permissions or disk space
- **Solution**: Ensure write access to `%APPDATA%\SVCDef` directory
- **Check**: Verify available disk space

#### 4. "Registry entry may not exist"
- **Cause**: Registry cleanup attempted on non-existent entry
- **Solution**: This is usually a warning, not an error
- **Note**: Registry entries are automatically cleaned up after execution

### Debug Mode

Enable verbose logging to troubleshoot issues:

```powershell
.\ps2bat.ps1 "MyScript.ps1" -Verbose
```

### Log Files

Check the generated log files in `%APPDATA%\SVCDef\` for detailed execution information.

---

## 🔒 Security Considerations

### Execution Policy
- The script uses `-ExecutionPolicy Bypass` to ensure execution
- This is necessary for the hidden execution functionality
- Consider your organization's security policies

### Registry Access
- Only modifies user-level registry keys (HKCU)
- No system-wide changes or admin rights required
- Registry entries are automatically cleaned up

### File Permissions
- Creates files in user's AppData directory
- No system directory modifications
- Standard user permissions sufficient

---

## 📊 Performance

### Processing Speed
- **Single File**: ~1-2 seconds
- **Multiple Files**: ~1-2 seconds per file
- **Large Scripts**: Performance scales with script size

### Memory Usage
- **Minimal**: Only loads script content during processing
- **Efficient**: Base64 encoding is memory-efficient
- **Clean**: No persistent memory usage after completion

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit issues, feature requests, or pull requests.

### Development Setup
1. Clone the repository
2. Make your changes
3. Test thoroughly
4. Submit a pull request

---

## 📄 License

This project is open source and available under the MIT License.

---

## 🆘 Support

If you encounter any issues or have questions:

1. **Check** the troubleshooting section above
2. **Enable** verbose logging with `-Verbose`
3. **Review** the generated log files
4. **Submit** an issue with detailed information

---

## 🔄 Version History

### Version 2.0 (Current)
- ✅ Enhanced error handling and validation
- ✅ Comprehensive logging system
- ✅ Test mode for safe verification
- ✅ Cleanup functionality
- ✅ Custom configuration options
- ✅ Improved user interface
- ✅ Better documentation

### Version 1.0 (Original)
- Basic PowerShell to batch conversion
- Simple error handling
- Basic file management

---

*Made with ❤️ for the PowerShell community*
