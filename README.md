# 🎥 Video Compressor

**Batch compress MP4 videos to save 40-70% disk space while keeping your originals safe.**

Works on any folder - perfect for OneDrive, external drives, or network shares. Outputs to a separate location with mirrored folder structure.

---

## 🚀 Quick Start

### 1. Install FFmpeg (one-time)

```powershell
winget install FFmpeg
```

### 2. Choose Your Method

| Method | Best For | How to Use |
|--------|----------|------------|
| **🎯 Folder Picker** | Beginners, one-time use | Double-click `Compress Videos.bat` |
| **🖱️ Right-Click Menu** | Regular use, multiple folders | Install via `install-context-menu.ps1` |
| **💻 Command Line** | Power users, automation | `.\compress-videos.ps1 -Path "C:\Videos"` |

---

## 💡 Common Use Cases

### Compress to Desktop (OneDrive Safe)

```powershell
.\compress-videos.ps1 `
  -Path "C:\Users\YourName\OneDrive\Videos" `
  -OutputDir "C:\Users\YourName\Desktop\CompressedVideos"
```

**What this does:**
- Reads from OneDrive (or any source)
- Outputs to Desktop with mirrored folder structure
- Avoids OneDrive sync conflicts
- Keeps originals safe

**Example:**
```
Source: OneDrive\Videos\2024\Vacation\video.mp4
Output: Desktop\CompressedVideos\2024\Vacation\video.mp4
```

### Compress in Place

```powershell
.\compress-videos.ps1 -Path "C:\LocalVideos"
```

Creates `*_compressed.mp4` files in the same folder.

### Test One File First

```powershell
.\test-single-file.ps1 -File "C:\Videos\test.mp4" -Quality medium
```

### Install Right-Click Menu

1. Right-click `install-context-menu.ps1`
2. "Run as Administrator"
3. Now right-click any folder → "Compress Videos Here"

---

## 🎚️ Quality Options

| Quality | CRF | Size Reduction | Visual Quality | Speed |
|---------|-----|----------------|----------------|-------|
| **low** | 28 | 50-70% | Noticeable | Fast |
| **medium** ⭐ | 23 | 40-60% | Excellent | Medium |
| **high** | 20 | 20-40% | Near-identical | Slow |

⭐ Recommended default

```powershell
# Maximum compression
.\compress-videos.ps1 -Path "C:\Videos" -Quality low

# Better quality
.\compress-videos.ps1 -Path "C:\Videos" -Quality high
```

---

## 🔧 All Options

```powershell
.\compress-videos.ps1 `
  -Path "C:\Source\Folder" `
  -OutputDir "C:\Output\Folder" `
  -Quality medium `
  [-NoRecursive] `
  [-DeleteOriginal]
```

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `-Path` | String | `.` | Source folder with videos |
| `-OutputDir` | String | `null` | Output folder (mirrors source structure) |
| `-Quality` | String | `medium` | `low` \| `medium` \| `high` |
| `-NoRecursive` | Switch | Off | Only process top folder (no subfolders) |
| `-DeleteOriginal` | Switch | Off | ⚠️ Delete source files after compression |

**Note:** When using `-OutputDir`, files are always kept in source location (no `_compressed` suffix).

---

## 📁 How Folder Structure Works

### With `-OutputDir` (Recommended)

```
Source: C:\Videos\
├── 2024\
│   ├── Vacation\
│   │   └── video.mp4          (100 MB)
│   └── Birthday\
│       └── party.mp4           (200 MB)

Output: C:\Compressed\
├── 2024\
│   ├── Vacation\
│   │   └── video.mp4          (40 MB) ← Compressed
│   └── Birthday\
│       └── party.mp4           (80 MB) ← Compressed
```

### Without `-OutputDir` (In-Place)

```
Before:
C:\Videos\
└── video.mp4                   (100 MB)

After:
C:\Videos\
├── video.mp4                   (100 MB) ← Original
└── video_compressed.mp4        (40 MB)  ← New
```

---

## 🛡️ Safety Features

| Feature | Status |
|---------|--------|
| **Keeps originals** | ✅ Always (unless `-DeleteOriginal` used) |
| **Skips processed** | ✅ Won't re-compress existing outputs |
| **Fail-safe** | ✅ Originals kept if compression fails |
| **Progress tracking** | ✅ Real-time per-file updates |
| **OneDrive compatible** | ✅ Use `-OutputDir` to avoid conflicts |

---

## 📊 Example Output

```
Video Compression Settings:
  Quality: medium - Balanced quality/size (recommended)
  CRF: 23 | Preset: medium
  Recursive: True
  Keep originals: True (creates _compressed.mp4 files)
  Output directory: C:\Users\Me\Desktop\CompressedVideos (mirrored structure)

Found 372 video(s) to compress

[1/372] Processing: Videos 2008\Zac and David's Podcast\video.mp4
  Compressing... Done!
  Original: 450.25 MB
  Compressed: 180.10 MB
  Saved: 270.15 MB (60.0%)
  Original kept in source location

...

==================================================
SUMMARY
==================================================
Files processed: 372
Total original size: 125,450 MB (122.5 GB)
Total compressed size: 50,180 MB (49.0 GB)
Total saved: 75,270 MB (73.5 GB) - 60.0%
==================================================
```

---

## 🚀 Advanced Usage

### Batch Multiple Folders

```powershell
$folders = @(
    "C:\Videos\2024",
    "C:\Videos\2023",
    "C:\Videos\2022"
)

foreach ($folder in $folders) {
    .\compress-videos.ps1 -Path $folder -OutputDir "C:\Compressed"
}
```

### Scheduled Compression

```powershell
# Create a scheduled task that runs weekly
$action = New-ScheduledTaskAction `
  -Execute "PowerShell.exe" `
  -Argument "-ExecutionPolicy Bypass -File C:\Tools\compress-videos.ps1 -Path C:\Videos -OutputDir C:\Compressed"

$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 2am

Register-ScheduledTask `
  -TaskName "Weekly Video Compression" `
  -Action $action `
  -Trigger $trigger
```

### Add to Windows PATH

1. Move folder to: `C:\Tools\video-compressor`
2. Add to PATH:
   - Win+X → System → Advanced → Environment Variables
   - User variables → Path → Edit → New
   - Add: `C:\Tools\video-compressor`

Then run from anywhere:
```powershell
compress-videos.ps1 -Path "C:\Any\Folder" -OutputDir "C:\Output"
```

---

## 📝 Files Included

| File | Purpose |
|------|---------|
| `compress-videos.ps1` | Main compression script |
| `Compress Videos.bat` | Folder picker launcher (easiest) |
| `compress-any-folder.ps1` | Folder picker backend |
| `compress-videos-here.bat` | Compress current directory |
| `test-single-file.ps1` | Test on one video |
| `install-context-menu.ps1` | Add right-click menu |
| `README.md` | This file |
| `.gitignore` | Git ignore rules |

---

## ❓ Troubleshooting

### FFmpeg not installed

```powershell
winget install FFmpeg
```

Or download from: https://ffmpeg.org/download.html

### "Cannot run scripts" error

```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### OneDrive sync conflicts

Use `-OutputDir` to output to a non-OneDrive location:

```powershell
.\compress-videos.ps1 `
  -Path "C:\Users\Me\OneDrive\Videos" `
  -OutputDir "C:\Users\Me\Desktop\Compressed"
```

### Videos look too compressed

```powershell
.\compress-videos.ps1 -Path "C:\Videos" -Quality high
```

### Script is slow

- Use `-Quality low` for faster encoding
- Close CPU-intensive programs
- Video encoding is CPU-intensive (normal)
- Consider running overnight for large collections

### Context menu not appearing

1. Did you run `install-context-menu.ps1` as Administrator?
2. Log out and back in
3. Check Registry: `HKEY_CLASSES_ROOT\Directory\shell\CompressVideos`

### Uninstall context menu

```powershell
.\install-context-menu.ps1 -Uninstall
```

---

## 🤔 FAQ

**Q: Will this delete my original videos?**  
A: No by default. Only if you explicitly use `-DeleteOriginal` flag.

**Q: Do I need to move my videos?**  
A: No! Use `-OutputDir` to compress to a different location.

**Q: Will this reduce quality?**  
A: Slightly, but most people won't notice with medium/high settings. Test first!

**Q: What formats are supported?**  
A: Currently only MP4 input files. Output is always MP4 (H.264 + AAC).

**Q: Can I stop mid-compression?**  
A: Yes, press Ctrl+C. Already compressed files won't be re-processed.

**Q: How long does this take?**  
A: ~1-5 minutes per GB on modern CPUs. 372 videos ≈ 6-12 hours.

**Q: Can I use this on external drives?**  
A: Yes! Works on local, USB, network, and cloud drives.

**Q: Why use `-OutputDir`?**  
A: Avoids OneDrive sync conflicts, keeps source clean, easier to review before deleting originals.

---

## 🔍 Technical Details

### FFmpeg Command

```bash
ffmpeg -i input.mp4 \
  -c:v libx264 \           # H.264 video codec
  -crf 23 \                # Quality (lower = better)
  -preset medium \         # Encoding speed
  -c:a aac \               # AAC audio codec
  -b:a 128k \              # Audio bitrate
  -movflags +faststart \   # Web streaming optimization
  output.mp4
```

### Why These Settings?

- **H.264** - Universal compatibility
- **CRF 23** - Visually transparent for most content
- **AAC 128k** - Transparent audio quality
- **medium preset** - Balanced speed/compression

### How It Works

1. Recursively scans source folder for `*.mp4` files
2. Creates mirrored folder structure in output (if `-OutputDir` used)
3. Encodes each video with FFmpeg
4. Tracks progress and calculates space savings
5. Skips files that already exist in output

---

**Video Compressor** | Save disk space safely and easily | v1.0
