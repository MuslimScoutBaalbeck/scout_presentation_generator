# Scout History Presentation

Markdown-driven `flutter_deck` presentation about scouting history.

## Files

- `assets/markdown/scout_history.md` — edit the slides here.
- `lib/main.dart` — loads the Markdown and creates the Flutter Deck.
- `lib/presentation/scout_markdown_slide.dart` — parser + custom slide UI.

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

## Run

```bash
flutter pub get
flutter run -d chrome
```

Use the Flutter Deck PDF/PPTX export toolbar to export.
