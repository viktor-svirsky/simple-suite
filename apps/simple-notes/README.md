# simple-notes

Minimal markdown notes app — first in the `simple-suite`.

## Requirements

- Xcode 15.4+
- iOS 17+ target
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)

## Generate the Xcode project

The `.xcodeproj` is generated from `project.yml`. Regenerate after adding or moving files:

```bash
cd apps/simple-notes
xcodegen generate
open SimpleNotes.xcodeproj
```

## Build from CLI

```bash
xcodebuild \
  -project apps/simple-notes/SimpleNotes.xcodeproj \
  -scheme SimpleNotes \
  -destination 'generic/platform=iOS Simulator' \
  build
```

## Test

```bash
xcodebuild \
  -project apps/simple-notes/SimpleNotes.xcodeproj \
  -scheme SimpleNotes \
  -destination 'platform=iOS Simulator,name=iPhone 15' \
  test
```

## Structure

```
SimpleNotes/
  App/        — @main entry, RootView shell
  Models/     — SwiftData @Model types
  Features/   — feature modules (Sidebar, NoteList, Editor, …)
  Theme/      — colors, fonts, metrics
  Resources/  — Info.plist, asset catalog
SimpleNotesTests/ — unit tests
```

Spec: `../../docs/superpowers/specs/2026-04-19-simple-notes-design.md`
