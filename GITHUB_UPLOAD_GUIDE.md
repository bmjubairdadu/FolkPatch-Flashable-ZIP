# GitHub Release Upload Guide

This document guides you through uploading the FolkPatch Flashable ZIP to GitHub Releases.

## Files to Upload

From `dist/` folder:
- ✅ `FolkPatch-v5.0-KP0.13.8-Recovery-Installer.zip` (12.7 MB)
- ✅ `FolkPatch-v5.0-KP0.13.8-Boot-Patcher.zip` (12.7 MB)
- ✅ `FolkPatch-v5.0-KP0.13.8-Uninstaller.zip` (12.7 MB)
- ✅ `SHA256SUMS.txt` (checksums for verification)

## Method 1: GitHub Web UI (Easiest)

1. **Navigate to Releases:**
   - Go to: https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP/releases
   - Click "Create a new release"

2. **Fill in Release Details:**
   - **Tag version:** `v5.0-kp0.13.8`
   - **Release title:** `FolkPatch v5.0 - KernelPatch 0.13.8 - Complete Flashable ZIP`
   - **Description:** Use the content from `RELEASE_NOTES.md` (see below)

3. **Upload Files:**
   - Click "Attach binaries by dropping them here..."
   - Drag and drop all 4 files from `dist/` folder
   - Or click to select files manually

4. **Publish:**
   - Check "Set as the latest release"
   - Check "Create a discussion for this release"
   - Click "Publish release"

## Method 2: GitHub CLI (Recommended for Automation)

**Prerequisites:**
```bash
# Install GitHub CLI
# Windows: choco install gh
# macOS: brew install gh
# Linux: sudo apt install gh

# Authenticate
gh auth login
# Follow prompts, select "HTTPS", use personal access token
```

**Upload:**
```bash
cd d:\FolkPatch-Flashable-ZIP
git tag v5.0-kp0.13.8
git push origin v5.0-kp0.13.8

# Create release with files
gh release create v5.0-kp0.13.8 \
  --title "FolkPatch v5.0 - KernelPatch 0.13.8" \
  --notes "See CHANGELOG.md for details" \
  dist/FolkPatch-*.zip \
  dist/SHA256SUMS.txt
```

## Method 3: Git + Push (Manual)

```bash
cd d:\FolkPatch-Flashable-ZIP

# Create git tag
git tag v5.0-kp0.13.8

# Push tag to GitHub
git push origin v5.0-kp0.13.8

# Then use Web UI to create release and attach files
```

## Release Notes Template

Copy this into the release description on GitHub:

```markdown
# FolkPatch v5.0 — KernelPatch 0.13.8 — Complete Root & Kernel Patcher

**Now with system fixes, stability improvements, and comprehensive recovery support!**

## What's New

### New Features
- ✨ System stability fixes for CMA memory allocation
- ✨ PRNG/entropy initialization patches  
- ✨ Enhanced APEX runtime mounting for recovery environment
- ✨ Improved Linker64 binary resolution
- ✨ Better SELinux compatibility handling
- ✨ Device tree optimization support
- ✨ Multi-partition (A/B) slot detection
- ✨ Recovery environment auto-detection

### Improvements
- 🔧 Enhanced kernel patching reliability
- 🔧 Better backup and restore procedures
- 🔧 Improved file-based encryption (FBE) compatibility
- 🔧 More robust partition detection via by-name lookup
- 🔧 Cleaner error messages and diagnostics

### Fixes
- 🐛 Fixed CMA memory pool allocation warnings
- 🐛 Fixed entropy source initialization
- 🐛 Fixed APEX mount failures in recovery
- 🐛 Fixed linker resolution in stub /system
- 🐛 Fixed partition detection on multiple devices

## Download

| File | Size | Purpose |
|------|------|---------|
| **FolkPatch-v5.0-KP0.13.8-Recovery-Installer.zip** | 12.7 MB | ⭐ Recommended — Direct flash from recovery |
| **FolkPatch-v5.0-KP0.13.8-Boot-Patcher.zip** | 12.7 MB | Safe mode — Patch files on sdcard, flash via fastboot |
| **FolkPatch-v5.0-KP0.13.8-Uninstaller.zip** | 12.7 MB | Restore stock or live-unpatch kernel |
| **SHA256SUMS.txt** | ~0.3 KB | Verify file integrity |

## Verification

Verify download integrity:
```bash
# On Windows (PowerShell):
(Get-FileHash "FolkPatch-v5.0-KP0.13.8-Recovery-Installer.zip").Hash

# On Linux/Mac:
sha256sum FolkPatch-v5.0-KP0.13.8-Recovery-Installer.zip

# Compare with SHA256SUMS.txt
```

## Quick Start

**Method 1: Direct Flash (Easiest)**
1. Copy ZIP to sdcard
2. Boot into TWRP/OrangeFox/PBRP
3. Install → Flash ZIP
4. Reboot → Install Manager APK
5. Verify root in app

**Method 2: Safe Mode (Advanced)**
1. Extract stock `boot.img` from firmware
2. Flash Boot-Patcher ZIP from recovery
3. Use `fastboot flash boot <patched-image>` on PC
4. Reboot → Verify

## Requirements

- **ARM64 device** (32-bit ARM not supported)
- **Kernel 3.18 – 6.15** with `CONFIG_KALLSYMS=y`
- **Custom recovery:** TWRP 3.8+, OrangeFox R11.1+, PBRP 3.3+
- **50%+ battery** during flashing
- **Stock backup** before first flash (recommended)

## System Support

Tested/Confirmed working on:
- ✅ Qualcomm Snapdragon 600-888 series
- ✅ MediaTek Helio series
- ✅ Exynos devices
- ✅ Android 9 – 14
- ✅ A/B slot devices
- ✅ A-only devices

## Documentation

- 📖 **[README.md](https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP)** — Full guide
- 📋 **[CHANGELOG.md](https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP/blob/master/CHANGELOG.md)** — Version history
- 🆘 **[TROUBLESHOOTING.md](https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP/blob/master/TROUBLESHOOTING.md)** — Common issues
- 🤝 **[CONTRIBUTING.md](https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP/blob/master/CONTRIBUTING.md)** — Dev guide

## Credits

- **FolkPatch** by [LyraVoid](https://github.com/LyraVoid)
- **KernelPatch** by [bmax121](https://github.com/bmax121/KernelPatch)
- **Recovery installer framework** inspired by Magisk

## License

GPL-3.0 — See [LICENSE](https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP/blob/master/LICENSE)

## Support

- 🐛 Report issues: https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP/issues
- 💬 Discussions: https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP/discussions
- ⭐ Star this project if it helps!

---

**⚠️ Always backup before flashing. Flash at your own risk.**
```

## Verifying Release on GitHub

After upload, verify:
1. Visit the release page
2. Confirm all 4 files are attached
3. Test download links work
4. Check file sizes match (should be ~12.7 MB each)
5. Verify SHA256SUMS.txt content is visible

## Automated CI/CD

When you push a tag, GitHub Actions automatically:
1. Builds the ZIPs from source
2. Uploads artifacts to release
3. Publishes release notes

Check `.github/workflows/build.yml` to see the automation.

## Troubleshooting Upload

**Issue: "File too large"**
- GitHub allows up to 2 GB per file (ZIPs are ~12 MB, no issue)

**Issue: "Tag already exists"**
- Delete and recreate: `git tag -d v5.0-kp0.13.8 && git push origin :v5.0-kp0.13.8`

**Issue: "Failed to authenticate"**
- Check GitHub CLI: `gh auth status`
- Re-authenticate: `gh auth login --reset`

**Issue: "Release already exists"**
- Use `gh release edit` to update existing release
- Or delete and recreate via Web UI

## Next Steps After Release

1. **Announce** on XDA forums, Reddit r/androiddev
2. **Update** GitHub project description with new release link
3. **Share** on relevant Discord/Telegram communities
4. **Monitor** issues and respond to user feedback
5. **Plan** next release version (v5.0-kp0.13.9, etc.)

---

For more help, see the official GitHub docs:
https://docs.github.com/en/repositories/releasing-projects-on-github
