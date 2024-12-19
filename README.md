# 🚀 Cursor Free Trial Reset Tool

<div align="center">

[![Release](https://img.shields.io/github/v/release/yuaotian/go-cursor-help?style=flat-square&logo=github&color=blue)](https://github.com/yuaotian/go-cursor-help/releases/latest)
[![License](https://img.shields.io/badge/license-MIT-blue.svg?style=flat-square&logo=bookstack)](https://github.com/yuaotian/go-cursor-help/blob/main/LICENSE)
[![Stars](https://img.shields.io/github/stars/yuaotian/go-cursor-help?style=flat-square&logo=github)](https://github.com/yuaotian/go-cursor-help/stargazers)

[English](#-english) | [中文](#-chinese)

<img src="https://ai-cursor.com/wp-content/uploads/2024/09/logo-cursor-ai-png.webp" alt="Cursor Logo" width="120"/>

</div>

# 🌟 English

### 📝 Description

Resets Cursor's free trial limitation when you see:

```
Too many free trial accounts used on this machine.
Please upgrade to pro. We have this limit in place
to prevent abuse. Please let us know if you believe
this is a mistake.
```

### 💻 System Support

**Windows** ✅ x64  
**macOS** ✅ Intel & M-series  
**Linux** ✅ x64 & ARM64

### 📥 Installation

#### Automatic Installation (Recommended)

**Linux/macOS**
```bash
curl -fsSL https://raw.githubusercontent.com/yuaotian/go-cursor-help/master/scripts/install.sh | sudo bash
```

**Windows** (Run PowerShell as Admin)
```powershell
irm https://raw.githubusercontent.com/yuaotian/go-cursor-help/master/scripts/install.ps1 | iex
```

The installation script will automatically:
- Request necessary privileges (sudo/admin)
- Close any running Cursor instances
- Backup existing configuration
- Install the tool
- Add it to system PATH
- Clean up temporary files

#### Manual Installation

1. Download the latest release for your system from the [releases page](https://github.com/yuaotian/go-cursor-help/releases)
2. Extract and run with administrator/root privileges:
   ```bash
   # Linux/macOS
   sudo ./cursor-id-modifier

   # Windows (PowerShell Admin)
   .\cursor-id-modifier.exe
   ```

#### Manual Configuration Method

1. Close Cursor completely
2. Navigate to the configuration file location:
   - Windows: `%APPDATA%\Cursor\User\globalStorage\storage.json`
   - macOS: `~/Library/Application Support/Cursor/User/globalStorage/storage.json`
   - Linux: `~/.config/Cursor/User/globalStorage/storage.json`
3. Create a backup of `storage.json`
4. Edit `storage.json` and update these fields with new random UUIDs:
   ```json
   {
     "telemetry.machineId": "generate-new-uuid",
     "telemetry.macMachineId": "generate-new-uuid",
     "telemetry.devDeviceId": "generate-new-uuid",
     "telemetry.sqmId": "generate-new-uuid",
     "lastModified": "2024-01-01T00:00:00.000Z",
     "version": "1.0.1"
   }
   ```
5. Save the file and restart Cursor

### 🔧 Technical Details

#### Configuration Files
The program modifies Cursor's `storage.json` config file located at:
- Windows: `%APPDATA%\Cursor\User\globalStorage\`
- macOS: `~/Library/Application Support/Cursor/User/globalStorage/`
- Linux: `~/.config/Cursor/User/globalStorage/`

#### Modified Fields
The tool generates new unique identifiers for:
- `telemetry.machineId`
- `telemetry.macMachineId`
- `telemetry.devDeviceId`
- `telemetry.sqmId`

#### Safety Features
- Automatic backup of existing configuration
- Safe process termination
- Atomic file operations
- Error handling and rollback

---

