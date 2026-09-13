# FolkPatch Flashable ZIP — Complete Root & Kernel Patcher

[![Build ZIPs](https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP/actions/workflows/build.yml/badge.svg)](https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/bmjubairdadu/FolkPatch-Flashable-ZIP)](https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP/releases)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)

**Flash FolkPatch root (KernelPatch) from custom recovery — just like Magisk, with system fixes included.**

[FolkPatch](https://github.com/LyraVoid/FolkPatch) (by LyraVoid, based on
[KernelPatch](https://github.com/bmax121/KernelPatch)) ships as an Android APK.
Renaming the `.apk` to `.zip` and flashing it in TWRP / OrangeFox / PBRP
**does not work** — a recovery-flashable ZIP needs `META-INF/com/google/android/update-binary`
plus POSIX-shell installer scripts, which a plain APK doesn't have.

This project provides **one universal flashable ZIP set — works on ALL
devices** (old boot-only phones AND new boot+init_boot phones):
- ✅ Direct kernel patching from recovery (root access via KernelPatch)
- ✅ **Boot-only universal** — official rule: kernel always lives in `boot`;
  `init_boot` is ramdisk-only and is NEVER flashed (no brick)
- ✅ System optimizations and fixes for stability
- ✅ A/B slot auto-detection
- ✅ Automatic backup before patching
- ✅ Full uninstaller for clean removal
- ✅ File-mode patcher (safe, PC-based patching)
- ✅ Recovery-compatible POSIX shell scripts
- ✅ Works with TWRP, OrangeFox, PBRP

> **Keywords:** FolkPatch flashable zip, FolkPatch TWRP, FolkPatch OrangeFox,
> FolkPatch recovery installer, KernelPatch flashable zip, root without Magisk,
> APatch alternative, FolkPatch boot patcher, FolkPatch uninstaller, system fixes

---

## Download

Get the ZIPs from the
[**Releases page**](https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP/releases)
(`v10.0-kp0.13.8`):

| File | What it does |
|---|---|
| `FolkPatch-v10.0-kp0.13.8-Recovery-Installer.zip` | ⭐ **Recommended — Direct flash = INSTANT ROOT** — ONE ZIP for ALL devices: patches & flashes `boot` (kernel lives here on every device, old or new) with REAL superkey **+ installs `/data/adb/apd` daemon in recovery** (app rule). Reboot -> install Manager APK -> Installed/Active. `init_boot` is NEVER touched. Easiest, no PC needed. |
| `FolkPatch-v10.0-kp0.13.8-Boot-Patcher.zip` | **Safe file mode (advanced)** — patches a stock `boot.img` file on your sdcard, **never touches partitions**. You then `fastboot flash boot` the patched image from a PC. |
| `FolkPatch-v10.0-kp0.13.8-Uninstaller.zip` | Restores the stock backup, removes daemon, or live-unpatches the kernel. |

Each ZIP also bundles the `FolkPatch-Manager.apk` (copied to sdcard on install)
and a `README.txt` (Bangla guide).

Verify integrity with the `SHA256SUMS.txt` attached to the release.

## Requirements

- **ARM64** device, kernel **3.18 – 6.15** with `CONFIG_KALLSYMS=y`
- Custom recovery: **TWRP / OrangeFox / PBRP** (ARM64 build)
- **50%+ battery** charged (flashing takes 2–5 minutes)
- **Stock backup** of `boot` partition (recommended)
- **Data backup** on computer or external storage
- If recovery shows a signature error, turn **off** "Zip signature verification"

## System Fixes & Enhancements

This release includes patches for:
- ✅ Kernel memory allocation stability (CMA pool optimization)
- ✅ PRNG/entropy initialization for secure operations  
- ✅ SELinux permission handling
- ✅ Device tree (DT) and hardware compatibility fixes
- ✅ APEX runtime mounting in recovery environment
- ✅ Linker64 binary resolution for proper root execution
- ✅ A/B slot detection and multi-partition support
- ✅ Recovery environment compatibility (TWRP, OrangeFox, PBRP)
- ✅ File-based encryption (FBE) compatibility
- ✅ Backup and restore reliability

## Features

| Feature | Status |
|---------|--------|
| A/B Slot Detection | ✅ Automatic |
| Universal target | ✅ boot-only (all devices) |
| Stock Image Backup | ✅ Before patch |
| Live Unpatch | ✅ Without backup |
| Superkey in kernel | ✅ Real key set (apd auth) |
| Recovery Compatibility | ✅ TWRP/OrangeFox/PBRP |
| Partition Detection | ✅ by-name lookup |
| APEX Mounting | ✅ For kptools runtime |
| Busybox Integration | ✅ Included |
| SHA256 Verification | ✅ Release checksums |

## Method 1 — Direct flash (Recovery Installer, ⭐ recommended)

1. Copy the Installer ZIP (and the APK) to sdcard.
2. Boot recovery → Install → flash
   `FolkPatch-v10.0-kp0.13.8-Recovery-Installer.zip`.
3. Flash → reboot. Screen-e **superkey** (`ApXXXXXXXX`) + **Daemon OK**
   dekhabe — kernel patched + `/data/adb/apd` installed = INSTANT ROOT
   (**app-e key entry deoar option nei**, app signature diye auto-verify kore).
4. Reboot → sdcard theke `FolkPatch-Manager.apk` (**ZIP-er official APK tai**,
   onno APK noy) install koro → app kholo → Installed/Active dekhabe.
   Ditiyo patch lagbe na — Superuser chaile Allow dio.
5. App **already installed**? Purono app uninstall kore ZIP-er official APK
   install koro (signature na mille auth hobe na).
6. Bootloop/freeze? Flash the **Uninstaller ZIP** or restore your stock image.

Freeze safety in this build: each A/B slot is patched from **its own** stock
(no cross-slot image copy), patched size is checked before flashing.

### Flash success kintu root nai? (checklist)

1. Recovery log-e **`ROOT ACTIVE on current slot`** ache kina dekho — na
   thakle flash asole partition-e atkani (vul target / flash blocked).
2. ZIP-er **official Manager APK** install korecho kina dekho — onno
   source-er APK (onno signature) hole auth hobe na, Not Installed
   dekhabe.
3. App-e `Installed/Active` na asle recovery log-er `Verify` line + app
   screenshot niye issue kholo.
4. OrangeFox/custom ROM-e majhe majhe age Uninstaller diye stock-e fire,
   reboot, tarpor abar flash korle kaaj kore.

## Method 2 — Safe (Boot Patcher + fastboot, advanced)

1. Put your **stock** `boot.img` (from your firmware) on
   sdcard, named:
   `FolkPatch-stock-boot.img`.
2. Flash `FolkPatch-v10.0-kp0.13.8-Boot-Patcher.zip` from recovery
   (it does **not** touch any partition).
3. It writes `FolkPatch-patched-boot.img` to sdcard.
4. On PC: `fastboot flash boot <file>`
   (on A/B devices flash the current slot, or both slots).
5. Reboot → install Manager APK → verify.

## Uninstall

Flash `FolkPatch-v10.0-kp0.13.8-Uninstaller.zip`.
If a stock backup (`FolkPatch-Backup/stock-*.img`) exists it is restored
automatically.

## How it works

- `META-INF/com/google/android/update-binary` — Magisk-style bootstrap:
  picks a writable tmp dir, bootstraps busybox, extracts the payload,
  selects the installer by ZIP name, then `exec`s it.
- `scripts/InstallFP.sh` — reads the live `boot` partition (boot-only,
  universal — `init_boot` is NEVER flashed),
  backs it up, `unpack → REAL-key patch (kptools -S, boot_patch.sh rule) → repack → flash`,
  then installs the userspace daemon in recovery (`/data/adb/apd` + bins + `fpd`, app rule) = INSTANT ROOT.
- `scripts/PatchOnly.sh` — same pipeline on a stock image file, no flashing.
- `scripts/UninstallFP.sh` — restores backup or live-unpatches (`kptools -u`), plus daemon cleanup.
- Recovery has no Android runtime (`/system/bin/linker64` is a dangling
  symlink because `/apex` isn't mounted), so the scripts mount the real
  `system` + `apex` and run the `kptools` binary directly with
  `LD_LIBRARY_PATH` set — never by invoking the linker manually.

## Build from source

No binaries are committed to this repo. The build script downloads the
official FolkPatch APK and packs the ZIPs:

```sh
python tools/build.py
# outputs dist/FolkPatch-v10.0-kp0.13.8-*.zip + SHA256SUMS.txt
```

Pushing a `v*` tag runs the same build in GitHub Actions and attaches the
ZIPs to the GitHub Release automatically.

## Credits & license

- **FolkPatch** by [LyraVoid](https://github.com/LyraVoid/FolkPatch),
  based on **KernelPatch** by [bmax121](https://github.com/bmax121/KernelPatch).
  Binaries (`kpimg`, `kptools`, `busybox`) and the Manager APK come from the
  official upstream release **FolkPatch v5.0 (KP-0.13.8)**.
- Installer scripts in this repo (`META-INF/…/update-binary`, `scripts/*.sh`)
  are original work, licensed **GPL-3.0** (see [LICENSE](LICENSE)) to match
  the upstream project.
- This is a community repackaging project, not affiliated with LyraVoid.
  If you like FolkPatch, please ⭐ the
  [upstream repo](https://github.com/LyraVoid/FolkPatch) too.

## বাংলা গাইড (সংক্ষেপে)

APK rename করে ZIP করলে flash হয় না — recovery-তে `update-binary` +
installer script লাগে, যা APK-তে থাকে না। এই repo সেই layer যোগ করেছে।

- **সহজ (recommended):** Recovery-Installer ZIP flash করো → superkey note
  করো (kernel-e set hoy; **app-e entry option nei**) → reboot →
  sdcard থেকে ZIP-er official Manager APK install করো → অ্যাপ খোলো →
  Installed/Active দেখাবে।
- **অ্যাপ আগে থেকে install থাকলে:** purono app uninstall kore ZIP-er official
  APK install koro (onno signature hole auth hobe na)।
- **নিরাপদ (advanced):** stock `boot.img` sdcard-তে
  `FolkPatch-stock-boot.img` নামে রাখো → Boot-Patcher ZIP flash করো →
  `FolkPatch-patched-boot.img` PC থেকে `fastboot flash` করো।
- Bootloop/freeze হলে Uninstaller ZIP flash করো বা stock img restore করো।
- Kernel-এ `CONFIG_KALLSYMS=y` না থাকলে root কাজ করবে না।
- ফ্রিজ/হঠাৎ power-off এড়াতে: প্রতিটা slot নিজের stock থেকে প্যাচ হয়, ভুল slot-এর
  image অন্য slot-এ লেখা হয় না, আর flash-এর আগে size check করা হয়।
