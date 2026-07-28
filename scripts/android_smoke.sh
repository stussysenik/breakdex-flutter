#!/bin/sh
# Android smoke gate for Breakdex — build, install, and drive the app on a
# pinned Android target. Exits zero only if every flow in the tag passes.
#
# Examples:
#   scripts/android_smoke.sh                    # smoke tag on the pinned AVD
#   scripts/android_smoke.sh --tags=review
#   scripts/android_smoke.sh --no-build         # reuse the installed APK
#
# The tooling ruling behind this script is
# openspec/changes/android-e2e/design.md D1-D4: Maestro drives Android, argent
# does not; the flows under .maestro/ already exist.
set -u
cd "$(dirname "$0")/.." || exit 1

AVD="${ANDROID_AVD:-Medium_Phone_API_35}"
TAGS=smoke
BUILD=1

for arg in "$@"; do
  case "$arg" in
    --tags=*) TAGS="${arg#--tags=}" ;;
    --no-build) BUILD=0 ;;
    -h|--help)
      sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
      exit 0
      ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

SDK="${ANDROID_SDK_ROOT:-${ANDROID_HOME:-$HOME/Library/Android/sdk}}"
PATH="$SDK/platform-tools:$SDK/emulator:$PATH"
export PATH

MAESTRO=$(command -v maestro || echo "$HOME/.maestro/bin/maestro")
if [ ! -x "$MAESTRO" ]; then
  echo "maestro not found. Install: curl -fsSL https://get.maestro.mobile.dev | bash" >&2
  exit 1
fi
command -v adb >/dev/null || { echo "adb not found under $SDK" >&2; exit 1; }

# ── Parse gate ──────────────────────────────────────────────────────────────
# Maestro parses EVERY flow in the directory before it filters by tag, so one
# syntax-stale flow in an unrelated tier blocks the smoke run. This check needs
# no device and returns in seconds — run it before spending minutes on an
# emulator boot and a gradle build.
echo "=== Parsing .maestro/ ==="
PARSE=$("$MAESTRO" test --include-tags=__parse_only__ .maestro/ 2>&1)
if ! printf '%s' "$PARSE" | grep -q "did not match any Flows"; then
  printf '%s\n' "$PARSE" >&2
  echo "Flow parse failed — fix the syntax above before the gate can run." >&2
  exit 1
fi
echo "  ok    all flows parse"
[ "${LINT_ONLY:-0}" = "1" ] && exit 0

# ── Target ──────────────────────────────────────────────────────────────────
# Reuse whatever is already attached — a booted emulator or the owner's plugged
# device. Only boot the pinned AVD when nothing is there, so a device run and a
# lab run take the same path.
SERIAL=$(adb devices | awk '$2 == "device" { print $1; exit }')

if [ -z "$SERIAL" ]; then
  emulator -list-avds | grep -qx "$AVD" || {
    echo "AVD '$AVD' not found. Available:" >&2
    emulator -list-avds >&2
    exit 1
  }
  echo "=== Booting $AVD ==="
  emulator -avd "$AVD" -no-snapshot-save -no-boot-anim >/tmp/breakdex_emulator.log 2>&1 &
  adb wait-for-device || exit 1
  SERIAL=$(adb devices | awk '$2 == "device" { print $1; exit }')
  # wait-for-device returns at adbd, not at a usable home screen.
  until [ "$(adb -s "$SERIAL" shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" = "1" ]; do
    sleep 2
  done
  BOOTED_HERE=1
else
  BOOTED_HERE=0
fi

DESC=$(adb -s "$SERIAL" shell getprop ro.product.model 2>/dev/null | tr -d '\r')
API=$(adb -s "$SERIAL" shell getprop ro.build.version.sdk 2>/dev/null | tr -d '\r')
echo "Target: $SERIAL — $DESC (API $API)"

# ── Build + install ─────────────────────────────────────────────────────────
APK=build/app/outputs/flutter-apk/app-debug.apk
if [ "$BUILD" = "1" ]; then
  echo "=== flutter build apk --debug ==="
  flutter build apk --debug || exit 1
fi
[ -f "$APK" ] || { echo "No APK at $APK — drop --no-build." >&2; exit 1; }

echo "=== Installing ==="
adb -s "$SERIAL" install -r "$APK" || exit 1

# ── Drive ───────────────────────────────────────────────────────────────────
echo "=== maestro test --include-tags=$TAGS ==="
MAESTRO_DRIVER_STARTUP_TIMEOUT=120000 \
  "$MAESTRO" --device "$SERIAL" test --include-tags="$TAGS" .maestro/
STATUS=$?

if [ "$BOOTED_HERE" = "1" ]; then
  adb -s "$SERIAL" emu kill >/dev/null 2>&1
fi

echo "========================================"
if [ "$STATUS" = "0" ]; then
  echo "ANDROID SMOKE PASSED — tag '$TAGS' on $DESC (API $API)"
else
  echo "ANDROID SMOKE FAILED — tag '$TAGS' on $DESC (API $API)"
fi
echo "NOT PROVEN by this run: any flow outside tag '$TAGS', release-signed"
echo "  behavior (this is a debug build), live Appwrite sync, and every other"
echo "  device in the 6.4 matrix — one target is one target."
exit "$STATUS"
