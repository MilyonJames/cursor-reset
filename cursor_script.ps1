# Set output encoding to UTF-8
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Color definitions
$RED = "`e[31m"
$GREEN = "`e[32m"
$YELLOW = "`e[33m"
$BLUE = "`e[34m"
$NC = "`e[0m"

# Configuration file paths
$STORAGE_FILE = "$env:APPDATA\Cursor\User\globalStorage\storage.json"
$BACKUP_DIR = "$env:APPDATA\Cursor\User\globalStorage\backups"

# Check administrator privileges
function Test-Administrator {
    $user = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($user)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

if (-not (Test-Administrator)) {
    Write-Host "$RED[ERROR]$NC Please run this script as administrator"
    Write-Host "Right-click the script and select 'Run as administrator'"
    Read-Host "Press Enter to exit"
    exit 1
}

# Display Logo
Clear-Host
Write-Host @"

    ██████╗██╗   ██╗██████╗ ███████╗ ██████╗ ██████╗ 
   ██╔════╝██║   ██║██╔══██╗██╔════╝██╔═══██╗██╔══██╗
   ██║     ██║   ██║██████╔╝███████╗██║   ██║██████╔╝
   ██║     ██║   ██║██╔══██╗╚════██║██║   ██║██╔══██╗
   ╚██████╗╚██████╔╝██║  ██║███████║╚██████╔╝██║  ██║
    ╚═════╝ ╚═════╝ ╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═╝  ╚═╝

"@
Write-Host "$BLUE================================$NC"
Write-Host "$GREEN   Cursor Device ID Modifier Tool   $NC"
Write-Host "$YELLOW  Cursor ID Reset Tool - Community Edition $NC"
Write-Host "$YELLOW  Free tool for Cursor device ID management  $NC"
Write-Host "$YELLOW  [IMPORTANT] This is a free community tool  $NC"
Write-Host "$BLUE================================$NC"
Write-Host ""

# Get and display Cursor version
function Get-CursorVersion {
    try {
        # Main detection path
        $packagePath = "$env:LOCALAPPDATA\Programs\cursor\resources\app\package.json"
        
        if (Test-Path $packagePath) {
            $packageJson = Get-Content $packagePath -Raw | ConvertFrom-Json
            if ($packageJson.version) {
                Write-Host "$GREEN[INFO]$NC Current Cursor version: v$($packageJson.version)"
                return $packageJson.version
            }
        }

        # Alternative path detection
        $altPath = "$env:LOCALAPPDATA\cursor\resources\app\package.json"
        if (Test-Path $altPath) {
            $packageJson = Get-Content $altPath -Raw | ConvertFrom-Json
            if ($packageJson.version) {
                Write-Host "$GREEN[INFO]$NC Current Cursor version: v$($packageJson.version)"
                return $packageJson.version
            }
        }

        Write-Host "$YELLOW[WARNING]$NC Unable to detect Cursor version"
        Write-Host "$YELLOW[TIP]$NC Please ensure Cursor is properly installed"
        return $null
    }
    catch {
        Write-Host "$RED[ERROR]$NC Failed to get Cursor version: $_"
        return $null
    }
}

# Get version information
$cursorVersion = Get-CursorVersion
Write-Host ""

Write-Host "$YELLOW[IMPORTANT NOTE]$NC Latest 0.45.x (supported)"
Write-Host ""

# Check and close Cursor processes
Write-Host "$GREEN[INFO]$NC Checking Cursor processes..."

function Get-ProcessDetails {
    param($processName)
    Write-Host "$BLUE[DEBUG]$NC Getting process details for $processName:"
    Get-WmiObject Win32_Process -Filter "name='$processName'" | 
        Select-Object ProcessId, ExecutablePath, CommandLine | 
        Format-List
}

# Define maximum retries and wait time
$MAX_RETRIES = 5
$WAIT_TIME = 1

# Handle process termination
function Close-CursorProcess {
    param($processName)
    
    $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
    if ($process) {
        Write-Host "$YELLOW[WARNING]$NC Found $processName running"
        Get-ProcessDetails $processName
        
        Write-Host "$YELLOW[WARNING]$NC Attempting to close $processName..."
        Stop-Process -Name $processName -Force
        
        $retryCount = 0
        while ($retryCount -lt $MAX_RETRIES) {
            $process = Get-Process -Name $processName -ErrorAction SilentlyContinue
            if (-not $process) { break }
            
            $retryCount++
            if ($retryCount -ge $MAX_RETRIES) {
                Write-Host "$RED[ERROR]$NC Unable to close $processName after $MAX_RETRIES attempts"
                Get-ProcessDetails $processName
                Write-Host "$RED[ERROR]$NC Please close the process manually and try again"
                Read-Host "Press Enter to exit"
                exit 1
            }
            Write-Host "$YELLOW[WARNING]$NC Waiting for process to close, attempt $retryCount/$MAX_RETRIES..."
            Start-Sleep -Seconds $WAIT_TIME
        }
        Write-Host "$GREEN[INFO]$NC $processName successfully closed"
    }
}

# Close all Cursor processes
Close-CursorProcess "Cursor"
Close-CursorProcess "cursor"

# Create backup directory
if (-not (Test-Path $BACKUP_DIR)) {
    New-Item -ItemType Directory -Path $BACKUP_DIR | Out-Null
}

# Backup existing configuration
if (Test-Path $STORAGE_FILE) {
    Write-Host "$GREEN[INFO]$NC Backing up configuration file..."
    $backupName = "storage.json.backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
    Copy-Item $STORAGE_FILE "$BACKUP_DIR\$backupName"
}

# Generate new ID
Write-Host "$GREEN[INFO]$NC Generating new ID..."

function Get-RandomHex {
    param (
        [int]$length
    )
    
    $bytes = New-Object byte[] ($length)
    $rng = [System.Security.Cryptography.RNGCryptoServiceProvider]::new()
    $rng.GetBytes($bytes)
    $hexString = [System.BitConverter]::ToString($bytes) -replace '-',''
    $rng.Dispose()
    return $hexString
}

function New-StandardMachineId {
    $template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
    $result = $template -replace '[xy]', {
        param($match)
        $r = [Random]::new().Next(16)
        $v = if ($match.Value -eq "x") { $r } else { ($r -band 0x3) -bor 0x8 }
        return $v.ToString("x")
    }
    return $result
}

# Generate IDs
$MAC_MACHINE_ID = New-StandardMachineId
$UUID = [System.Guid]::NewGuid().ToString()
$prefixBytes = [System.Text.Encoding]::UTF8.GetBytes("auth0|user_")
$prefixHex = -join ($prefixBytes | ForEach-Object { '{0:x2}' -f $_ })
$randomPart = Get-RandomHex -length 32
$MACHINE_ID = "$prefixHex$randomPart"
$SQM_ID = "{$([System.Guid]::NewGuid().ToString().ToUpper())}"

# Check administrator privileges
if (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {
    Write-Host "$RED[ERROR]$NC Please run this script with administrator privileges"
    Start-Process powershell "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

function Update-MachineGuid {
    try {
        $registryPath = "HKLM:\SOFTWARE\Microsoft\Cryptography"
        if (-not (Test-Path $registryPath)) {
            throw "Registry path does not exist: $registryPath"
        }

        $currentGuid = Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction Stop
        if (-not $currentGuid) {
            throw "Unable to get current MachineGuid"
        }

        $originalGuid = $currentGuid.MachineGuid
        Write-Host "$GREEN[INFO]$NC Current registry value:"
        Write-Host "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography" 
        Write-Host "    MachineGuid    REG_SZ    $originalGuid"

        if (-not (Test-Path $BACKUP_DIR)) {
            New-Item -ItemType Directory -Path $BACKUP_DIR -Force | Out-Null
        }

        $backupFile = "$BACKUP_DIR\MachineGuid_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"
        $backupResult = Start-Process "reg.exe" -ArgumentList "export", "`"HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography`"", "`"$backupFile`"" -NoNewWindow -Wait -PassThru
        
        if ($backupResult.ExitCode -eq 0) {
            Write-Host "$GREEN[INFO]$NC Registry backup created at: $backupFile"
        } else {
            Write-Host "$YELLOW[WARNING]$NC Backup creation failed, continuing..."
        }

        $newGuid = [System.Guid]::NewGuid().ToString()
        Set-ItemProperty -Path $registryPath -Name MachineGuid -Value $newGuid -Force -ErrorAction Stop
        
        $verifyGuid = (Get-ItemProperty -Path $registryPath -Name MachineGuid -ErrorAction Stop).MachineGuid
        if ($verifyGuid -ne $newGuid) {
            throw "Registry verification failed: Updated value ($verifyGuid) doesn't match expected value ($newGuid)"
        }

        Write-Host "$GREEN[INFO]$NC Registry successfully updated:"
        Write-Host "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Cryptography"
        Write-Host "    MachineGuid    REG_SZ    $newGuid"
        return $true
    }
    catch {
        Write-Host "$RED[ERROR]$NC Registry operation failed: $($_.Exception.Message)"
        
        if ($backupFile -and (Test-Path $backupFile)) {
            Write-Host "$YELLOW[RECOVERY]$NC Attempting to restore from backup..."
            $restoreResult = Start-Process "reg.exe" -ArgumentList "import", "`"$backupFile`"" -NoNewWindow -Wait -PassThru
            
            if ($restoreResult.ExitCode -eq 0) {
                Write-Host "$GREEN[SUCCESS]$NC Original registry value restored"
            } else {
                Write-Host "$RED[ERROR]$NC Restore failed, please manually import backup file: $backupFile"
            }
        } else {
            Write-Host "$YELLOW[WARNING]$NC No backup file found or backup creation failed, cannot auto-restore"
        }
        return $false
    }
}

# Create or update configuration file
Write-Host "$GREEN[INFO]$NC Updating configuration..."

try {
    if (-not (Test-Path $STORAGE_FILE)) {
        Write-Host "$RED[ERROR]$NC Configuration file not found: $STORAGE_FILE"
        Write-Host "$YELLOW[TIP]$NC Please install and run Cursor once before using this script"
        Read-Host "Press Enter to exit"
        exit 1
    }

    try {
        $originalContent = Get-Content $STORAGE_FILE -Raw -Encoding UTF8
        $config = $originalContent | ConvertFrom-Json 

        $oldValues = @{
            'machineId' = $config.'telemetry.machineId'
            'macMachineId' = $config.'telemetry.macMachineId'
            'devDeviceId' = $config.'telemetry.devDeviceId'
            'sqmId' = $config.'telemetry.sqmId'
        }

        $config.'telemetry.machineId' = $MACHINE_ID
        $config.'telemetry.macMachineId' = $MAC_MACHINE_ID
        $config.'telemetry.devDeviceId' = $UUID
        $config.'telemetry.sqmId' = $SQM_ID

        $updatedJson = $config | ConvertTo-Json -Depth 10
        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($STORAGE_FILE), 
            $updatedJson, 
            [System.Text.Encoding]::UTF8
        )
        Write-Host "$GREEN[INFO]$NC Configuration file updated successfully"
    } catch {
        if ($originalContent) {
            [System.IO.File]::WriteAllText(
                [System.IO.Path]::GetFullPath($STORAGE_FILE), 
                $originalContent, 
                [System.Text.Encoding]::UTF8
            )
        }
        throw "JSON processing failed: $_"
    }

    Update-MachineGuid

    Write-Host ""
    Write-Host "$GREEN[INFO]$NC Configuration updated:"
    Write-Host "$BLUE[DEBUG]$NC machineId: $MACHINE_ID"
    Write-Host "$BLUE[DEBUG]$NC macMachineId: $MAC_MACHINE_ID"
    Write-Host "$BLUE[DEBUG]$NC devDeviceId: $UUID"
    Write-Host "$BLUE[DEBUG]$NC sqmId: $SQM_ID"

    Write-Host ""
    Write-Host "$GREEN[INFO]$NC File structure:"
    Write-Host "$BLUE$env:APPDATA\Cursor\User$NC"
    Write-Host "├── globalStorage"
    Write-Host "│   ├── storage.json (modified)"
    Write-Host "│   └── backups"

    $backupFiles = Get-ChildItem "$BACKUP_DIR\*" -ErrorAction SilentlyContinue
    if ($backupFiles) {
        foreach ($file in $backupFiles) {
            Write-Host "│       └── $($file.Name)"
        }
    } else {
        Write-Host "│       └── (empty)"
    }

    Write-Host ""
    Write-Host "$GREEN================================$NC"
    Write-Host "$YELLOW  Cursor ID Reset Tool - Community Edition  $NC"
    Write-Host "$GREEN================================$NC"
    Write-Host ""
    Write-Host "$GREEN[INFO]$NC Please restart Cursor to apply new configuration"
    Write-Host ""

    Write-Host ""
    Write-Host "$YELLOW[QUESTION]$NC Do you want to disable Cursor auto-updates?"
    Write-Host "0) No - Keep default settings (Press Enter)"
    Write-Host "1) Yes - Disable auto-updates"
    $choice = Read-Host "Enter option (0)"

    if ($choice -eq "1") {
        Write-Host ""
        Write-Host "$GREEN[INFO]$NC Processing auto-update settings..."
        $updaterPath = "$env:LOCALAPPDATA\cursor-updater"

        function Show-ManualGuide {
            Write-Host ""
            Write-Host "$YELLOW[WARNING]$NC Automatic setup failed, try manual steps:"
            Write-Host "$YELLOWManual steps to disable updates:$NC"
            Write-Host "1. Open PowerShell as Administrator"
            Write-Host "2. Copy and paste these commands:"
            Write-Host "$BLUECommand 1 - Delete existing directory (if exists):$NC"
            Write-Host "Remove-Item -Path `"$updaterPath`" -Force -Recurse -ErrorAction SilentlyContinue"
            Write-Host ""
            Write-Host "$BLUECommand 2 - Create blocking file:$NC"
            Write-Host "New-Item -Path `"$updaterPath`" -ItemType File -Force | Out-Null"
            Write-Host ""
            Write-Host "$BLUECommand 3 - Set read-only attribute:$NC"
            Write-Host "Set-ItemProperty -Path `"$updaterPath`" -Name IsReadOnly -Value `$true"
            Write-Host ""
            Write-Host "$BLUECommand 4 - Set permissions (optional):$NC"
            Write-Host "icacls `"$updaterPath`" /inheritance:r /grant:r `"`$($env:USERNAME):(R)`""
            Write-Host ""
            Write-Host "$YELLOWVerification steps:$NC"
            Write-Host "1. Run: Get-ItemProperty `"$updaterPath`""
            Write-Host "2. Confirm IsReadOnly is True"
            Write-Host "3. Run: icacls `"$updaterPath`""
            Write-Host "4. Confirm read-only permissions"
            Write-Host ""
            Write-Host "$YELLOW[TIP]$NC Restart Cursor after completion"
        }

        try {
            if (Test-Path $updaterPath) {
                try {
                    Remove-Item -Path $updaterPath -Force -Recurse -ErrorAction Stop
                    Write-Host "$GREEN[INFO]$NC Successfully removed cursor-updater directory"
                }
                catch {
                    Write-Host "$RED[ERROR]$NC Failed to remove cursor-updater directory"
                    Show-ManualGuide
                    return
                }
            }

            try {
                New-Item -Path $updaterPath -ItemType File -Force -ErrorAction Stop | Out-Null
                Write-Host "$GREEN[INFO]$NC Successfully created blocking file"
            }
            catch {
                Write-Host "$RED[ERROR]$NC Failed to create blocking file"
                Show-ManualGuide
                return
            }

            try {
                Set-ItemProperty -Path $updaterPath -Name IsReadOnly -Value $true -ErrorAction Stop
                
                $result = Start-Process "icacls.exe" -ArgumentList "`"$updaterPath`" /inheritance:r /grant:r `"$($env:USERNAME):(R)`"" -Wait -NoNewWindow -PassThru
                if ($result.ExitCode -ne 0) {
                    throw "icacls command failed"
                }
                
                Write-Host "$GREEN[INFO]$NC Successfully set file permissions"
            }
            catch {
                Write-Host "$RED[ERROR]$NC Failed to set file permissions"
                Show-ManualGuide
                return
            }

            try {
                $fileInfo = Get-ItemProperty $updaterPath
                if (-not $fileInfo.IsReadOnly) {
                    Write-Host "$RED[ERROR]$NC Verification failed: File permissions may not be effective"
                    Show-ManualGuide
                    return
                }
            }
            catch {
                Write-Host "$RED[ERROR]$NC Verification failed"
                Show-ManualGuide
                return
            }

            Write-Host "$GREEN[INFO]$NC Auto-updates successfully disabled"
        }
        catch {
            Write-Host "$RED[ERROR]$NC Unknown error occurred: $_"
            Show-ManualGuide
        }
    }
    else {
        Write-Host "$GREEN[INFO]$NC Keeping default settings, no changes made"
    }

    Update-MachineGuid

} catch {
    Write-Host "$RED[ERROR]$NC Main operation failed: $_"
    Write-Host "$YELLOW[ATTEMPT]$NC Trying alternative method..."
    
    try {
        $tempFile = [System.IO.Path]::GetTempFileName()
        $config | ConvertTo-Json | Set-Content -Path $tempFile -Encoding UTF8
        Copy-Item -Path $tempFile -Destination $STORAGE_FILE -Force
        Remove-Item -Path $tempFile
        Write-Host "$GREEN[INFO]$NC Configuration written successfully using alternative method"
    } catch {
        Write-Host "$RED[ERROR]$NC All attempts failed"
        Write-Host "Error details: $_"
        Write-Host "Target file: $STORAGE_FILE"
        Write-Host "Please ensure you have sufficient permissions to access this file"
        Read-Host "Press Enter to exit"
        exit 1
    }
}

Write-Host ""
Read-Host "Press Enter to exit"
exit 0

function Write-ConfigFile {
    param($config, $filePath)
    
    try {
        $utf8NoBom = New-Object System.Text.UTF8Encoding $false
        $jsonContent = $config | ConvertTo-Json -Depth 10
        $jsonContent = $jsonContent.Replace("`r`n", "`n")
        
        [System.IO.File]::WriteAllText(
            [System.IO.Path]::GetFullPath($filePath),
            $jsonContent,
            $utf8NoBom
        )
        
        Write-Host "$GREEN[INFO]$NC Configuration file written successfully (UTF8 no BOM)"
    }
    catch {
        throw "Failed to write configuration file: $_"
    }
}

function Compare-Version {
    param (
        [string]$version1,
        [string]$version2
    )
    
    try {
        $v1 = [version]($version1 -replace '[^\d\.].*$')
        $v2 = [version]($version2 -replace '[^\d\.].*$')
        return $v1.CompareTo($v2)
    }
    catch {
        Write-Host "$RED[ERROR]$NC Version comparison failed: $_"
        return 0
    }
}

Write-Host "$GREEN[INFO]$NC Checking Cursor version..."
$cursorVersion = Get-CursorVersion

if ($cursorVersion) {
    $compareResult = Compare-Version $cursorVersion "0.45.0"
    if ($compareResult -ge 0) {
        Write-Host "$RED[ERROR]$NC Current version ($cursorVersion) is not supported"
        Write-Host "$YELLOW[SUGGESTION]$NC Please use v0.44.11 or lower"
        Write-Host "$YELLOW[SUGGESTION]$NC Download supported versions from:"
        Write-Host "Windows: https://download.todesktop.com/230313mzl4w4u92/Cursor%20Setup%200.44.11%20-%20Build%20250103fqxdt5u9z-x64.exe"
        Write-Host "Mac ARM64: https://dl.todesktop.com/230313mzl4w4u92/versions/0.44.11/mac/zip/arm64"
        Read-Host "Press Enter to exit"
        exit 1
    }
    else {
        Write-Host "$GREEN[INFO]$NC Current version ($cursorVersion) supports reset functionality"
    }
}
else {
    Write-Host "$YELLOW[WARNING]$NC Unable to detect version, continuing execution..."
} 
