# VibeGesture

VibeGesture is a lightweight macOS menu bar tool for vibe coding. It uses the default camera and Vision hand pose detection to turn a small, fixed set of right-hand gestures into keyboard actions for supported apps like Codex, Claude Code, and Cursor.

## Features

- Menu bar toggle for recognition
- Default-camera capture
- Vision-based hand pose pipeline
- Rules-based gesture interpretation
- Explicit recognition state machine
- Safe keyboard dispatching
- Foreground app gating for supported apps only
- Settings window with permission guidance and configuration

## Requirements

- macOS 14 or later
- Camera permission
- Accessibility permission

## Quick Start

### Build and test

```bash
swift test
```

### Build a runnable `.app`

```bash
bash scripts/build_bundle.sh
```

To build and open the app at the same time:

```bash
bash scripts/build_bundle.sh --open
```

The bundle is created under:

```text
.build/app-bundle/debug/VibeGesture.app
```

## Contributing

Please read [`CONTRIBUTING.md`](CONTRIBUTING.md) before opening a PR.

## Privacy

The app is designed to run locally on macOS. It does not include networked gesture upload or cloud processing in the current implementation.

## License

MIT. See [`LICENSE`](LICENSE).
