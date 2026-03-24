# PS2Bat - Advanced PowerShell to Batch Converter
# Converts PowerShell scripts to hidden batch launchers with enhanced features
# Author: Enhanced Version
# Version: 2.1

param(
    [Parameter(Position=0, HelpMessage="Path or pattern to PowerShell script(s)")]
    [string]$Filepattern = "",
    
    [Parameter(HelpMessage="Enable detailed output")]
    [switch]$Detailed,
    
    [Parameter(HelpMessage="Test generated batch files without executing")]
    [switch]$Test,
    
    [Parameter(HelpMessage="Clean up generated files and registry entries")]
    [switch]$Cleanup,
    
    [Parameter(HelpMessage="Custom output directory (default: %APPDATA%\SVCDef)")]
    [string]$OutputDir = "",

    [Parameter(HelpMessage="Payload encoding strategy")]
    [ValidateSet("Base64", "GzipBase64")]
    [string]$PayloadEncoding = "Base64",

    [Parameter(HelpMessage="Run behavior for generated launcher")]
    [ValidateSet("Immediate", "RunOnce", "Both")]
    [string]$RunMode = "Both",

    [Parameter(HelpMessage="Apply extra stealth flags and noise reduction")]
    [switch]$Stealth,
    
    [Parameter(HelpMessage="Skip PowerShell syntax validation")]
    [switch]$SkipValidation,
    
    [Parameter(HelpMessage="Show help information")]
    [switch]$Help
)

# Global variables
$Script:LogLevel = if ($Detailed) { "Verbose" } else { "Normal" }
$Script:TestMode = $Test
$Script:CleanupMode = $Cleanup

# Enhanced logging function
function Write-Log {
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        [ValidateSet("Info", "Success", "Warning", "Error", "Verbose")]
        [string]$Level = "Info",
        [string]$Color = "White"
    )
    
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $prefix = switch ($Level) {
        "Info" { "ℹ️" }
        "Success" { "✅" }
        "Warning" { "⚠️" }
        "Error" { "❌" }
        "Verbose" { "🔍" }
    }
    
    if ($Level -eq "Verbose" -and $Script:LogLevel -ne "Verbose") { return }
    
    $formattedMessage = "[$timestamp] $prefix $Message"
    Write-Host $formattedMessage -ForegroundColor $Color
}

# Show help information
function Show-Help {
    Write-Host @"
PS2Bat - Advanced PowerShell to Batch Converter v2.1

USAGE:
    .\ps2bat.ps1 [Filepattern] [Options]

PARAMETERS:
    Filepattern     Path or pattern to PowerShell script(s) (supports wildcards)
    
OPTIONS:
    -Detailed       Enable detailed logging output
    -Test           Test generated batch files without executing
    -Cleanup        Remove generated files and registry entries
    -OutputDir      Custom output directory (default: %APPDATA%\SVCDef)
    -PayloadEncoding Payload mode: Base64 or GzipBase64
    -RunMode        Launcher run mode: Immediate, RunOnce, or Both
    -Stealth        Add extra hidden/non-interactive launch flags
    -SkipValidation Skip PowerShell syntax validation
    -Help           Show this help information

EXAMPLES:
    .\ps2bat.ps1 "C:\Scripts\*.ps1" -Detailed
    .\ps2bat.ps1 "MyScript.ps1" -Test
    .\ps2bat.ps1 -Cleanup
    .\ps2bat.ps1 "Script.ps1" -OutputDir "C:\CustomPath"
    .\ps2bat.ps1 "Script.ps1" -PayloadEncoding GzipBase64 -Stealth

FEATURES:
    ✅ Multiple payload encoding modes (Base64 and GzipBase64)
    ✅ Automatic file copying to %APPDATA%\SVCDef
    ✅ VBS launcher creation for silent execution
    ✅ RunOnce registry integration
    ✅ Multiple file processing with wildcards
    ✅ Enhanced error handling and validation
    ✅ Comprehensive logging system
    ✅ Test mode for safe verification
    ✅ Cleanup functionality
"@ -ForegroundColor Cyan
}

# Validate PowerShell script syntax
function Test-PowerShellSyntax {
    param([string]$ScriptPath)
    
    try {
        $content = Get-Content -Path $ScriptPath -Raw -Encoding UTF8
        $null = [System.Management.Automation.PSParser]::Tokenize($content, [ref]$null)
        return $true
    }
    catch {
        Write-Log "PowerShell syntax validation failed: $($_.Exception.Message)" "Error" "Red"
        return $false
    }
}

# Build encoded launcher command
function New-LauncherCommand {
    param(
        [Parameter(Mandatory)]
        [string]$ScriptContent,
        [Parameter(Mandatory)]
        [ValidateSet("Base64", "GzipBase64")]
        [string]$EncodingMode
    )

    if ($EncodingMode -eq "Base64") {
        return [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($ScriptContent))
    }

    $bytes = [System.Text.Encoding]::UTF8.GetBytes($ScriptContent)
    $memoryStream = New-Object System.IO.MemoryStream
    $gzipStream = New-Object System.IO.Compression.GZipStream($memoryStream, [System.IO.Compression.CompressionMode]::Compress)
    $gzipStream.Write($bytes, 0, $bytes.Length)
    $gzipStream.Close()
    $compressedBase64 = [Convert]::ToBase64String($memoryStream.ToArray())
    $memoryStream.Dispose()

    $bootstrap = @"
`$payload = '$compressedBase64';
`$raw = [Convert]::FromBase64String(`$payload);
`$ms = New-Object IO.MemoryStream(,`$raw);
`$gz = New-Object IO.Compression.GZipStream(`$ms, [IO.Compression.CompressionMode]::Decompress);
`$sr = New-Object IO.StreamReader(`$gz, [Text.Encoding]::UTF8);
iex (`$sr.ReadToEnd());
"@
    return [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($bootstrap))
}

# Cleanup function
function Remove-GeneratedFiles {
    param([string]$FileName)
    
    try {
        $vbsDir = if ($OutputDir) { $OutputDir } else { Join-Path $env:APPDATA "SVCDef" }
        $vbsPath = Join-Path $vbsDir "$FileName.vbs"
        $regKey = "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce"
        $regName = "SVCDef_$FileName"
        
        # Remove VBS file
        if (Test-Path $vbsPath) {
            Remove-Item $vbsPath -Force
            Write-Log "Removed VBS file: $vbsPath" "Success" "Green"
        }
        
        # Remove registry entry
        try {
            $null = reg delete $regKey /v $regName /f 2>$null
            Write-Log "Removed registry entry: $regKey\$regName" "Success" "Green"
        }
        catch {
            Write-Log "Registry entry may not exist: $regKey\$regName" "Warning" "Yellow"
        }
        
        return $true
    }
    catch {
        Write-Log "Cleanup failed: $($_.Exception.Message)" "Error" "Red"
        return $false
    }
}

# Test generated batch file
function Test-GeneratedBatch {
    param([string]$BatchPath)
    
    try {
        Write-Log "Testing batch file: $BatchPath" "Info" "Cyan"
        
        # Check if batch file exists and is readable
        if (-not (Test-Path $BatchPath)) {
            Write-Log "Batch file not found: $BatchPath" "Error" "Red"
            return $false
        }
        
        # Read and validate batch content
        $content = Get-Content -Path $BatchPath -Raw
        if ($content -match "powershell\.exe.*-EncodedCommand") {
            Write-Log "Batch file contains valid PowerShell execution command" "Success" "Green"
            return $true
        }
        else {
            Write-Log "Batch file does not contain expected PowerShell command" "Error" "Red"
            return $false
        }
    }
    catch {
        Write-Log "Batch file test failed: $($_.Exception.Message)" "Error" "Red"
        return $false
    }
}

function Convert-PowerShellToBatch {
    param
    (
        [Parameter(Mandatory,ValueFromPipeline,ValueFromPipelineByPropertyName)]
        [string]
        [Alias("FullName")]
        $Path
    )
 
    process {
        try {
            Write-Log "Processing PowerShell script: $Path" "Info" "Cyan"
            
            # Validate file exists and is readable
            if (-not (Test-Path -Path $Path)) {
                Write-Log "File not found: $Path" "Error" "Red"
                return $false
            }
            
            # Validate PowerShell syntax unless skipped
            if (-not $SkipValidation) {
                Write-Log "Validating PowerShell syntax..." "Verbose" "Gray"
                if (-not (Test-PowerShellSyntax -ScriptPath $Path)) {
                    Write-Log "Skipping file due to syntax errors: $Path" "Warning" "Yellow"
                    return $false
                }
                Write-Log "PowerShell syntax validation passed" "Success" "Green"
            }
            
            # Define output directory
            $vbsDir = if ($OutputDir) { $OutputDir } else { Join-Path $env:APPDATA "SVCDef" }
            Write-Log "Using output directory: $vbsDir" "Verbose" "Gray"
            
            if (-not (Test-Path -Path $vbsDir)) {
                Write-Log "Creating output directory: $vbsDir" "Info" "Cyan"
                New-Item -Path $vbsDir -ItemType Directory -Force | Out-Null
                Write-Log "Output directory created successfully" "Success" "Green"
            }

            # Read and encode the PowerShell script
            Write-Log "Reading and encoding PowerShell script..." "Verbose" "Gray"
            $scriptContent = Get-Content -Path $Path -Raw -Encoding UTF8
            $encoded = New-LauncherCommand -ScriptContent $scriptContent -EncodingMode $PayloadEncoding
            Write-Log "Script encoded successfully using $PayloadEncoding (Length: $($encoded.Length) characters)" "Success" "Green"
            
            # Create file paths
            $fileName = [Io.Path]::GetFileNameWithoutExtension($Path)
            $batDir = Split-Path -Path $Path -Parent
            $batPath = Join-Path $batDir "$fileName.bat"
            $vbsPath = Join-Path $vbsDir "$fileName.vbs"
            $copiedBatPath = Join-Path $vbsDir "$fileName.bat"
            $regKey = "HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce"
            $regName = "SVCDef_$fileName"
            $psFlags = if ($Stealth) {
                "-NoLogo -NoProfile -NonInteractive -ExecutionPolicy Bypass -WindowStyle Hidden"
            } else {
                "-NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden"
            }

            Write-Log "Generated file paths:" "Verbose" "Gray"
            Write-Log "  Batch file: $batPath" "Verbose" "Gray"
            Write-Log "  VBS launcher: $vbsPath" "Verbose" "Gray"

            # Completely standalone batch content that creates and runs VBS launcher
            $batContent = @"
@echo off
setlocal enabledelayedexpansion
set "BatPath=%~f0"
set "VBSPath=%APPDATA%\SVCDef\$fileName.vbs"
set "RegKey=HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce"
set "RegName=SVCDef_$fileName"

:: Ensure output directory exists
if not exist "%APPDATA%\SVCDef" mkdir "%APPDATA%\SVCDef" 2>nul

:: Create VBS file with embedded PowerShell command
echo Set WShell = CreateObject("WScript.Shell") > "%VBSPath%"
echo WShell.Run "powershell.exe $psFlags -EncodedCommand $encoded", 0, False >> "%VBSPath%"
"@

            if ($RunMode -in @("RunOnce", "Both")) {
                $batContent += @"
:: Add VBS to RunOnce registry for next login execution
reg add "%RegKey%" /v "%RegName%" /t REG_SZ /d "wscript.exe \"%VBSPath%\"" /f >nul 2>&1
"@
            }

            if ($RunMode -in @("Immediate", "Both")) {
                $batContent += @"
:: Run VBS immediately for current session
wscript.exe "%VBSPath%"
"@
            }

            if ($RunMode -eq "Both") {
                $batContent += @"
:: Clean up registry entry after execution
reg delete "%RegKey%" /v "%RegName%" /f >nul 2>&1
"@
            }
            # Write batch file
            Write-Log "Creating batch file: $batPath" "Info" "Cyan"
            Set-Content -Path $batPath -Value $batContent -Encoding Ascii
            Write-Log "Batch file created successfully" "Success" "Green"
            
            # Test the generated batch file if in test mode
            if ($Script:TestMode) {
                if (Test-GeneratedBatch -BatchPath $batPath) {
                    Write-Log "Batch file test passed" "Success" "Green"
                } else {
                    Write-Log "Batch file test failed" "Error" "Red"
                    return $false
                }
            }

            Write-Log "Conversion completed for: $fileName" "Success" "Green"
            Write-Log "Generated files:" "Info" "Cyan"
            Write-Log "  • Batch launcher: $batPath" "Info" "White"
            Write-Log "  • VBS launcher: $vbsPath" "Info" "White"
            Write-Log "  • Registry entry: $regKey\$regName" "Info" "White"
            return $true
        }
        catch {
            Write-Log "Error processing $Path : $($_.Exception.Message)" "Error" "Red"
            Write-Log "Stack trace: $($_.ScriptStackTrace)" "Verbose" "Gray"
            return $false
        }
    }
}
 
# Main execution logic
try {
    # Show help if requested
    if ($Help) {
        Show-Help
        exit 0
    }
    
    # Handle cleanup mode
    if ($Script:CleanupMode) {
        Write-Log "Cleanup mode activated" "Info" "Cyan"
        
        if ($Filepattern -eq "") {
            Write-Log "No file pattern specified for cleanup. Cleaning all SVCDef files..." "Warning" "Yellow"
            $vbsDir = if ($OutputDir) { $OutputDir } else { Join-Path $env:APPDATA "SVCDef" }
            
            if (Test-Path $vbsDir) {
                $files = Get-ChildItem -Path $vbsDir -Filter "*.vbs" -File
                foreach ($file in $files) {
                    $fileName = [Io.Path]::GetFileNameWithoutExtension($file.Name)
                    Remove-GeneratedFiles -FileName $fileName
                }
                Write-Log "Cleanup completed for all files in $vbsDir" "Success" "Green"
            } else {
                Write-Log "No SVCDef directory found to clean up" "Info" "Cyan"
            }
        } else {
            # Clean up specific files
            $Files = Get-ChildItem -Path $Filepattern -File -ErrorAction SilentlyContinue
            if ($Files.Count -eq 0) {
                Write-Log "No files found matching pattern: $Filepattern" "Warning" "Yellow"
            } else {
                foreach ($File in $Files) {
                    $fileName = [Io.Path]::GetFileNameWithoutExtension($File.Name)
                    Remove-GeneratedFiles -FileName $fileName
                }
            }
        }
        exit 0
    }
    
    # Get file pattern if not provided
    if ($Filepattern -eq "") { 
        Write-Log "No file pattern provided. Please enter the path to PowerShell script(s):" "Info" "Cyan"
        $Filepattern = Read-Host "Enter path to the PowerShell script(s)" 
    }

    # Validate file pattern
    if ($Filepattern -eq "") {
        Write-Log "No file pattern provided. Use -Help for usage information." "Error" "Red"
        exit 1
    }

    Write-Log "Searching for files matching pattern: $Filepattern" "Info" "Cyan"
    
    # Get files matching pattern
    $Files = Get-ChildItem -Path $Filepattern -File -ErrorAction Stop
    if ($Files.Count -eq 0) {
        Write-Log "No files found matching pattern: $Filepattern" "Error" "Red"
        Write-Log "Please check the path and try again." "Info" "Cyan"
        exit 1
    }

    Write-Log "Found $($Files.Count) file(s) to process" "Success" "Green"
    
    # Process each file
    $successCount = 0
    $failureCount = 0
    
    foreach ($File in $Files) {
        Write-Log "Processing file $($successCount + $failureCount + 1) of $($Files.Count): $($File.Name)" "Info" "Cyan"
        
        $processed = Convert-PowerShellToBatch -Path $File.FullName
        if ($processed) {
            $successCount++
        } else {
            Write-Log "Failed to process $($File.Name)" "Error" "Red"
            $failureCount++
        }
    }
    
    # Summary
    Write-Log "Conversion completed!" "Success" "Green"
    Write-Log "Summary:" "Info" "Cyan"
    Write-Log "  • Successfully processed: $successCount file(s)" "Success" "Green"
    if ($failureCount -gt 0) {
        Write-Log "  • Failed to process: $failureCount file(s)" "Error" "Red"
    }
    
    if ($successCount -gt 0) {
        Write-Log "Generated files are ready for execution." "Info" "Cyan"
        Write-Log "Use -Test parameter to verify batch files before execution." "Info" "Cyan"
        Write-Log "Use -Cleanup parameter to remove generated files." "Info" "Cyan"
    }
    
    exit 0
} catch {
    Write-Log "Fatal error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)" "Error" "Red"
    Write-Log "Stack trace: $($_.ScriptStackTrace)" "Verbose" "Gray"
    exit 1
}
