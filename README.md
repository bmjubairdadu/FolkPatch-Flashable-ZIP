# FolkPatch Flashable ZIP — Magisk-Style Recovery Installer

[![Build ZIPs](https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP/actions/workflows/build.yml/badge.svg)](https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP/actions/workflows/build.yml)
[![Release](https://img.shields.io/github/v/release/bmjubairdadu/FolkPatch-Flashable-ZIP)](https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP/releases)
[![License: GPL-3.0](https://img.shields.io/badge/License-GPL--3.0-blue.svg)](LICENSE)

**Flash FolkPatch root (KernelPatch) from custom recovery — just like Magisk.**

[FolkPatch](https://github.com/LyraVoid/FolkPatch) (by LyraVoid, based on
[KernelPatch](https://github.com/bmax121/KernelPatch)) ships as an Android APK.
Renaming the `.apk` to `.zip` and flashing it in TWRP / OrangeFox / PBRP
**does not work** — a recovery-flashable ZIP needs `META-INF/com/google/android/update-binary`
plus POSIX-shell installer scripts, which a plain APK doesn't have.
(Magisk's APK flashes because it is a *hybrid* APK+ZIP; FolkPatch's APK is not.)

This project adds that missing recovery layer: **Magisk-style flashable ZIPs**
built from the official FolkPatch release, with recovery-compatible (POSIX `sh`,
no bashisms) installer scripts, A/B slot auto-detection, `init_boot` support,
and an uninstaller.

> **Keywords for search:** FolkPatch flashable zip, FolkPatch TWRP, FolkPatch
> OrangeFox, FolkPatch recovery installer, KernelPatch flashable zip, root
> without Magisk, APatch alternative, flash FolkPatch from recovery,
> FolkPatch boot patcher, FolkPatch uninstaller zip.

---

## Download

Get the ZIPs from the
[**Releases page**](https://github.com/bmjubairdadu/FolkPatch-Flashable-ZIP/releases)
(`v5.0-kp0.13.8`):

| File | What it does |
|---|---|
| `FolkPatch-v5.0-KP0.13.8-Recovery-Installer.zip` | ⭐ **Recommended — Direct flash** — patches & flashes `init_boot` (preferred) or `boot` from recovery. Easiest, no PC needed. |
| `FolkPatch-v5.0-KP0.13.8-Boot-Patcher.zip` | **Safe file mode (advanced)** — patches a stock `boot`/`init_boot` image on your sdcard, **never touches partitions**. You then `fastboot flash` the patched image from a PC. |
| `FolkPatch-v5.0-KP0.13.8-Uninstaller.zip` | Restores the stock backup, or live-unpatches the kernel. |

Each ZIP also bundles the `FolkPatch-Manager.apk` (copied to sdcard on install)
and a `README.txt` (Bangla guide).

Verify integrity with the `SHA256SUMS.txt` attached to the release.

## Requirements

- **ARM64** device, kernel **3.18 – 6.15** with `CONFIG_KALLSYMS=y`
- Custom recovery: **TWRP / OrangeFox / PBRP** (ARM64 build)
- 50%+ battery, and keep a **stock boot/init_boot backup + data backup** first
- If recovery shows a signature error, turn **off** “Zip signature verification”

## Method 1 — Direct flash (Recovery Installer, ⭐ recommended)

1. Copy the Installer ZIP (and the APK) to sdcard.
2. Boot recovery → Install → flash
   `FolkPatch-v5.0-KP0.13.8-Recovery-Installer.zip`.
3. The screen shows your **superkey** (`ApXXXXXXXX`) — write it down.
   It's also saved as `FolkPatch-key.txt` on sdcard.
4. Reboot → install `FolkPatch-Manager.apk` → open the app to verify root.
5. Bootloop? Flash the **Uninstaller ZIP** or restore your stock image.

## Method 2 — Safe (Boot Patcher + fastboot, advanced)

1. Put your **stock** `boot.img` / `init_boot.img` (from your firmware) on
   sdcard, named:
   `FolkPatch-stock-boot.img` (or `FolkPatch-stock-init_boot.img`).
2. Flash `FolkPatch-v5.0-KP0.13.8-Boot-Patcher.zip` from recovery
   (it does **not** touch any partition).
3. It writes `FolkPatch-patched-boot.img` to sdcard.
4. On PC: `fastboot flash boot <file>`
   (or `fastboot flash init_boot <file>`; on A/B devices flash the current slot).
5. Reboot → install Manager APK → verify.

## Uninstall

Flash `FolkPatch-v5.0-KP0.13.8-Uninstaller.zip`.
If a stock backup (`FolkPatch-Backup/stock-*.img`) exists it is restored
automatically.

## How it works

- `META-INF/com/google/android/update-binary` — Magisk-style bootstrap:
  picks a writable tmp dir, bootstraps busybox, extracts the payload,
  selects the installer by ZIP name, then `exec`s it.
- `scripts/InstallFP.sh` — reads the live `boot`/`init_boot` partition,
  backs it up, `unpack → patch (kptools + kpimg + superkey) → repack → flash`.
- `scripts/PatchOnly.sh` — same pipeline on a stock image file, no flashing.
- `scripts/UninstallFP.sh` — restores backup or live-unpatches (`kptools -u`).
- Recovery has no Android runtime (`/system/bin/linker64` is a dangling
  symlink because `/apex` isn't mounted), so the scripts mount the real
  `system` + `apex` and run the `kptools` binary directly with
  `LD_LIBRARY_PATH` set — never by invoking the linker manually.

## Build from source

No binaries are committed to this repo. The build script downloads the
official FolkPatch APK and packs the ZIPs:

```sh
python tools/build.py
# outputs dist/FolkPatch-v5.0-KP0.13.8-*.zip + SHA256SUMS.txt
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

- **সহজ (recommended):** Recovery-Installer ZIP flash করো → superkey নোট করো → reboot →
  Manager APK install।
- **নিরাপদ (advanced):** stock `boot.img` sdcard-তে
  `FolkPatch-stock-boot.img` নামে রাখো → Boot-Patcher ZIP flash করো →
  `FolkPatch-patched-boot.img` PC থেকে `fastboot flash` করো।
- Bootloop হলে Uninstaller ZIP flash করো বা stock img restore করো।
- Kernel-এ `CONFIG_KALLSYMS=y` না থাকলে root কাজ করবে না।
