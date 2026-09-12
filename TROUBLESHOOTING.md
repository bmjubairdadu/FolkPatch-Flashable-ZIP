# Troubleshooting Guide

## Installation Issues

### "Cannot read boot/init_boot partition"

**Cause:** Partition detection failed (by-name lookup missing).

**Solutions:**
1. **Check recovery logs:**
   ```bash
   adb pull /tmp/recovery.log
   grep -i "target\|boot" recovery.log
   ```

2. **Ensure partition by-name symlinks exist:**
   - In recovery, `ls /dev/block/by-name/` should show `boot`, `boot_b`, etc.
   - Some devices need `ls /dev/block/bootdevice/by-name/`

3. **Try Boot Patcher instead:**
   - Extract stock `boot.img` from your firmware ZIP
   - Use `FolkPatch-Boot-Patcher.zip` (file mode, safer)

4. **Disable encryption temporarily:**
   - Some encrypted recoveries hide partition access
   - Check recovery settings

---

### "kptools: Cannot execute: No such file"

**Cause:** Linker or runtime library missing in recovery.

**Solutions:**
1. **Check APEX mounting:**
   ```bash
   # In recovery terminal (if available):
   ls -la /apex/com.android.runtime/lib64/libc.so
   ```

2. **Update recovery to latest version:**
   - OrangeFox R12+, TWRP 3.8+, PBRP 3.3+
   - Older recoveries may lack APEX support

3. **Use Boot Patcher (file mode):**
   - Avoids linker issues entirely
   - Requires PC with `fastboot`

---

### "Patch failed with exit code 1"

**Cause:** Kernel doesn't have `CONFIG_KALLSYMS=y`.

**Solutions:**
1. **Verify kernel config:**
   ```bash
   # On device:
   cat /proc/config.gz | gunzip | grep KALLSYMS
   ```
   Should show: `CONFIG_KALLSYMS=y` and `CONFIG_KALLSYMS_ALL=y`

2. **Check kernel version:**
   ```bash
   # On device:
   uname -a
   ```
   - FolkPatch requires Linux 3.18 – 6.15
   - Some custom ROMs have incompatible kernels

3. **Try a different ROM/kernel:**
   - Use stock ROM kernel if possible
   - Some kernels are too old (pre-3.18) or too new (6.16+)

---

### "Bootloop after flash"

**Cause:** Corrupted patch or incompatible configuration.

**Recovery Steps:**
1. **Boot into recovery immediately** (while phone is restarting)
   - Press power + volume buttons during boot
   - For most phones: `Power + Vol Down` held throughout boot

2. **Flash Uninstaller ZIP:**
   - **Method 1:** If backup exists, it auto-restores
   - **Method 2:** If no backup, it live-unpatches

3. **Restore stock manually:**
   ```bash
   # If you have the original boot.img file:
   fastboot flash boot stock-boot.img
   fastboot reboot
   ```

4. **Still bootlooping?**
   - Use ADB to pull stock backup: `adb pull /data/FolkPatch-Backup/stock-*.img`
   - Flash via `fastboot flash boot <file>`
   - If no ADB access, use recovery file manager to navigate

---

### "No superkey shown during install"

**Cause:** Recovery output redirection issue.

**Solutions:**
1. **Check saved key files:**
   ```bash
   # In recovery file manager:
   Browse: /sdcard/FolkPatch-key.txt
           /data/media/0/FolkPatch-key.txt
           /FolkPatch-Backup/FolkPatch-key.txt
   ```

2. **Re-flash installer:**
   - The key should appear in red text on screen
   - If not visible, check recovery logs: `adb pull /tmp/recovery.log`

3. **Manual key lookup:**
   - Key is saved to all accessible storage
   - Look for `FolkPatch-key.txt` files

---

## Post-Flash Verification

### "FolkPatch-Manager.apk not found on sdcard"

**Cause:** Storage mount issue or directory permission.

**Solutions:**
1. **Manually copy the APK:**
   ```bash
   # Extract from dist folder:
   unzip FolkPatch-v5.0-KP0.13.8-Recovery-Installer.zip -d extracted/
   adb push extracted/FolkPatch.apk /sdcard/FolkPatch-Manager.apk
   ```

2. **Check storage permissions:**
   - Ensure `/sdcard` is mounted writable
   - Some recoveries require explicit mount

3. **Alternative install:**
   - Sideload APK: `adb install FolkPatch-Manager.apk`
   - Or use Play Store if available

---

### "App shows 'Not installed' despite flashing"

**Cause:** FolkPatch-Manager APK version mismatch or system restriction.

**Solutions:**
1. **Reinstall via ADB:**
   ```bash
   adb uninstall com.folk.patch  # Remove old version
   adb install -r FolkPatch-Manager.apk  # Reinstall
   ```

2. **Check system restrictions:**
   - Settings → Apps → Permissions → Verify allow unknown sources
   - Some ROMs have extra app restrictions

3. **Use alternative root checker:**
   - `Root Checker` app (Google Play)
   - `Terminal Emulator` to run: `id` (should show `uid=0`)

---

## Recovery Compatibility

### OrangeFox

**Known Issues:**
- ✅ Recommended for this project
- Requires R11.1+
- APEX mounting works well

**Tips:**
- Enable "Advanced" menu for debugging
- Check Settings → Debugging → Recovery log

### TWRP

**Known Issues:**
- ✅ Supported (3.8+)
- Sometimes missing `/apex` mount in older versions
- May need manual system mount

**Tips:**
```bash
# In TWRP terminal (if available):
mount /apex
mount /system
```

### PBRP (Pitch Black Recovery)

**Known Issues:**
- ✅ Supported (3.3+)
- PRNG entropy may need manual seed
- Good partition detection

**Tips:**
- Use latest version (3.3+)
- Ensure full storage mount enabled

---

## Diagnostic Commands

### In Recovery Terminal

```bash
# List boot partitions
ls -la /dev/block/by-name/ | grep -i boot

# Check APEX
ls -la /apex/

# View recovery logs
cat /tmp/recovery.log | tail -50

# Check kernel CONFIG
dd if=/dev/block/bootdevice/by-name/boot of=/tmp/boot.img
file /tmp/boot.img  # Verify image type
```

### On Device (ADB)

```bash
# Check root status
id  # Should show uid=0 if rooted

# Verify FolkPatch installed
ls -la /data/FolkPatch-Backup/

# Check superkey
cat /data/FolkPatch-key.txt  # if saved to data

# View boot image
strings /dev/block/by-name/boot | grep -i "folk\|kernel"
```

### Build Verification

```bash
# On PC
sha256sum FolkPatch-v5.0-KP0.13.8-Recovery-Installer.zip
# Compare with SHA256SUMS.txt from release
```

---

## Reporting a Bug

If you still have issues:

1. **Collect diagnostics:**
   ```bash
   adb logcat -d > logcat.txt
   adb pull /tmp/recovery.log recovery.log
   adb pull /proc/config.gz kernel-config.gz
   uname -a > device-info.txt
   ```

2. **Create an issue:**
   - Include device model, kernel version, recovery type
   - Attach all log files
   - Describe exact steps to reproduce
   - Link to this guide if applicable

3. **Be patient:**
   - Complex kernel issues may take time
   - We help based on available info

---

## Safe Practices

⚠️ **Always:**
- ✅ Keep battery **50%+** during flashing
- ✅ Backup your ROM and boot image first
- ✅ Write down your superkey
- ✅ Keep stock backup safe
- ✅ Test on non-critical device first

❌ **Never:**
- ❌ Flash ZIPs over slow USB connection (use sdcard)
- ❌ Unplug device during flashing
- ❌ Flash incompatible kernel versions
- ❌ Delete backup files until verified working
- ❌ Flash multiple ZIPs without testing each

---

## Still Need Help?

- 📖 Check [README.md](README.md)
- 🐛 Search [existing issues](../../issues)
- 💬 Open a new [Discussion](../../discussions)
- 🔗 Ask on XDA Forums (thread link in README)
