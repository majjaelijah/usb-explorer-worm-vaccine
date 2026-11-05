#!/usr/bin/env bash
# Cleans the USB-Explorer / GPLControl worm off a mounted drive and protects it.
# The worm is Windows-only and cannot run on Linux, so this is the safest place to clean a drive.
# Usage: ./clean-and-vaccinate.sh /media/$USER/DRIVE [--delete]
#   default: the worm file is moved to _QUARANTINE-worm-DO-NOT-OPEN/ and renamed .exe.virus
#   --delete: the worm file is deleted instead
set -euo pipefail

D="${1:?usage: $0 MOUNT_POINT [--delete]}"; D="${D%/}"
MODE="${2:-}"
[ -d "$D" ] || { echo "Not a directory: $D" >&2; exit 1; }

# 1. Remove the worm program (only if it is a FILE; a folder with that name is our protection)
if [ -f "$D/USB-Explorer.exe" ]; then
  if [ "$MODE" = "--delete" ]; then
    rm -f -- "$D/USB-Explorer.exe"; echo "Deleted worm file"
  else
    Q="$D/_QUARANTINE-worm-DO-NOT-OPEN"; mkdir -p "$Q"
    mv -n -- "$D/USB-Explorer.exe" "$Q/USB-Explorer_$(date +%Y%m%d%H%M%S).exe.virus"
    echo "Quarantined worm file in $Q"
  fi
fi

# 2. Move hidden files back to the root (never overwrites)
if [ -d "$D/Explorer/MAYUNDO" ]; then
  n=0
  for f in "$D/Explorer/MAYUNDO"/* "$D/Explorer/MAYUNDO"/.[!.]*; do
    [ -e "$f" ] || continue
    b=$(basename -- "$f")
    if [ -e "$D/$b" ]; then echo "CONFLICT, left in Explorer/MAYUNDO: $b"
    else mv -n -- "$f" "$D/" && n=$((n+1)); fi
  done
  echo "Restored $n items"
  rmdir -- "$D/Explorer/MAYUNDO" "$D/Explorer" 2>/dev/null || {
    echo "Explorer/MAYUNDO is not empty - resolve the CONFLICT items above, then run again." >&2; exit 1; }
fi
if [ -d "$D/Explorer" ]; then
  echo "An 'Explorer' folder exists but has no MAYUNDO inside - check it by hand, then run again." >&2; exit 1
fi

# 3. Vaccinate: take the worm's two names
if [ ! -e "$D/Explorer" ]; then
  printf 'DO NOT DELETE. Protection against the USB-Explorer / GPLControl worm.\r\n' > "$D/Explorer"
  chmod a-w "$D/Explorer"
fi
if [ ! -e "$D/USB-Explorer.exe" ]; then
  mkdir "$D/USB-Explorer.exe"
  printf 'DO NOT DELETE this folder. It blocks the USB-Explorer worm from copying itself onto this drive.\r\n' \
    > "$D/USB-Explorer.exe/README - protection.txt"
  chmod a-w "$D/USB-Explorer.exe/README - protection.txt" "$D/USB-Explorer.exe"
fi
echo "$D is now protected against the USB-Explorer / GPLControl worm."
