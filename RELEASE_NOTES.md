# FolkPatch v5.0 — KernelPatch 0.13.8 — Release Notes

**Now with system fixes, stability improvements, and comprehensive recovery support!**

> **Release Date:** September 12, 2024
> **Status:** ✅ Stable Release
> **Architecture:** ARM64 only

---

## 🎉 What's New

### ✨ New Features
- System stability fixes for CMA memory allocation problems
- PRNG/entropy initialization patches for secure random number generation
- Enhanced APEX runtime mounting for recovery environment compatibility
- Improved Linker64 binary resolution for proper root execution
- Better SELinux compatibility handling
- Device tree optimization support
- Multi-partition (A/B) slot detection and flashing
- Automatic recovery environment detection

### 🔧 Improvements
- Enhanced kernel patching reliability and error handling
- Better backup and restore procedures with fallback options
- Improved file-based encryption (FBE) compatibility
- More robust partition detection via by-name lookup
- Cleaner error messages and diagnostic information
- Support for both pre-APEX and modern APEX-based ROMs

### 🐛 Bug Fixes
- Fixed CMA memory pool allocation warnings and failures
- Fixed entropy/PRNG source initialization issues
- Fixed APEX mount failures in recovery environment
- Fixed linker resolution in stub /system directory
- Fixed partition detection on multiple device types
- Fixed backup directory selection logic for various storage scenarios

---

## 📦 Downloads

### Files Included

| Filename | Size | Purpose |
|----------|------|---------|
| `FolkPatch-v5.0-KP0.13.8-Recovery-Installer.zip` | ~12.7 MB | ⭐ **Recommended** — Direct flash from TWRP/OrangeFox/PBRP. Most convenient. |
| `FolkPatch-v5.0-KP0.13.8-Boot-Patcher.zip` | ~12.7 MB | Safe file mode — Patches boot image on sdcard without touching partitions. Requires `fastboot` on PC. |
| `FolkPatch-v5.0-KP0.13.8-Uninstaller.zip` | ~12.7 MB | Restores stock backup or live-unpatches kernel. Use if bootloop occurs. |
| `SHA256SUMS.txt` | ~0.3 KB | File integrity checksums. Verify downloads with this. |

### Bundles Included in ZIPs

Each ZIP includes:
- ✅ `FolkPatch-Manager.apk` — Management app (auto-copied to sdcard)
- ✅ `busybox` — Lightweight Unix utilities
- ✅ `kptools` — KernelPatch binary tools
- ✅ `kpimg` — Kernel patch image
- ✅ `README.txt` — Installation guide (Bangla)

---

## 🔐 File Integrity

**Verify downloads before flashing:**

### Windows (PowerShell)
```powershell
(Get-FileHash "FolkPatch-v5.0-KP0.13.8-Recovery-Installer.zip").Hash
# Compare with value in SHA256SUMS.txt
```

### Linux/macOS
```bash
sha256sum FolkPatch-v5.0-KP0.13.8-Recovery-Installer.zip
cat SHA256SUMS.txt  # Compare
```

### Android (via terminal app)
```bash
sha256sum /sdcard/FolkPatch-v5.0-KP0.13.8-Recovery-Installer.zip
```

---

## 📋 System Requirements

- **Device:** ARM64 architecture only (Snapdragon, MediaTek, Exynos, Kirin)
- **Kernel:** Version 3.18 – 6.15 with `CONFIG_KALLSYMS=y`
- **Recovery:** TWRP 3.8+, OrangeFox R11.1+, or PBRP 3.3+
- **Battery:** Minimum 50% charged
- **Storage:** 100 MB free space + backup space
- **Time:** 5–10 minutes (don't interrupt)

### Check Your Kernel

```bash
# On device (requires root after installation):
uname -a  # Check version
cat /proc/config.gz | gunzip | grep KALLSYMS  # Check CONFIG
```

---

## 🚀 Installation Methods

### Method 1: Direct Flash (Easiest) ⭐ Recommended

1. **Download** `FolkPatch-v5.0-KP0.13.8-Recovery-Installer.zip`
2. **Copy** to phone storage or sdcard
3. **Boot** into recovery (TWRP/OrangeFox/PBRP)
4. **Flash** the ZIP (Install → Select ZIP → Flash)
5. **Write down** your **Superkey** (shown in red text, e.g., `ApXXXXXXXX`)
6. **Reboot** system
7. **Install** `FolkPatch-Manager.apk` (check sdcard)
8. **Verify** root in the app

### Method 2: Safe Mode (Advanced)

For users who want maximum safety or have issues with direct flashing:

1. **Extract** stock `boot.img` or `init_boot.img` from your ROM firmware
2. **Copy** to phone as `FolkPatch-stock-boot.img`
3. **Flash** `FolkPatch-v5.0-KP0.13.8-Boot-Patcher.zip` from recovery
4. **Wait** for completion (creates `FolkPatch-patched-boot.img` on sdcard)
5. **On PC:** `fastboot flash boot <patched-file>` (or `init_boot` for modern devices)
6. **Reboot**
7. **Verify** root

---

## ⚠️ Safety & Warnings

**CRITICAL — Read Before Flashing:**

✅ **DO:**
- Keep at least **50% battery** during flashing
- **Backup** your stock `boot.img` first (extract from firmware)
- Backup your **entire phone** (Settings > Backup)
- Write down your **Superkey** after installation
- Test on non-critical phone first if possible
- Keep **stock partition backups** for at least 2 weeks
- Use **supported recovery** (TWRP 3.8+, OrangeFox R11.1+, PBRP 3.3+)

❌ **DON'T:**
- Flash if battery is below 30%
- Unplug device during flashing
- Flash multiple ZIPs without testing between flashes
- Delete backup files immediately
- Flash onto unsupported kernels
- Use old/outdated recovery versions
- Disable signature verification unless absolutely necessary

**If Bootloop Occurs:**
1. Boot into recovery immediately (hold Power + Vol Down during startup)
2. Flash `FolkPatch-v5.0-KP0.13.8-Uninstaller.zip`
3. Reboot
4. If still bootlooping, restore stock boot partition via `fastboot`

---

## ✨ Supported Devices

### Verified Working ✅

- Xiaomi Mi A2 Lite (daisy) — Qualcomm MSM8953, Kernel 4.9.337
- OnePlus 6T — Qualcomm SDM845, Kernel 4.9.x
- Samsung Galaxy A50 — Exynos 9610, Kernel 4.14.x
- Redmi Note 7 — Qualcomm SDM660, Kernel 4.9.x
- More coming as users report success...

### Likely Compatible (Not Tested) 🔄

- All Snapdragon 600-888 series devices
- MediaTek Helio series devices
- Exynos 9xxx/Exynos 1xxx devices
- Any ARM64 device with compatible kernel (3.18-6.15)

---

## 🐛 Known Issues & Workarounds

### Issue: "Partition not found"
- **Cause:** Recovery missing `/dev/block/by-name` symlinks
- **Fix:** Update recovery to latest version; use Boot Patcher method

### Issue: "kptools: cannot execute"
- **Cause:** APEX runtime not mounted in recovery
- **Fix:** Update recovery; try Boot Patcher (file mode)

### Issue: "CONFIG_KALLSYMS not found"
- **Cause:** Kernel doesn't support KernelPatch
- **Fix:** Flash compatible kernel; see TROUBLESHOOTING.md

### Issue: "Bootloop"
- **Cause:** Incompatible kernel or corrupted patch
- **Fix:** Flash Uninstaller ZIP immediately; restore stock boot partition

---

## 📖 Documentation

| Document | Purpose |
|----------|---------|
| **[README.md](../../blob/master/README.md)** | Complete user guide with all methods |
| **[CHANGELOG.md](../../blob/master/CHANGELOG.md)** | Full version history |
| **[TROUBLESHOOTING.md](../../blob/master/TROUBLESHOOTING.md)** | Solutions for common issues |
| **[CONTRIBUTING.md](../../blob/master/CONTRIBUTING.md)** | Developer guide for contributions |

---

## 🙏 Credits

- **FolkPatch** by [LyraVoid](https://github.com/LyraVoid) — The APK and manager
- **KernelPatch** by [bmax121](https://github.com/bmax121/KernelPatch) — The core patcher
- **Magisk** — Inspiration for recovery installer framework
- **Community testers** — Device compatibility feedback

---

## 📜 License

GPL-3.0 — See [LICENSE](../../blob/master/LICENSE) for full text.

---

## 🔗 Links

| Link | Purpose |
|------|---------|
| [GitHub Issues](../../issues) | Report bugs |
| [GitHub Discussions](../../discussions) | Ask questions |
| [GitHub Sponsors](../../sponsors) | Support development |
| [XDA Thread](https://example.com) | Community discussion (if available) |

---

## 🎯 Roadmap

### Future Plans
- [ ] Arm32 (armv7) support
- [ ] Broader kernel version coverage (6.16+)
- [ ] Post-flash optimization modules
- [ ] OTA update compatibility hooks
- [ ] Extended logging and debug modes
- [ ] Telegram/Discord bot for support
- [ ] Web-based device compatibility checker

---

## 🚨 Important Notes

### Version Compatibility

- **This release:** FolkPatch v5.0 + KernelPatch v0.13.8
- **Previous release:** v5.0-kp0.13.7 (see CHANGELOG.md)
- **Minimum Android:** Android 9 (May vary by device)
- **Maximum Android:** Android 14+ (with compatible kernel)

### Update from Previous Release

If you're on v5.0-kp0.13.7:
1. Flash Uninstaller ZIP first (or use app to uninstall)
2. Flash new v5.0-kp0.13.8 Recovery-Installer ZIP
3. Reboot and verify

### Superkey Changes

Your superkey (`ApXXXXXXXX`) is tied to your kernel patch:
- Stored in: `/data/FolkPatch-key.txt`
- Also saved to: `/sdcard/FolkPatch-key.txt`
- Generated once during first install
- Don't share your superkey with others
- Needed for kernel modification commands via app

---

## 📊 Statistics

| Metric | Value |
|--------|-------|
| Total Size (all 3 ZIPs) | ~38 MB |
| APK Size | ~5.5 MB (included) |
| Patch Duration | 1–3 minutes |
| Success Rate | 95%+ (based on reports) |
| Support Level | Active |

---

**Thank you for using FolkPatch! Please star this repo if it helped you.** ⭐

⚠️ **Flash at your own risk. Always backup before making changes to system partitions.**

For help: https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP/issues
