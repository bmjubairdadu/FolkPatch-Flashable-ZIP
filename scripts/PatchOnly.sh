#!/bin/sh
# FolkPatch boot-image patcher, file mode only (POSIX sh).
# Patches a stock boot/init_boot IMG on sdcard, NEVER touches partitions.
# Env: BBBIN, INSTALLER. Args: $1 api, $2 fd, $3 zip.
OUTFD="$2"
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
  ui_print "- Patch aborted. Partitions NOT touched."
  exit 1
}

cd "$WORK" 2>/dev/null || abort "cannot cd to $WORK"
mount -o bind /dev/urandom /dev/random 2>/dev/null
OLD_LD_PRELOAD="$LD_PRELOAD"
OLD_LD_CONFIG="$LD_CONFIG_FILE"
unset LD_PRELOAD 2>/dev/null
unset LD_CONFIG_FILE 2>/dev/null
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
if ! command -v gzip >/dev/null 2>&1; then
  if [ "$BB_OK" = "1" ] && "$BB" gzip --help >/dev/null 2>&1; then
    mkdir -p "$WORK/bin" 2>/dev/null
    ln -sf "$BB" "$WORK/bin/gzip" 2>/dev/null
    PATH="$WORK/bin:$PATH"
    ui_print "- gzip linked from busybox"
  else
    ui_print "- WARNING: gzip missing, repack may fail"
  fi
fi
if [ ! -f "$KPTOOLS" ]; then abort "kptools missing"; fi
if [ ! -f "$KPIMG" ]; then abort "kpimg missing"; fi

ui_print "****************************"
ui_print " FolkPatch Boot Patcher"
ui_print " (file mode, no auto-flash)"
ui_print "****************************"

# Kernel lives in boot: prefer boot images first (init_boot = ramdisk only).
SRC=""
for f in /sdcard/FolkPatch-stock-boot.img /data/media/0/FolkPatch-stock-boot.img /sdcard/boot.img /sdcard/stock_boot.img /external_sd/boot.img /sdcard/FolkPatch-stock-init_boot.img /sdcard/init_boot.img /sdcard/stock_init_boot.img /external_sd/init_boot.img; do
  if [ -s "$f" ]; then SRC="$f"; break; fi
done
if [ -z "$SRC" ]; then
  ui_print "- Put your stock image on sdcard first, named:"
  ui_print "  FolkPatch-stock-boot.img  (or init_boot)"
  abort "no stock boot/init_boot img found on sdcard"
fi
ui_print "- Source: $SRC"

case "$SRC" in
  *init_boot*) KIND="init_boot" ;;
  *) KIND="boot" ;;
esac
if [ "$KIND" = "init_boot" ]; then
  ui_print "- NOTE: init_boot holds ramdisk, kernel patch needs boot."
  ui_print "- If root does not activate, redo with stock boot.img."
fi

SKEY=""
for d in /sdcard /data/media/0 /data/media /external_sd; do
  if [ -f "$d/FolkPatch-key.txt" ]; then
    SKEY=$(cat "$d/FolkPatch-key.txt" 2>/dev/null | head -n 1 | tr -d ' \t\r\n')
    if [ -n "$SKEY" ]; then break; fi
  fi
done
if [ -z "$SKEY" ]; then
  R=$(cat /proc/sys/kernel/random/uuid 2>/dev/null | cut -d- -f1 | tr -d ' \t\r\n')
  if [ -z "$R" ]; then R="00000000"; fi
  SKEY="Ap$R"
fi
ui_print "- Superkey: $SKEY"

OUTDIR=""
for d in /sdcard /data/media/0 /external_sd; do
  if [ -d "$d" ]; then OUTDIR="$d"; break; fi
done
if [ -z "$OUTDIR" ]; then
  ui_print "- NOTE: /sdcard not mounted, output goes to /tmp only"
  OUTDIR="$WORK"
fi

if [ "$BB_OK" = "1" ]; then "$BB" cp -f "$SRC" "$WORK/boot.img" 2>/dev/null || abort "cannot copy source"; else cp -f "$SRC" "$WORK/boot.img" 2>/dev/null || abort "cannot copy source"; fi
kp_run unpack boot.img >"$WORK/unpack.log" 2>&1 || abort "unpack failed"
print_file "$WORK/unpack.log"
if [ ! -f kernel ]; then abort "no kernel after unpack"; fi
if ! kp_run -i kernel -f 2>/dev/null | run_grep -q "CONFIG_KALLSYMS=y"; then
  abort "kernel needs CONFIG_KALLSYMS=y"
fi
ui_print "- Kernel check passed"
if kp_run -i kernel -l 2>/dev/null | run_grep -qi "patched=true"; then
  abort "source image already patched - use a STOCK boot.img"
fi
if [ "$BB_OK" = "1" ]; then "$BB" mv kernel kernel-origin 2>/dev/null || abort "cannot stage kernel"; else mv kernel kernel-origin 2>/dev/null || abort "cannot stage kernel"; fi
ui_print "- Mode: official first (root-skey, same as boot_patch.sh) ..."
kp_run -p -i kernel-origin -S "$SKEY" -k "$KPIMG" -o kernel >"$WORK/patch.log" 2>&1
RC=$?
if [ "$RC" -ne 0 ]; then
  kp_run -p -i kernel-origin -s "$SKEY" -S "$SKEY" -k "$KPIMG" -o kernel >"$WORK/patch.log" 2>&1
  RC=$?
fi
if [ "$RC" -ne 0 ]; then
  kp_run -p -i kernel-origin -s "$SKEY" -k "$KPIMG" -o kernel >"$WORK/patch.log" 2>&1
  RC=$?
fi
print_file "$WORK/patch.log"
if [ "$RC" -ne 0 ]; then abort "patch failed ($RC)"; fi
ui_print "- Verifying ..."
kp_run -i kernel -l >"$WORK/verify.log" 2>&1
print_file "$WORK/verify.log"
if run_grep -qi "patched=false" "$WORK/verify.log"; then abort "verify failed (patched=false)"; fi
if run_grep -qi "patched=true" "$WORK/verify.log"; then
  ui_print "- File patched=true. Flash it, then Manager app-e ei key dao."
fi
run_grep -i "superkey" "$WORK/verify.log" 2>/dev/null | while IFS= read -r _kl || [ -n "$_kl" ]; do ui_print "- $_kl"; done
if ! kp_run -i kernel-origin -f 2>/dev/null | run_grep -q "CONFIG_KALLSYMS_ALL=y"; then
  ui_print "- WARNING: CONFIG_KALLSYMS_ALL off; keep stock backup safe."
fi
kp_run repack boot.img >"$WORK/repack.log" 2>&1 || abort "repack failed"
print_file "$WORK/repack.log"
if [ ! -f "$WORK/new-boot.img" ]; then abort "new-boot.img missing"; fi

OUT="$OUTDIR/FolkPatch-patched-$KIND.img"
if [ "$BB_OK" = "1" ]; then "$BB" cp -f "$WORK/new-boot.img" "$OUT" 2>/dev/null || abort "cannot write $OUT"; else cp -f "$WORK/new-boot.img" "$OUT" 2>/dev/null || abort "cannot write $OUT"; fi
echo "$SKEY" > "$OUTDIR/FolkPatch-key.txt" 2>/dev/null
mkdir -p "$OUTDIR/Download/FolkPatch/BootBackups" 2>/dev/null
run_cp -f "$SRC" "$OUTDIR/Download/FolkPatch/BootBackups/" 2>/dev/null
if [ -f "$WORK/FolkPatch.apk" ]; then
  run_cp -f "$WORK/FolkPatch.apk" "$OUTDIR/FolkPatch-Manager.apk" 2>/dev/null
  run_cp -f "$WORK/FolkPatch.apk" "$OUTDIR/Download/FolkPatch/FolkPatch-Manager.apk" 2>/dev/null
fi
if [ -n "$OLD_LD_PRELOAD" ]; then export LD_PRELOAD="$OLD_LD_PRELOAD"; fi
if [ -n "$OLD_LD_CONFIG" ]; then export LD_CONFIG_FILE="$OLD_LD_CONFIG"; fi

ui_print "****************************"
ui_print " Patched image ready:"
ui_print " $OUT"
ui_print " Key: $SKEY"
ui_print " Flash on PC: fastboot flash $KIND $OUT"
ui_print " (A/B device? flash to current slot, or flash both slots)"
ui_print "****************************"
exit 0
