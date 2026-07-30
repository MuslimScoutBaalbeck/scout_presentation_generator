# Scout History Presentation

Markdown-driven `flutter_deck` presentation about scouting history.

## Files

- `assets/markdown/scout_history.md` — edit slide content and speaker notes.
- `lib/main.dart` — projector/audience entry point.
- `lib/main_presenter.dart` — presenter entry point.
- `lib/bootstrap.dart` — shared Flutter Deck configuration.
- `lib/presentation/scout_markdown_slide.dart` — Markdown parser and custom slide UI.
- `tool/presenter_server.dart` — local WebSocket state relay; Dart Frog is not required.
- `tool/run_macos_pair.sh` — builds and opens the two native macOS apps.

## Markdown format

Separate slides with:

```md
---
```

Use:

```md
# Slide title
## Optional subtitle
- Bullet one
- Bullet two

> Optional quote

:::notes
Speaker notes here.
:::
```

## Run two native macOS apps

The macOS workflow creates two different app bundles so they can run at the same time:

- **Scout Projector**: the clean audience view shown on the projector.
- **Scout Presenter**: current slide, next slide, notes, timer, and controls on the Mac.

Connect the projector as an **extended display**, not a mirrored display, then run:

```bash
cd /Users/fenix/Desktop/Scout/Workspace/scout_presentation_generator
bash tool/run_macos_pair.sh
```

The command:

1. Starts a local WebSocket server on `127.0.0.1:8080`.
2. Builds `lib/main.dart` as `Scout Projector.app`.
3. Builds `lib/main_presenter.dart` as `Scout Presenter.app`.
4. Gives each app a distinct bundle identifier.
5. Opens both apps.

Move **Scout Projector** to the projector display and use macOS full screen (`Control` + `Command` + `F`). Keep **Scout Presenter** on the Mac display.

The generated apps are stored in:

```text
build/macos-pair/Scout Projector.app
build/macos-pair/Scout Presenter.app
```

### Open again without rebuilding

```bash
SKIP_BUILD=1 bash tool/run_macos_pair.sh
```

### Stop both apps and the local server

```bash
bash tool/stop_macos_pair.sh
```

### Use a different local port

```bash
DECK_WS_PORT=8090 bash tool/run_macos_pair.sh
```

### Build without launching

```bash
bash tool/build_macos_pair.sh
```

The scripts use `fvm flutter` and `fvm dart` when FVM is installed; otherwise they use the system `flutter` and `dart` commands.

## WebSocket configuration

The app reads the WebSocket address from the compile-time `DECK_WS_URI` value and defaults to:

```text
ws://127.0.0.1:8080
```

Example manual build:

```bash
fvm flutter build macos \
  --release \
  --target=lib/main.dart \
  --dart-define=DECK_WS_URI=ws://127.0.0.1:8080
```

## Web development

```bash
fvm flutter pub get
fvm flutter run -d chrome
```

Use the Flutter Deck PDF/PPTX export tools when needed.
