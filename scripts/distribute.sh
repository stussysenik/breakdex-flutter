#!/bin/sh
# Scriptable distribution gate for Breakdex.
#
# Examples:
#   scripts/distribute.sh web
#   scripts/distribute.sh android-aab
#   scripts/distribute.sh ios-nosign
#   scripts/distribute.sh all --quick
set -u
cd "$(dirname "$0")/.." || exit 1

TARGET="${1:-}"
QUICK=0
ALLOW_DEBUG_SIGNING=0

if [ "$TARGET" = "" ] || [ "$TARGET" = "-h" ] || [ "$TARGET" = "--help" ]; then
  cat <<'USAGE'
Usage: scripts/distribute.sh <target> [--quick] [--allow-debug-signing]

Targets:
  web           Run gates, then flutter build web --release
  android-apk   Run gates, then flutter build apk --release
  android-aab   Run gates, then flutter build appbundle --release
  ios-nosign    Run gates, then flutter build ios --release --no-codesign
  ios-ipa       Run gates, then flutter build ipa --release
  all           Run gates, then web + android-aab + ios-nosign

Options:
  --quick                 Use ./verify.sh --quick before building. Default is full verify.
  --allow-debug-signing   Build an Android artifact with the template's debug keys.
                          Installable locally, NOT uploadable to Play.

Notes:
  ios-* targets require macOS + Xcode. ios-ipa also requires valid signing setup.
  android-* refuse to build until release signing is configured (android/key.properties),
  because a debug-signed bundle is not a release artifact.
USAGE
  exit 0
fi

shift || true
for arg in "$@"; do
  case "$arg" in
    --quick) QUICK=1 ;;
    --allow-debug-signing) ALLOW_DEBUG_SIGNING=1 ;;
    *)
      echo "Unknown option: $arg" >&2
      exit 2
      ;;
  esac
done

BUILD_NUMBER=$(sed -n 's/^version: .*+//p' pubspec.yaml | head -n 1)
if [ -z "$BUILD_NUMBER" ]; then
  echo "Could not parse build number from pubspec.yaml version." >&2
  exit 1
fi

# The whole premise of this script is "gate, THEN build". Without checking the
# gate's exit status it printed SOME GATES FAILED and built anyway — a green
# artifact off a red tree. Never build past a failed gate.
run_verify() {
  if [ "$QUICK" -eq 1 ]; then
    ./verify.sh --quick
  else
    ./verify.sh
  fi
  status=$?
  if [ "$status" -ne 0 ]; then
    echo >&2
    echo "REFUSING TO BUILD: the gate failed (exit $status)." >&2
    echo "Fix it, or inspect with ./verify.sh. No artifact was produced." >&2
    exit "$status"
  fi
}

require_darwin() {
  if [ "$(uname -s)" != "Darwin" ]; then
    echo "$1 requires macOS + Xcode." >&2
    exit 1
  fi
}

build_web() {
  flutter build web --release --build-number "$BUILD_NUMBER"
}

# android/app/build.gradle.kts still carries the Flutter template's
# `signingConfig = signingConfigs.getByName("debug")` for the release build. A
# debug-signed artifact cannot be uploaded to Play and is not a release binary,
# so a green build here would be a false green. Refuse it unless the caller
# explicitly asks for an unsigned/debug-signed local build.
require_android_release_signing() {
  if [ -f android/key.properties ]; then
    return 0
  fi
  if grep -q 'signingConfigs.getByName("debug")' android/app/build.gradle.kts 2>/dev/null; then
    if [ "$ALLOW_DEBUG_SIGNING" -eq 1 ]; then
      echo "WARNING: building $1 with DEBUG signing keys (--allow-debug-signing)." >&2
      echo "         The artifact is installable locally and NOT uploadable to Play." >&2
      return 0
    fi
    cat >&2 <<'SIGN'
Android release signing is not configured.

android/app/build.gradle.kts still uses the Flutter template default:
  signingConfig = signingConfigs.getByName("debug")

A debug-signed AAB/APK cannot be uploaded to Play, so shipping one would be a
false green. Fix it before claiming a release artifact:

  1. keytool -genkey -v -keystore ~/breakdex-upload.jks -keyalg RSA \
       -keysize 2048 -validity 10000 -alias upload
  2. Create android/key.properties (gitignored) with storeFile, storePassword,
     keyAlias, keyPassword.
  3. Load it in android/app/build.gradle.kts and point the release
     signingConfig at it.

To build a local, non-uploadable artifact anyway:
  scripts/distribute.sh <target> --allow-debug-signing
SIGN
    exit 1
  fi
}

build_android_apk() {
  require_android_release_signing "android-apk"
  flutter build apk --release --build-number "$BUILD_NUMBER"
}

build_android_aab() {
  require_android_release_signing "android-aab"
  flutter build appbundle --release --build-number "$BUILD_NUMBER"
}

build_ios_nosign() {
  require_darwin "ios-nosign"
  flutter build ios --release --no-codesign --build-number "$BUILD_NUMBER"
}

build_ios_ipa() {
  require_darwin "ios-ipa"
  flutter build ipa --release --build-number "$BUILD_NUMBER"
}

run_verify

case "$TARGET" in
  web) build_web ;;
  android-apk) build_android_apk ;;
  android-aab) build_android_aab ;;
  ios-nosign) build_ios_nosign ;;
  ios-ipa) build_ios_ipa ;;
  all)
    build_web
    build_android_aab
    build_ios_nosign
    ;;
  *)
    echo "Unknown target: $TARGET" >&2
    echo "Run scripts/distribute.sh --help for valid targets." >&2
    exit 2
    ;;
esac
