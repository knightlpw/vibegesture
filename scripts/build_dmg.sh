#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_NAME="VibeGesture"
CONFIGURATION="release"
OUTPUT_PATH=""
OPEN_AFTER_BUILD=0

usage() {
    cat <<'EOF'
Usage: scripts/build_dmg.sh [--configuration debug|release] [--output path] [--open]

Builds the app bundle if needed and wraps it in a distributable .dmg file.
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
        --output)
            if [[ $# -lt 2 ]]; then
                echo "Missing value for --output" >&2
                exit 64
            fi
            OUTPUT_PATH="$2"
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

if [[ -z "$OUTPUT_PATH" ]]; then
    OUTPUT_PATH="$PROJECT_ROOT/.build/distribution/$APP_NAME-$CONFIGURATION.dmg"
fi

APP_BUNDLE="$PROJECT_ROOT/.build/app-bundle/$CONFIGURATION/$APP_NAME.app"
STAGING_ROOT="$PROJECT_ROOT/.build/dmg-staging/$CONFIGURATION/root"

bash "$SCRIPT_DIR/build_bundle.sh" --configuration "$CONFIGURATION"

rm -rf "$STAGING_ROOT" "$OUTPUT_PATH"
mkdir -p "$STAGING_ROOT"

cp -R "$APP_BUNDLE" "$STAGING_ROOT/"
ln -sfn /Applications "$STAGING_ROOT/Applications"

mkdir -p "$(dirname "$OUTPUT_PATH")"
hdiutil create \
    -volname "$APP_NAME" \
    -srcfolder "$STAGING_ROOT" \
    -format UDZO \
    -ov \
    "$OUTPUT_PATH" >/dev/null

hdiutil verify "$OUTPUT_PATH" >/dev/null

echo "DMG created at: $OUTPUT_PATH"

if [[ "$OPEN_AFTER_BUILD" -eq 1 ]]; then
    open "$OUTPUT_PATH"
fi
