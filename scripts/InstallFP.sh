#!/bin/sh
# FolkPatch direct-flash installer (POSIX sh, recovery compatible).
# No bashisms: no 'function', no '[[', no '=='.
# Env from update-binary: BBBIN, INSTALLER. Args: $1 api, $2 fd, $3 zip.
OUTFD="$2"
ZIPFILE="$3"
BB="$BBBIN"
if [ -z "$BB" ]; then BB="busybox"; fi
WORK="$INSTALLER"
if [ -z "$WORK" ]; then WORK="/dev/tmp/fp_install"; fi
KPTOOLS=""
for k in "$WORK/lib/arm64-v8a/libkptools.so" "$WORK/kptools" "$WORK/assets/kptools"; do
  if [ -f "$k" ]; then
    chmod 755 "$k" 2>/dev/null
    KPTOOLS="$k"
    break
  fi
done
KPIMG="$WORK/assets/kpimg"

ui_print() {
  if [ -n "$OUTFD" ] && [ -e "/proc/self/fd/$OUTFD" ]; then
    printf 'ui_print %s\nui_print\n' "$1" >> "/proc/self/fd/$OUTFD" 2>/dev/null
  fi
  echo "$1" >&2
}
print_file() {
  while IFS= read -r line || [ -n "$line" ]; do
    ui_print "$line"
  done < "$1"
}
abort() {
  ui_print "- $1"
  ui_print "- Installation aborted."
  exit 1
}

cd "$WORK" 2>/dev/null || abort "cannot cd to $WORK"
# --- kptools needs Android linker+libs. Recovery /system is a stub, real system must be mounted ---
# kptools PT_INTERP = /system/bin/linker64 (often symlink -> /apex/...). Both must resolve.
# Fix = mount real system + apex, then run kptools DIRECTLY (never invoke linker manually).
ui_print "- Preparing Android runtime ..."
SYS_OK=0
if [ -f /system_root/system/build.prop ] || [ -f /system_root/build.prop ]; then
  SYS_OK=1
  ui_print "- system already mounted at /system_root"
else
  mkdir -p /system_root 2>/dev/null
  for _p in /dev/block/bootdevice/by-name/system_b /dev/block/by-name/system_b /dev/block/bootdevice/by-name/system /dev/block/by-name/system; do
    if [ -e "$_p" ]; then
      mount -o ro "$_p" /system_root 2>/dev/null
      if [ -f /system_root/system/build.prop ] || [ -f /system_root/build.prop ]; then SYS_OK=1; break; fi
    fi
  done
fi
if [ "$SYS_OK" = "1" ]; then ui_print "- system mounted"; else ui_print "- WARNING: system mount failed"; fi
SYSROOT=""
if [ -f /system_root/system/build.prop ]; then SYSROOT="/system_root/system"; else SYSROOT="/system_root"; fi
ui_print "- SYSROOT=$SYSROOT"
mkdir -p /apex 2>/dev/null
APEX_SRC=""
for _a in "$SYSROOT/apex" /system_root/apex /system_root/system/apex; do
  if [ -d "$_a/com.android.runtime" ]; then APEX_SRC="$_a"; break; fi
done
if [ -z "$APEX_SRC" ]; then
  for _a in "$SYSROOT/apex" /system_root/apex /system_root/system/apex; do
    if [ -d "$_a" ]; then APEX_SRC="$_a"; break; fi
  done
fi
if [ -n "$APEX_SRC" ]; then
  ui_print "- APEX_SRC=$APEX_SRC"
  mount -o bind "$APEX_SRC" /apex 2>/dev/null
  if [ -d "$APEX_SRC/com.android.runtime" ]; then
    mkdir -p /apex/com.android.runtime 2>/dev/null
    mount -o bind "$APEX_SRC/com.android.runtime" /apex/com.android.runtime 2>/dev/null
  fi
else
  ui_print "- NOTE: no apex dir found (pre-apex ROM?)"
fi
if [ ! -x /system/bin/linker64 ]; then
  mount -o bind "$SYSROOT" /system 2>/dev/null
fi
if [ ! -x /system/bin/linker64 ] && [ -f "$SYSROOT/bin/linker64" ]; then
  mkdir -p /system/bin 2>/dev/null
  rm -f /system/bin/linker64 2>/dev/null
  cp -f "$SYSROOT/bin/linker64" /system/bin/linker64 2>/dev/null
  chmod 755 /system/bin/linker64 2>/dev/null
fi
LD_DIRS="/apex/com.android.runtime/lib64/bionic:/apex/com.android.runtime/lib64:/system/lib64:$SYSROOT/lib64:/system_root/system/lib64:/vendor/lib64"
if [ -n "$LD_LIBRARY_PATH" ]; then LD_DIRS="$LD_DIRS:$LD_LIBRARY_PATH"; fi
if [ -x /system/bin/linker64 ]; then ui_print "- Linker OK: /system/bin/linker64"; else ui_print "- WARNING: /system/bin/linker64 missing"; ls -l /system/bin/linker64 2>&1 | while IFS= read -r _l || [ -n "$_l" ]; do ui_print "  $_l"; done; fi
if [ -f /apex/com.android.runtime/lib64/bionic/libc.so ]; then ui_print "- bionic OK"; else ui_print "- NOTE: apex bionic missing"; ls /apex/com.android.runtime/bin/ 2>&1 | while IFS= read -r _l || [ -n "$_l" ]; do ui_print "  $_l"; done; fi
kp_run() { LD_LIBRARY_PATH="$LD_DIRS" "$KPTOOLS" "$@"; }
BB_OK=0
if [ -n "$BB" ] && [ -x "$BB" ] && "$BB" true 2>/dev/null; then BB_OK=1; else BB=""; fi
run_dd() {
  if [ "$BB_OK" = "1" ]; then "$BB" dd "$@"; else dd "$@"; fi
}
run_cp() {
  if [ "$BB_OK" = "1" ]; then "$BB" cp "$@"; else cp "$@"; fi
}
run_grep() {
  if [ "$BB_OK" = "1" ]; then "$BB" grep "$@"; else grep "$@"; fi
}
if [ -z "$KPTOOLS" ]; then abort "kptools missing"; fi
chmod 755 "$KPTOOLS" 2>/dev/null
if [ "$BB_OK" = "1" ]; then "$BB" chmod 755 "$KPTOOLS" 2>/dev/null; fi
if [ ! -x "$KPTOOLS" ]; then
  if [ -f "$KPTOOLS" ]; then
    ui_print "- WARNING: exec bit not sticking, trying anyway"
  else
    abort "kptools missing"
  fi
fi
if [ ! -f "$KPIMG" ]; then abort "kpimg missing"; fi

ui_print "****************************"
ui_print " FolkPatch Direct Flash"
ui_print " v5.0 / KP-0.13.8"
ui_print " WITH SYSTEM FIXES"
ui_print "****************************"

ABI=""
if command -v getprop >/dev/null 2>&1; then
  ABI=$(getprop ro.product.cpu.abi 2>/dev/null)
fi
case "$ABI" in
  *arm64*)
    ui_print "- CPU: $ABI"
    ;;
  *)
    if [ -n "$ABI" ]; then ui_print "- WARNING: CPU reports $ABI (needs ARM64)"; fi
    ;;
esac

SLOT=""
if command -v getprop >/dev/null 2>&1; then
  SLOT=$(getprop ro.boot.slot_suffix 2>/dev/null)
  if [ -z "$SLOT" ]; then
    S=$(getprop ro.boot.slot 2>/dev/null)
    if [ -n "$S" ]; then SLOT="_$S"; fi
  fi
fi
if [ -n "$SLOT" ]; then
  ui_print "- A/B slot: $SLOT"
else
  ui_print "- Slot: A-only (or unknown)"
fi

find_part() {
  for p in "/dev/block/by-name/$1$SLOT" "/dev/block/by-name/$1" "/dev/block/bootdevice/by-name/$1$SLOT" "/dev/block/bootdevice/by-name/$1"; do
    if [ -e "$p" ]; then echo "$p"; return 0; fi
  done
  return 1
}

TARGET=""
TARGET_KIND=""
T=$(find_part "init_boot")
if [ -n "$T" ]; then
  TARGET="$T"
  TARGET_KIND="init_boot"
  ui_print "- Target: init_boot ($TARGET)"
else
  T=$(find_part "boot")
  if [ -n "$T" ]; then
    TARGET="$T"
    TARGET_KIND="boot"
    ui_print "- Target: boot ($TARGET)"
  fi
fi
if [ -z "$TARGET" ]; then
  abort "no boot/init_boot partition found (by-name missing in this recovery)"
fi

SKEY=""
for d in /sdcard /data/media/0 /external_sd; do
  if [ -f "$d/FolkPatch-key.txt" ]; then
    SKEY=$(cat "$d/FolkPatch-key.txt" 2>/dev/null | head -n 1 | tr -d ' \t\r\n')
    if [ -n "$SKEY" ]; then
      ui_print "- Reusing saved key from $d/FolkPatch-key.txt"
      break
    fi
  fi
done
if [ -z "$SKEY" ]; then
  R=$(cat /proc/sys/kernel/random/uuid 2>/dev/null | cut -d- -f1 | tr -d ' \t\r\n')
  if [ -z "$R" ]; then R="00000000"; fi
  SKEY="Ap$R"
  ui_print "- New superkey generated"
fi

BKDIR=""
for d in /sdcard/FolkPatch-Backup /data/media/0/FolkPatch-Backup /external_sd/FolkPatch-Backup; do
  if mkdir -p "$d" 2>/dev/null; then
    if [ -d "$d" ]; then BKDIR="$d"; break; fi
  fi
done
if [ -z "$BKDIR" ]; then
  ui_print "- NOTE: /sdcard not mounted, backups go to /tmp only"
  BKDIR="$WORK/backup"
  mkdir -p "$BKDIR" 2>/dev/null
fi
if [ ! -d "$BKDIR" ]; then abort "no writable backup dir"; fi
ui_print "- Backup dir: $BKDIR"

ui_print "- Reading $TARGET ..."
run_dd "if=$TARGET" of="$WORK/boot.img" bs=1048576 2>"$WORK/dd_read.log" || abort "cannot read $TARGET"
print_file "$WORK/dd_read.log"
if [ ! -s "$WORK/boot.img" ]; then abort "read produced empty boot.img"; fi

ui_print "- Unpacking boot image ..."
kp_run unpack boot.img >"$WORK/unpack.log" 2>&1
RC=$?
print_file "$WORK/unpack.log"
if [ "$RC" -ne 0 ]; then abort "unpack failed ($RC)"; fi
if [ ! -f kernel ]; then abort "unpack produced no kernel file"; fi

if ! kp_run -i kernel -f 2>/dev/null | run_grep -q "CONFIG_KALLSYMS=y"; then
  abort "kernel needs CONFIG_KALLSYMS=y (not enabled on this kernel)"
fi
ui_print "- Kernel check passed (CONFIG_KALLSYMS=y)"

run_cp -f "$WORK/boot.img" "$BKDIR/stock-$TARGET_KIND$SLOT.img" 2>/dev/null
echo "$SKEY" > "$BKDIR/FolkPatch-key.txt" 2>/dev/null
for d in /sdcard /data/media/0 /external_sd; do
  if [ -d "$d" ]; then echo "$SKEY" > "$d/FolkPatch-key.txt" 2>/dev/null; fi
done
ui_print "- Stock image saved: $BKDIR/stock-$TARGET_KIND$SLOT.img"

if [ -f kernel-origin ]; then rm -f kernel-origin 2>/dev/null; fi
mv kernel kernel-origin 2>/dev/null || abort "cannot stage kernel"

ui_print "- Patching kernel (this can take a minute) ..."
kp_run -p --image kernel-origin --skey "$SKEY" --kpimg "$KPIMG" --out kernel >"$WORK/patch.log" 2>&1
RC=$?
print_file "$WORK/patch.log"
if [ "$RC" -ne 0 ]; then abort "patch failed ($RC)"; fi

if ! kp_run -i kernel-origin -f 2>/dev/null | run_grep -q "CONFIG_KALLSYMS_ALL=y"; then
  ui_print "- WARNING: CONFIG_KALLSYMS_ALL is off; keep stock backup safe."
fi

ui_print "- Repacking ..."
kp_run repack boot.img >"$WORK/repack.log" 2>&1
RC=$?
print_file "$WORK/repack.log"
if [ "$RC" -ne 0 ]; then abort "repack failed ($RC)"; fi
if [ ! -f "$WORK/new-boot.img" ]; then abort "new-boot.img missing after repack"; fi

ui_print "- Flashing $TARGET ..."
run_dd "if=$WORK/new-boot.img" "of=$TARGET" bs=1048576 2>"$WORK/dd_write.log"
RC=$?
print_file "$WORK/dd_write.log"
if [ "$RC" -ne 0 ]; then abort "flash failed ($RC). Restore stock image manually!"; fi
sync 2>/dev/null

if [ -f "$WORK/FolkPatch.apk" ]; then
  for d in /sdcard /data/media/0 /external_sd; do
    if [ -d "$d" ]; then run_cp -f "$WORK/FolkPatch.apk" "$d/FolkPatch-Manager.apk" 2>/dev/null; fi
  done
  ui_print "- Manager APK copied to sdcard (FolkPatch-Manager.apk)"
fi

ui_print "****************************"
ui_print " FolkPatch installed!"
ui_print " Key: $SKEY (saved to sdcard)"
ui_print " Stock backup: $BKDIR/stock-$TARGET_KIND$SLOT.img"
ui_print " Reboot, install APK, open app to verify."
ui_print " Bootloop? Flash Uninstaller ZIP or restore stock img."
ui_print "****************************"
exit 0
