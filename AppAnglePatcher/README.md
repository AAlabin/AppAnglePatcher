# App Angle Patcher

A macOS utility to fix red/black screen issues in applications by automatically patching them with the `--use-angle=gl` flag, forcing OpenGL rendering through ANGLE.

## 🚀 Quick Start

1. **Download** the latest `AppAnglePatcher.app` from [Releases](https://github.com/AAlabin/AppAnglePatcher/releases)
2. **Right-click → Open** (first time only to bypass Gatekeeper)
3. **Select applications** and click "Patch App"
4. **Find patched apps** in your `Downloads` folder
5. **Right-click → Open** each patched app first time

## 🎯 What It Solves

Fixes rendering issues in Electron/Chromium-based apps like:
- Red/black screens in Discord, Slack, WhatsApp
- Rendering glitches in VS Code, Chrome-based browsers  
- GPU compatibility issues on macOS
- Graphical artifacts in Yandex applications

## ⚙️ How It Works

Based on the solution by [khronokernel](https://gist.github.com/khronokernel/122dc28114d3a3b1673fa0423b5a9b39), this tool:

1. Creates a copy of the original application in your Downloads folder
2. Replaces the executable with a wrapper script
3. Adds `--use-angle=gl` flag to launch parameters
4. Preserves the original executable as `*.original` backup
5. Maintains application functionality while fixing rendering

## 📦 Installation

### GUI Version (Recommended)
```bash
# Download AppAnglePatcher.app from Releases
# Move to Applications folder
# Right-click → Open (first time)
# Grant Full Disk Access if needed for system apps
```
## 💻 Python Script (Alternative)

# Clone repository
git clone https://github.com/AAlabin/AppAnglePatcher.git
cd AppAnglePatcher/PythonScript

# Run patcher
python3 AppAnglePatcher.py
