#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="VibeGesture"
BUNDLE_IDENTIFIER="com.linpeiwen.vibegesture"
CONFIGURATION="debug"
OPEN_AFTER_BUILD=0

usage() {
    cat <<'EOF'
Usage: scripts/build_bundle.sh [--configuration debug|release] [--open]

Builds the SwiftPM executable and wraps it in a macOS .app bundle under
.build/app-bundle/<configuration>/VibeGesture.app.
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --configuration)
            if [[ $# -lt 2 ]]; then
                echo "Missing value for --configuration" >&2
                exit 64
            fi
            CONFIGURATION="$2"
            shift 2
            ;;
        --open)
            OPEN_AFTER_BUILD=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 64
            ;;
    esac
done

if [[ "$CONFIGURATION" != "debug" && "$CONFIGURATION" != "release" ]]; then
    echo "Unsupported configuration: $CONFIGURATION" >&2
    exit 64
fi

BUILD_ROOT="$PROJECT_ROOT/.build/app-bundle/$CONFIGURATION"
APP_BUNDLE="$BUILD_ROOT/$APP_NAME.app"
EXECUTABLE_PATH="$PROJECT_ROOT/.build/$CONFIGURATION/$APP_NAME"
ICONSET_DIR="$BUILD_ROOT/AppIcon.iconset"
ICON_MASTER="$BUILD_ROOT/AppIcon-master.png"
ICNS_PATH="$APP_BUNDLE/Contents/Resources/AppIcon.icns"

rm -rf "$APP_BUNDLE" "$ICONSET_DIR" "$ICON_MASTER"
mkdir -p "$APP_BUNDLE/Contents/MacOS" "$APP_BUNDLE/Contents/Resources" "$ICONSET_DIR"

swift build -c "$CONFIGURATION"

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
    echo "Missing built executable: $EXECUTABLE_PATH" >&2
    exit 1
fi

cp "$EXECUTABLE_PATH" "$APP_BUNDLE/Contents/MacOS/$APP_NAME"
chmod 755 "$APP_BUNDLE/Contents/MacOS/$APP_NAME"

swift "$SCRIPT_DIR/make_app_icon.swift" "$ICON_MASTER"

resize_icon() {
    local size="$1"
    local output="$2"
    sips -z "$size" "$size" "$ICON_MASTER" --out "$ICONSET_DIR/$output" >/dev/null
}

resize_icon 16 icon_16x16.png
resize_icon 32 icon_16x16@2x.png
resize_icon 32 icon_32x32.png
resize_icon 64 icon_32x32@2x.png
resize_icon 128 icon_128x128.png
resize_icon 256 icon_128x128@2x.png
resize_icon 256 icon_256x256.png
resize_icon 512 icon_256x256@2x.png
resize_icon 512 icon_512x512.png
resize_icon 1024 icon_512x512@2x.png

iconutil -c icns "$ICONSET_DIR" -o "$ICNS_PATH" >/dev/null

cat > "$APP_BUNDLE/Contents/Info.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>en</string>
    <key>CFBundleDisplayName</key>
    <string>$APP_NAME</string>
    <key>CFBundleExecutable</key>
    <string>$APP_NAME</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundleIdentifier</key>
    <string>$BUNDLE_IDENTIFIER</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>$APP_NAME</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>0.1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSApplicationCategoryType</key>
    <string>public.app-category.developer-tools</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSCameraUsageDescription</key>
    <string>VibeGesture needs camera access to read hand gestures.</string>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

printf 'APPL????' > "$APP_BUNDLE/Contents/PkgInfo"

plutil -lint "$APP_BUNDLE/Contents/Info.plist" >/dev/null

echo "Bundle created at: $APP_BUNDLE"
echo "Bundle identifier: $BUNDLE_IDENTIFIER"
echo "Icon installed at: $ICNS_PATH"

if [[ "$OPEN_AFTER_BUILD" -eq 1 ]]; then
    open -n "$APP_BUNDLE"
fi
