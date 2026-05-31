# 🎥 Video Compressor

Batch compress videos to save 40-70% disk space while keeping your originals safe.

Supports: MP4, MOV, AVI, MKV, WMV, FLV, WebM, M4V, 3GP, MPG, MPEG, M2V, OGV

---

## Quick Start

### Install FFmpeg (one-time)

```powershell
winget install FFmpeg
```

### Compress Videos

**Folder Picker (easiest):**
```
Double-click: Compress Videos.bat
```

**Command Line:**
```powershell
# Compress to separate folder (recommended)
.\compress-videos.ps1 -Path "C:\Videos" -OutputDir "C:\Compressed"

# Compress in place (creates *_compressed.mp4 files)
.\compress-videos.ps1 -Path "C:\Videos"

# Process limited number
.\compress-videos.ps1 -Path "C:\Videos" -MaxVideos 10

# Save timestamped log
.\compress-videos.ps1 -Path "C:\Videos" -LogOutput
```

**Right-Click Menu:**
```powershell
# Run as Administrator
.\install-context-menu.ps1

# Now: Right-click any folder → "Compress Videos Here"
```

---

## Options

```powershell
.\compress-videos.ps1 `
  -Path "C:\Videos" `
  -OutputDir "C:\Output" `
  -Quality medium `
  [-SafeMode $true] `
  [-NoRecursive] `
  [-DeleteOriginal] `
  [-MaxVideos 10] `
  [-LogOutput]
```

| Parameter | Default | Description |
|-----------|---------|-------------|
| `-Path` | `.` | Source folder |
| `-OutputDir` | `null` | Output folder (mirrors source structure) |
| `-Quality` | `medium` | `low` (50-70% savings) \| `medium` (40-60%) \| `high` (20-40%) |
| `-SafeMode` | `$true` | Two-pass compression: compress to temp, verify size, keep only if smaller |
| `-NoRecursive` | Off | Skip subfolders |
| `-DeleteOriginal` | Off | Delete source files after compression |
| `-MaxVideos` | 0 | Process up to N videos (0 = unlimited) |
| `-LogOutput` | Off | Create timestamped log file (e.g., `output_logs_2026-05-29_143022.txt`) |

---

## Safety Features

- ✅ **Safe Mode (enabled by default)**: Two-pass compression verifies files are smaller before keeping them
- ✅ Keeps originals by default
- ✅ Skips already compressed files
- ✅ Skips videos already below target bitrate
- ✅ Skips re-encoding H.264+AAC files (prevents generation loss)
- ✅ Auto-stops if disk space insufficient

### Safe Mode

Safe Mode compresses to a temporary file first, checks the size, and only keeps it if it's actually smaller than the original. This prevents the rare case where re-encoding makes a file larger.

**Disable for faster compression** (if you're confident in your settings):
```powershell
.\compress-videos.ps1 -Path "C:\Videos" -SafeMode $false
```

---

## Troubleshooting

**FFmpeg not installed:**
```powershell
winget install FFmpeg
```

**"Cannot run scripts":**
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

**Cloud sync conflicts (OneDrive, Dropbox, Google Drive):**

Move files out of cloud-synced folders before compressing. Cloud services can mark files as read-only during sync, causing FFmpeg permission errors.

Best practice:
1. Move videos to local folder (e.g., `C:\Temp\Videos`)
2. Compress them
3. Move compressed files back if desired

Or use `-OutputDir` to output to non-synced location.

**Uninstall right-click menu:**
```powershell
.\install-context-menu.ps1 -Uninstall
```

---

## FAQ

**Will this delete my videos?**  
No, unless you use `-DeleteOriginal`.

**Will this reduce quality?**  
Slightly. Most people won't notice with medium/high settings.

**Can I stop mid-compression?**  
Yes (Ctrl+C). Already compressed files won't be re-processed.

**What if I run out of disk space?**  
Script auto-checks before each video and stops safely if space is low.

**How long does this take?**  
~1-5 minutes per GB on modern CPUs.

---

**Video Compressor** | v1.0
