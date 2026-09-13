# Changelog

All notable changes to this project are documented here.

## [Unreleased] — auto-root + freeze fixes

### Fixed
- 🐛 **Wrong target fixed:** installer now patches `boot` first (kernel lives
  there on old and new devices). Patching `init_boot` gave no root and could
  cause freeze/reboot — now only a last-resort fallback.
- 🐛 **A/B freeze fixed:** inactive slot is patched from its **own** stock
  instead of copying the current slot's image (different kernels per slot
  caused freeze/bootloop on slot switch).
- 🐛 **App upgrade/key mismatch fixed:** patch sets both `skey` and `root-skey`
  to the same key, so the Manager app connects after install and keeps working
  after upgrade (already-installed app also detects the patch).
- 🐛 **Already-patched re-flash:** detects `patched=true` live image and warns
  instead of writing a mismatched key; PatchOnly refuses already-patched
  source files.
- 🐛 **Uninstaller cross-slot restore:** restores each slot from its matching
  backup; skips unknown key combos instead of flashing the wrong image.
- 🐛 Universal `dd` syntax (no `conv=notrunc,fsync`) so flashing works in all
  recoveries; block size checks before flash/restore.

### Added
- ✨ `vendor_kernel_boot` target support, `/proc/cmdline` slot detection
  (recovery `getprop` is often empty), platform `by-name` search.
- ✨ Battery warning below 25%, `gzip`-from-busybox fallback for repack.
- ✨ Manager APK + stock backup also staged in `Download/FolkPatch/` where the
  app expects them.

## [v5.0-kp0.13.8] — 2024-09-12

### Added
- ✨ System stability fixes for CMA memory allocation
- ✨ PRNG/entropy initialization patches  
- ✨ Enhanced APEX runtime mounting for recovery environment
- ✨ Improved Linker64 binary resolution
- ✨ Better SELinux compatibility handling
- ✨ Device tree optimization support
- ✨ Multi-partition (A/B) slot detection
- ✨ Recovery environment auto-detection

### Improved
- 🔧 Enhanced kernel patching reliability
- 🔧 Better backup and restore procedures
- 🔧 Improved file-based encryption (FBE) compatibility
- 🔧 More robust partition detection via by-name lookup
- 🔧 Cleaner error messages and diagnostics
- 🔧 Better handling of pre-apex and modern ROMs

### Fixed
- 🐛 Fixed CMA memory pool allocation warnings
- 🐛 Fixed entropy source initialization
- 🐛 Fixed APEX mount failures in recovery
- 🐛 Fixed linker resolution in stub /system
- 🐛 Fixed partition detection on multiple devices
- 🐛 Fixed backup directory selection logic

### Technical Details
- Base: FolkPatch v5.0
- KernelPatch: v0.13.8
- Kernel Support: 3.18 – 6.15
- Architecture: ARM64 only

## [Previous Versions]

### v5.0-kp0.13.8 (Previous Release)
- Initial FolkPatch flashable ZIP implementation
- Basic recovery installer support
- Boot patcher (file-safe mode)
- Uninstaller with backup restore

---

## Future Plans

- [ ] Arm32 (armv7) support
- [ ] Broader kernel version coverage (6.16+)
- [ ] Post-flash optimization modules
- [ ] OTA update compatibility hooks
- [ ] Extended logging and debug modes
- [ ] CI/CD improvements and binary caching
