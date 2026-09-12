# Changelog

All notable changes to this project are documented here.

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
