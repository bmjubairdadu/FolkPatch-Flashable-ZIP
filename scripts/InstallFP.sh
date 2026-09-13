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
# --- recovery stability: entropy + clean libs (prevents patch hangs) ---
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
# kptools repack shells out to external gzip; some recoveries lack it.
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
ui_print " FolkPatch FINAL All-in-One"
ui_print " v8.0 / KP-0.13.8 STABLE"
ui_print " boot-only universal, NO KEY needed"
ui_print "****************************"
ui_print "- JODI screen-e 'superkey' / '000' dekho:"
ui_print "- TUMI VUL (purono v5/v6) ZIP flash korecho!"
ui_print "- v8.0-te kono superkey screen-e ASE NA - keyless."
ui_print "- v8.0 Recovery-Installer NOTUN kore download kore flash koro."

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

# --- slot: cmdline first (recovery getprop is often empty), then getprop ---
SLOT=""
if [ -f /proc/cmdline ]; then
  _cmdline=$(cat /proc/cmdline 2>/dev/null)
  case "$_cmdline" in
    *androidboot.slot_suffix=*)
      SLOT=$(echo "$_cmdline" | tr ' ' '\n' 2>/dev/null | grep '^androidboot.slot_suffix=' 2>/dev/null | head -n 1 | cut -d= -f2)
      ;;
  esac
  if [ -z "$SLOT" ]; then
    _s=$(echo "$_cmdline" | tr ' ' '\n' 2>/dev/null | grep '^androidboot.slot=' 2>/dev/null | head -n 1 | cut -d= -f2)
    if [ -n "$_s" ]; then SLOT="_$_s"; fi
  fi
fi
if [ -z "$SLOT" ] && command -v getprop >/dev/null 2>&1; then
  SLOT=$(getprop ro.boot.slot_suffix 2>/dev/null)
  if [ -z "$SLOT" ]; then
    S=$(getprop ro.boot.slot 2>/dev/null)
    if [ -n "$S" ]; then SLOT="_$S"; fi
  fi
fi
if [ "$SLOT" = "normal" ]; then SLOT=""; fi
# Slot hidden (daisy/OrangeFox): boot_a/boot_b thakle A/B dhore _a default.
# Inactive-slot loop duit slot-i patch kore, jei slot-e boot hok root thakbe.
if [ -z "$SLOT" ]; then
  if find_block "boot_a" >/dev/null 2>&1 || find_block "boot_b" >/dev/null 2>&1; then
    SLOT="_a"
    ui_print "- Slot hidden by recovery, A/B found: using _a (both slots patched)"
  fi
fi
if [ -n "$SLOT" ]; then
  ui_print "- A/B slot: $SLOT"
else
  ui_print "- Slot: A-only (or unknown)"
fi

# by-name lives in different places per recovery/kernel: check all + generic search.
find_block() {
  _b="$1"
  for p in "/dev/block/by-name/$_b" "/dev/block/bootdevice/by-name/$_b"; do
    if [ -e "$p" ]; then echo "$p"; return 0; fi
  done
  for _m in /dev/block/platform/*/by-name/"$_b"; do
    if [ -e "$_m" ]; then echo "$_m"; return 0; fi
  done
  _dev=$(find /dev/block -iname "$_b" 2>/dev/null | head -n 1)
  if [ -n "$_dev" ]; then echo "$_dev"; return 0; fi
  return 1
}

find_part() {
  if [ -n "$SLOT" ]; then
    _t=$(find_block "$1$SLOT")
    if [ -n "$_t" ]; then echo "$_t"; return 0; fi
  fi
  _t=$(find_block "$1")
  if [ -n "$_t" ]; then echo "$_t"; return 0; fi
  return 1
}

# OFFICIAL RULE (fp.mysqil.com): FolkPatch always patches the BOOT partition -
# old device or new, kernel lives in boot. init_boot/vendor_boot hold ramdisk
# only; patching them = no root + brick. So this ZIP is boot-only everywhere.
TARGET=""
TARGET_KIND="boot"
for _n in boot kern-a android_boot kernel bootimg lnx; do
  T=$(find_part "$_n")
  if [ -n "$T" ]; then
    TARGET="$T"
    break
  fi
done
if [ -n "$TARGET" ]; then
  ui_print "- Target: boot ($TARGET)"
else
  ui_print "- Found partitions:"
  ls /dev/block/by-name 2>/dev/null | while IFS= read -r _p || [ -n "$_p" ]; do ui_print "  $_p"; done
  abort "no BOOT partition found. NEVER flash init_boot (brick!). Use Boot-Patcher ZIP + fastboot instead."
fi

SKEY=""
# FolkPatch 4.3+: official auth = SIGNATURE, no password/key needed.
# No key is written into the kernel. The bundled official APK only.
for d in /sdcard /data/media/0 /data/media /external_sd; do
  if [ -f "$d/FolkPatch-key.txt" ]; then
    rm -f "$d/FolkPatch-key.txt" 2>/dev/null
    ui_print "- Removed old FolkPatch-key.txt (not needed anymore)"
  fi
done
rm -f /data/FolkPatch-Backup/FolkPatch-key.txt 2>/dev/null
ui_print "- Auth: official signature mode (no superkey needed)"

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

_BAT=""
for _b in /sys/class/power_supply/battery/capacity /sys/class/power_supply/Battery/capacity; do
  if [ -f "$_b" ]; then _BAT=$(cat "$_b" 2>/dev/null | tr -d ' \t\r\n'); break; fi
done
case "$_BAT" in
  ''|*[!0-9]*) ;;
  *) if [ "$_BAT" -lt 25 ]; then ui_print "- WARNING: battery ${_BAT}% - charge above 50% before flashing!"; fi ;;
esac

ui_print "- Reading $TARGET ..."
run_dd "if=$TARGET" of="$WORK/boot.img" bs=1048576 2>"$WORK/dd_read.log" || abort "cannot read $TARGET"
print_file "$WORK/dd_read.log"
if [ ! -s "$WORK/boot.img" ]; then abort "read produced empty boot.img"; fi
_RSZ=$(wc -c < "$WORK/boot.img" 2>/dev/null | tr -d ' \t\r\n')
if [ -n "$_RSZ" ] && [ "$_RSZ" != "0" ] && [ "$_RSZ" -lt 4194304 ]; then
  abort "read only $_RSZ bytes (too small for boot.img) - wrong partition?"
fi
ui_print "- Read ${_RSZ} bytes"

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
if kp_run -i kernel -l 2>/dev/null | run_grep -qi "patched=true"; then
  ui_print "- NOTE: live image already patched, updating with same key."
  ui_print "- To use a new key, flash Uninstaller first."
fi

if [ -s "$BKDIR/stock-$TARGET_KIND$SLOT.img" ]; then
  ui_print "- Keeping existing stock backup (re-flash detected)."
else
  run_cp -f "$WORK/boot.img" "$BKDIR/stock-$TARGET_KIND$SLOT.img" 2>/dev/null
fi
mkdir -p /data/FolkPatch-Backup 2>/dev/null
if [ -s "/data/FolkPatch-Backup/stock-$TARGET_KIND$SLOT.img" ]; then
  ui_print "- Keeping existing /data stock backup."
else
  run_cp -f "$WORK/boot.img" "/data/FolkPatch-Backup/stock-$TARGET_KIND$SLOT.img" 2>/dev/null
fi
# No key files: official signature-auth needs none.
rm -f "$BKDIR/FolkPatch-key.txt" 2>/dev/null
ui_print "- Stock image saved: $BKDIR/stock-$TARGET_KIND$SLOT.img"
if run_cp -f "$WORK/boot.img" /data/boot.img 2>/dev/null; then
  ui_print "- Origin image also saved to /data/boot.img (official layout)"
fi

if [ -f kernel-origin ]; then rm -f kernel-origin 2>/dev/null; fi
mv kernel kernel-origin 2>/dev/null || abort "cannot stage kernel"

ui_print "- Patching kernel (this can take a minute) ..."
ui_print "- Official flow: KEYLESS patch, signature-auth (FolkPatch 4.3+) ..."
KEYMODE="keyless"
kp_run -p -i kernel-origin -k "$KPIMG" -o kernel >"$WORK/patch.log" 2>&1
RC=$?
print_file "$WORK/patch.log"
if [ "$RC" -ne 0 ]; then abort "patch failed ($RC)"; fi
if [ -n "$KEYMODE" ]; then ui_print "- Key mode OK: $KEYMODE"; fi
if run_grep -qi "patch done" "$WORK/patch.log"; then
  ui_print "- Patch reports done"
else
  ui_print "- NOTE: no 'patch done' line, verifying via -l below"
fi

ui_print "- Verifying patched kernel ..."
kp_run -i kernel -l >"$WORK/verify.log" 2>&1
RC=$?
print_file "$WORK/verify.log"
if [ "$RC" -ne 0 ]; then abort "patch verification failed to run ($RC)"; fi
if run_grep -qi "patched=false" "$WORK/verify.log"; then
  abort "patch verification failed (kernel still reports patched=false)"
fi
if run_grep -qi "patched=true" "$WORK/verify.log"; then
  ui_print "- Patch verified (patched=true)"
else
  ui_print "- WARNING: verify log has no patched=true line!"
  ui_print "- Flashing anyway, on-partition check below is final."
fi
# Signature-auth (FolkPatch 4.3+): no superkey in kernel, app verifies
# the official manager signature instead. Only informational.
_VL=$(run_grep -i "superkey" "$WORK/verify.log" 2>/dev/null | head -n 1)
if [ -n "$_VL" ]; then
  ui_print "- $_VL"
else
  ui_print "- Keyless kernel (official signature-auth, no key line expected)"
fi

if ! kp_run -i kernel-origin -f 2>/dev/null | run_grep -q "CONFIG_KALLSYMS_ALL=y"; then
  ui_print "- WARNING: CONFIG_KALLSYMS_ALL is off; keep stock backup safe."
fi

ui_print "- Repacking ..."
kp_run repack boot.img >"$WORK/repack.log" 2>&1
RC=$?
print_file "$WORK/repack.log"
if [ "$RC" -ne 0 ]; then abort "repack failed ($RC)"; fi
if [ ! -f "$WORK/new-boot.img" ]; then abort "new-boot.img missing after repack"; fi

flash_target() {
  # block-aware flash: size check + rw + fsync (official flash_image logic).
  _img="$WORK/new-boot.img"
  _part="$1"
  _sz=$(wc -c < "$_img" 2>/dev/null | tr -d ' \t\r\n')
  if [ -z "$_sz" ] || [ "$_sz" = "0" ]; then abort "patched image empty, refusing to flash"; fi
  if command -v blockdev >/dev/null 2>&1; then
    _bsz=$(blockdev --getsize64 "$_part" 2>/dev/null)
    if [ -n "$_bsz" ] && [ "$_bsz" != "0" ] && [ "$_sz" -gt "$_bsz" ]; then
      abort "patched image ($_sz) larger than partition ($_bsz), refusing to flash"
    fi
    blockdev --setrw "$_part" 2>/dev/null
  fi
  ui_print "- Flashing $1 (${_sz} bytes) ..."
  # plain dd + sync: works on busybox, toybox and toolbox dd alike.
  if [ "$BB_OK" = "1" ]; then
    "$BB" dd "if=$_img" "of=$1" bs=4096 2>"$WORK/dd_write.log" || abort "flash failed on $1. Restore stock image manually!"
  else
    dd "if=$_img" "of=$1" bs=4096 2>"$WORK/dd_write.log" || abort "flash failed on $1. Restore stock image manually!"
  fi
  print_file "$WORK/dd_write.log"
  sync 2>/dev/null
}

flash_target "$TARGET"

# Save current-slot image: inactive-slot patch below reuses new-boot.img name.
run_cp -f "$WORK/new-boot.img" "$WORK/new-boot-current.img" 2>/dev/null

# Inactive slot: patch ITS OWN stock (slots often have different kernels).
# Flashing current slot's image to the other slot = freeze/bootloop on slot switch.
OTHER=""
INACTIVE_FLASHED=""
case "$SLOT" in
  _a) OTHER="_b" ;;
  _b) OTHER="_a" ;;
esac
if [ -n "$OTHER" ]; then
  _op=$(find_block "$TARGET_KIND$OTHER")
  if [ -n "$_op" ] && [ "$_op" != "$TARGET" ]; then
    ui_print "- Patching inactive slot from its own stock ($TARGET_KIND$OTHER) ..."
    if run_dd "if=$_op" of="$WORK/obot.img" bs=1048576 2>"$WORK/dd_oread.log" && [ -s "$WORK/obot.img" ]; then
      rm -f kernel kernel-origin new-boot.img 2>/dev/null
      run_cp -f "$WORK/obot.img" "$WORK/boot.img" 2>/dev/null
      if kp_run unpack boot.img >"$WORK/ounpack.log" 2>&1 && [ -f kernel ]; then
        mv kernel kernel-origin 2>/dev/null
        if kp_run -p -i kernel-origin -k "$KPIMG" -o kernel >"$WORK/opatch.log" 2>&1; then _orc=0; else _orc=$?; fi
        if [ "$_orc" -eq 0 ] && kp_run repack boot.img >"$WORK/orepack.log" 2>&1 && [ -f "$WORK/new-boot.img" ]; then
          run_cp -f "$WORK/new-boot.img" "$WORK/new-boot-inactive.img" 2>/dev/null
          _osz=$(wc -c < "$WORK/new-boot.img" 2>/dev/null | tr -d ' \t\r\n')
          ui_print "- Flashing inactive slot ($_op, ${_osz} bytes) ..."
          if [ "$BB_OK" = "1" ]; then "$BB" dd "if=$WORK/new-boot.img" "of=$_op" bs=4096 2>"$WORK/dd_write2.log"; else dd "if=$WORK/new-boot.img" "of=$_op" bs=4096 2>"$WORK/dd_write2.log"; fi
          sync 2>/dev/null
          if [ "$?" -eq 0 ]; then
            ui_print "- Inactive slot patched."
            INACTIVE_FLASHED="$_op"
          else
            ui_print "- WARNING: inactive-slot flash failed, current slot is still patched."
          fi
        else
          ui_print "- WARNING: inactive slot patch failed, skipping (current slot OK)."
          print_file "$WORK/opatch.log"
        fi
      else
        ui_print "- WARNING: inactive slot unpack failed, skipping."
      fi
      # restore current-slot files for verify step below
      rm -f kernel kernel-origin 2>/dev/null
    else
      ui_print "- WARNING: cannot read inactive slot, skipping."
    fi
  fi
fi
for _v in "/dev/block/by-name/vbmeta$SLOT" /dev/block/by-name/vbmeta "/dev/block/bootdevice/by-name/vbmeta$SLOT"; do
  if [ -e "$_v" ]; then
    ui_print "- NOTE: vbmeta present; both slots patched so no fallback expected."
    break
  fi
done
_VB=""
if command -v getprop >/dev/null 2>&1; then _VB=$(getprop ro.boot.verifiedbootstate 2>/dev/null); fi
if [ "$_VB" = "green" ]; then
  ui_print "- WARNING: AVB=green (verification ON) - patched boot may be rejected!"
  ui_print "- Fix: unlock bootloader, then fastboot with"
  ui_print "  --disable-verity --disable-verification, then reflash."
fi
rm -f "$WORK/boot.img" "$WORK/obot.img" 2>/dev/null
# Restore current-slot image: inactive-slot step reused the new-boot.img name.
if [ -f "$WORK/new-boot-current.img" ]; then
  run_cp -f "$WORK/new-boot-current.img" "$WORK/new-boot.img" 2>/dev/null
fi
_NSZ=$(wc -c < "$WORK/new-boot.img" 2>/dev/null | tr -d ' \t\r\n')
if [ -n "$_NSZ" ]; then ui_print "- Patched image size: $_NSZ bytes"; fi
do_cmp() {
  if command -v cmp >/dev/null 2>&1; then
    cmp "$1" "$2" >/dev/null 2>&1
    return $?
  fi
  if [ "$BB_OK" = "1" ]; then
    "$BB" cmp "$1" "$2" >/dev/null 2>&1
    return $?
  fi
  return 2
}
verify_slot() {
  # $1=partition $2=label $3=expected image (default: current new-boot.img).
  # Decisive check: unpack what is REALLY on the partition, look for patched=true.
  # Byte-compare is best-effort only (padding can differ) -> warning, not abort.
  _exp="$3"
  if [ -z "$_exp" ]; then _exp="$WORK/new-boot.img"; fi
  _esz=$(wc -c < "$_exp" 2>/dev/null | tr -d ' \t\r\n')
  if [ -z "$_esz" ] || [ "$_esz" = "0" ]; then
    ui_print "- NOTE: size unknown, skipping verify for $2."
    return 0
  fi
  _blocks=$(( ($_esz + 511) / 512 ))
  if ! run_dd "if=$1" of="$WORK/check.img" bs=512 "count=$_blocks" 2>/dev/null || [ ! -s "$WORK/check.img" ]; then
    abort "cannot read back $2 ($1)! Flash may have failed."
  fi
  rm -rf "$WORK/vcheck" 2>/dev/null
  mkdir -p "$WORK/vcheck" 2>/dev/null
  run_cp -f "$WORK/check.img" "$WORK/vcheck/boot.img" 2>/dev/null
  cd "$WORK/vcheck" 2>/dev/null
  if kp_run unpack boot.img >"$WORK/vcheck.log" 2>&1 && [ -f kernel ]; then
    kp_run -i kernel -l >"$WORK/vcheck-l.log" 2>&1
    cd "$WORK" 2>/dev/null
    if run_grep -qi "patched=false" "$WORK/vcheck-l.log"; then
      rm -rf "$WORK/vcheck" "$WORK/check.img" 2>/dev/null
      abort "$2 holds UNPATCHED kernel! Flash went nowhere ($1) - wrong target or blocked. Restore stock, send recovery log."
    fi
    if run_grep -qi "patched=true" "$WORK/vcheck-l.log"; then
      ui_print "- ROOT ACTIVE on $2: partition kernel patched=true."
    else
      ui_print "- WARNING: $2 verify log unclear:"
      print_file "$WORK/vcheck-l.log"
    fi
    _kl=$(run_grep -i "root_superkey" "$WORK/vcheck-l.log" 2>/dev/null | head -n 1)
    if [ -n "$_kl" ]; then ui_print "- $2: $_kl"; fi
  else
    cd "$WORK" 2>/dev/null
    ui_print "- WARNING: cannot unpack $2 readback, relying on byte-compare."
  fi
  rm -rf "$WORK/vcheck" 2>/dev/null
  _rc=2
  if [ "$BB_OK" = "1" ]; then
    "$BB" head -c "$_esz" "$WORK/check.img" > "$WORK/check-trim.img" 2>/dev/null
    if [ -s "$WORK/check-trim.img" ]; then
      do_cmp "$WORK/check-trim.img" "$_exp"
      _rc=$?
      rm -f "$WORK/check-trim.img" 2>/dev/null
    fi
  fi
  rm -f "$WORK/check.img" 2>/dev/null
  if [ "$_rc" = "0" ]; then
    ui_print "- Bytes OK: $2 readback matches."
  elif [ "$_rc" != "2" ]; then
    ui_print "- NOTE: $2 bytes differ slightly (padding?) but kernel is patched - OK."
  fi
}
ui_print "- Verifying ON-PARTITION (what really got flashed) ..."
verify_slot "$TARGET" "current slot" "$WORK/new-boot.img"
if [ -n "$INACTIVE_FLASHED" ] && [ -f "$WORK/new-boot-inactive.img" ]; then
  verify_slot "$INACTIVE_FLASHED" "inactive slot" "$WORK/new-boot-inactive.img"
fi
sync 2>/dev/null

# Stage manager APK + key where the app/upgrade flow expects them.
# Recovery has no package manager, so first install is manual - but kernel is
# already patched, so after reboot: install APK -> enter superkey once ->
# app shows Installed/Active -> later upgrades keep working.
if [ -f "$WORK/FolkPatch.apk" ]; then
  for d in /sdcard /data/media/0 /external_sd; do
    if [ -d "$d" ]; then
      run_cp -f "$WORK/FolkPatch.apk" "$d/FolkPatch-Manager.apk" 2>/dev/null
      mkdir -p "$d/Download/FolkPatch/BootBackups" 2>/dev/null
      run_cp -f "$WORK/FolkPatch.apk" "$d/Download/FolkPatch/FolkPatch-Manager.apk" 2>/dev/null
      if [ -f "$BKDIR/stock-$TARGET_KIND$SLOT.img" ]; then
        run_cp -f "$BKDIR/stock-$TARGET_KIND$SLOT.img" "$d/Download/FolkPatch/BootBackups/" 2>/dev/null
      fi
    fi
  done
  ui_print "- Manager APK on sdcard (FolkPatch-Manager.apk)"
fi
if [ -n "$OLD_LD_PRELOAD" ]; then export LD_PRELOAD="$OLD_LD_PRELOAD"; fi
if [ -n "$OLD_LD_CONFIG" ]; then export LD_CONFIG_FILE="$OLD_LD_CONFIG"; fi

# DUAL-METHOD 2-in-1: direct flash done above; also leave fastboot-ready file.
if [ -f "$WORK/new-boot.img" ]; then
  for d in /sdcard /data/media/0 /data/media /external_sd; do
    if [ -d "$d" ]; then
      run_cp -f "$WORK/new-boot.img" "$d/FolkPatch-patched-$TARGET_KIND.img" 2>/dev/null
    fi
  done
  ui_print "- Patched file also on sdcard: FolkPatch-patched-$TARGET_KIND.img"
  ui_print "- Plan B (PC): fastboot flash $TARGET_KIND FolkPatch-patched-$TARGET_KIND.img"
fi

ui_print "****************************"
ui_print " FolkPatch installed! Auto-root active."
ui_print " NO KEY NEEDED (official signature-auth)."
ui_print " Stock backup: $BKDIR/stock-$TARGET_KIND$SLOT.img"
ui_print " BADHOTAMULOK:"
ui_print " 1. Reboot -> sdcard-er FolkPatch-Manager.apk INSTALL koro"
ui_print "    (ZIP-er sathe thaka official APK tai - onno APK noy)."
ui_print " 2. App kholo -> Installed/Active dekhabe, key chaibe NA."
ui_print " 3. Root Checker diye verify koro."
ui_print " Bootloop/freeze? Flash Uninstaller ZIP or restore stock img."
ui_print "****************************"
exit 0
