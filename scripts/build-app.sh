#!/usr/bin/env bash
# Assembles Kabigon.app from a release build so it runs as a proper menu bar
# app (bundle id, LSUIElement, working notifications). Ad-hoc signed for local
# testing. Notarization + DMG + Homebrew are issue #13.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT="$(pwd)"
APP="$ROOT/build/Kabigon.app"
CONFIG="${1:-release}"

# Build a universal binary (Apple Silicon + Intel) by default so the app runs
# on both. CI can set KABIGON_UNIVERSAL=0 to produce a native fallback ZIP when
# universal release builds are unavailable on the runner.
if [ "${KABIGON_UNIVERSAL:-1}" = "0" ]; then
    ARCH_LABEL="native"
    SWIFT_BUILD_ARGS=(-c "$CONFIG")
else
    ARCH_LABEL="universal arm64 + x86_64"
    SWIFT_BUILD_ARGS=(-c "$CONFIG" --arch arm64 --arch x86_64)
fi

echo "Building ($CONFIG, $ARCH_LABEL)..."
swift build "${SWIFT_BUILD_ARGS[@]}"
BINDIR="$(swift build "${SWIFT_BUILD_ARGS[@]}" --show-bin-path)"

echo "Assembling $APP ..."
rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"

cp "$BINDIR/kabigon" "$APP/Contents/MacOS/kabigon"
cp "$ROOT/scripts/AppInfo.plist" "$APP/Contents/Info.plist"
[ -f "$ROOT/scripts/AppIcon.icns" ] && cp "$ROOT/scripts/AppIcon.icns" "$APP/Contents/Resources/AppIcon.icns"
[ -f "$ROOT/Sources/App/Resources/KabigonLogo.png" ] && cp "$ROOT/Sources/App/Resources/KabigonLogo.png" "$APP/Contents/Resources/KabigonLogo.png"

# Install runtime assets in the standard macOS app resource directory.
ditto "$BINDIR/Kabigon_kabigon.bundle/pmd" "$APP/Contents/Resources/pmd"

# Bundle Sparkle.framework (auto-update). SwiftPM links it via @rpath but does
# not place it inside a hand-assembled .app, so we copy it into Frameworks and
# point the binary's rpath there. ditto preserves the framework symlinks.
mkdir -p "$APP/Contents/Frameworks"
ditto "$BINDIR/Sparkle.framework" "$APP/Contents/Frameworks/Sparkle.framework"
install_name_tool -add_rpath "@executable_path/../Frameworks" "$APP/Contents/MacOS/kabigon" 2>/dev/null || true

# Ad-hoc sign for local testing (release.sh re-signs with a Developer ID).
# Sign the framework first (inside-out) so the outer app signature is valid.
codesign --force --sign - "$APP/Contents/Frameworks/Sparkle.framework" || true
codesign --force --sign - "$APP" || echo "warning: codesign failed (continuing unsigned)"

echo "Done: $APP"
echo "Run with: open \"$APP\"   (or: \"$APP/Contents/MacOS/kabigon\")"
