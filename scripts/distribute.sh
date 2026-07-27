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

if [ "$TARGET" = "" ] || [ "$TARGET" = "-h" ] || [ "$TARGET" = "--help" ]; then
  cat <<'USAGE'
Usage: scripts/distribute.sh <target> [--quick]

Targets:
  web           Run gates, then flutter build web --release
  android-apk   Run gates, then flutter build apk --release
  android-aab   Run gates, then flutter build appbundle --release
  ios-nosign    Run gates, then flutter build ios --release --no-codesign
  ios-ipa       Run gates, then flutter build ipa --release
  all           Run gates, then web + android-aab + ios-nosign

Options:
  --quick       Use ./verify.sh --quick before building. Default is full verify.

Notes:
  ios-* targets require macOS + Xcode. ios-ipa also requires valid signing setup.
  Android signing is read from the normal Flutter/Gradle project configuration.
USAGE
  exit 0
fi

shift || true
for arg in "$@"; do
  case "$arg" in
    --quick) QUICK=1 ;;
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

run_verify() {
  if [ "$QUICK" -eq 1 ]; then
    ./verify.sh --quick
  else
    ./verify.sh
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

build_android_apk() {
  flutter build apk --release --build-number "$BUILD_NUMBER"
}

build_android_aab() {
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
