# simple-notes — Design Spec

**Date:** 2026-04-19
**Status:** Approved (brainstorm)
**App:** `apps/simple-notes`

## Purpose

Native iOS notes app. Minimal, beautiful, fast. First app in the `simple-suite` monorepo.

## Scope (v1)

- Create, read, update, delete notes
- Markdown-based rich text (Bear-style)
- Folders (optional) and tags (`#tag` inline)
- Full-text search with `#tag` and `folder:x` tokens
- Image attachments (inline markdown refs)
- Pin notes
- iCloud sync (private database) across user's devices
- System dark mode
- iPad layout (NavigationSplitView three columns)

**Out of scope (v1):** collaboration, web clipper, themes beyond light/dark, export, widgets, Apple Watch, Mac Catalyst, end-to-end encryption beyond Apple's defaults.

## Non-Goals

- Reach parity with Apple Notes / Bear / Notion. This is a focused minimal app.
- Support iOS < 17. SwiftData requires iOS 17+.

## Tech Stack

| Layer        | Choice                                  |
|--------------|-----------------------------------------|
| UI           | SwiftUI (iOS 17+)                       |
| Persistence  | SwiftData                               |
| Sync         | CloudKit (private database, auto)       |
| Language     | Swift 5.9+                              |
| Build        | Xcode 15+, xcodebuild                   |
| CI           | GitHub Actions (iOS simulator tests)    |

## Repo Structure

```
simple-suite/
├── README.md
├── .gitignore
├── apps/
│   └── simple-notes/
│       ├── SimpleNotes.xcodeproj
│       └── SimpleNotes/
│           ├── App/              # @main, ModelContainer setup
│           ├── Models/           # SwiftData @Model types
│           ├── Features/
│           │   ├── NoteList/
│           │   ├── Editor/
│           │   ├── Sidebar/
│           │   └── Settings/
│           ├── Components/       # Reusable UI primitives
│           ├── Theme/            # Color, Font, Metric
│           ├── Markdown/         # Renderer, tag/attachment extensions
│           ├── Search/           # Token parser, ranking
│           └── Resources/        # Assets.xcassets, Info.plist
├── packages/                     # Future shared Swift Packages
└── docs/
    └── superpowers/specs/
```

Future apps drop into `apps/`. Shared code extracted into `packages/SimpleKit` when a second app needs it.

## Data Model

SwiftData `@Model` types. CloudKit-compatible (all properties have defaults, relationships optional where needed).

```swift
@Model final class Note {
    var id: UUID
    var title: String            // derived: first non-empty line, trimmed, max 80 chars
    var body: String             // markdown source
    var createdAt: Date
    var updatedAt: Date
    var isPinned: Bool
    var folder: Folder?
    @Relationship var tags: [Tag]
    @Relationship(deleteRule: .cascade) var attachments: [Attachment]
}

@Model final class Folder {
    var id: UUID
    var name: String
    var sortOrder: Int
    @Relationship(inverse: \Note.folder) var notes: [Note]
}

@Model final class Tag {
    var id: UUID
    var name: String             // lowercase, unique
    @Relationship(inverse: \Note.tags) var notes: [Note]
}

@Model final class Attachment {
    var id: UUID
    var filename: String
    var data: Data               // see "Attachments" below
    var createdAt: Date
}
```

**Invariants:**
- `title` recomputed on every save from `body`
- `updatedAt` touched on any mutation
- Tags extracted from `body` on save: regex `#[A-Za-z0-9_-]+`, lowercased, deduplicated, upserted
- Deleting a `Note` cascades its `Attachment`s but not `Tag`s or `Folder`

## CloudKit Sync

`ModelConfiguration(cloudKitDatabase: .private)`. Default container. SwiftData handles sync automatically.

- Signed-in iCloud account required for sync; app still fully works offline / signed out (local container).
- Sync status surfaced in Settings (last sync timestamp, error if any).
- Conflict resolution: SwiftData's default (last-write-wins per field).

## Attachments

- Inline markdown reference: `![caption](attachment://<uuid>)`
- Small images (< 1 MB) stored in `Attachment.data` directly
- Larger images compressed (JPEG q=0.8, max 2048px long edge) at insert time
- If still > 5 MB after compression, reject with user-visible error (v1 limit)
- CKAsset-backed storage for large files deferred to v2

## Markdown Renderer

Built on `AttributedString(markdown:)` (Foundation, iOS 15+). Custom extensions:

- `#tag` — styled as muted monospace, tappable → filter list by tag
- `![](attachment://uuid)` — resolved to inline image from `Attachment`
- Code blocks render in `SF Mono`
- Headings: serif (New York), scaled by level

Editor is **not** live-preview. It is markdown source in a `TextEditor`, with rendered view shown when the note is not being edited (tap to edit, tap outside to render). This avoids the complexity of inline WYSIWYG and matches Bear.

Rejected: full WYSIWYG (too complex for v1), split-pane preview (cramped on iPhone).

## Architecture

```
SimpleNotesApp (@main)
└── RootView
    └── NavigationSplitView
        ├── SidebarView         — All, Pinned, Folders, Tags
        ├── NoteListView        — filtered list, search, sort
        └── NoteEditorView      — markdown editor / rendered view
```

**State management:**
- SwiftData `@Query` for lists (Notes, Folders, Tags)
- `@Observable` `EditorViewModel` owns dirty buffer, debounced autosave (500 ms after last keystroke)
- `SearchViewModel` parses query tokens, applies predicate to `@Query`
- No global app state; each screen owns its own

**Feature modules** (folders under `Features/`):
Each feature contains `View`, optional `ViewModel`, and local `Components/`. Features import only `Models/`, `Theme/`, `Components/` (app-level), `Markdown/`, `Search/`. No cross-feature imports.

## UI Flow

### iPhone (compact)
- Launch → `NoteListView` ("All Notes", newest first)
- Tap row → push `NoteEditorView`
- Swipe left on row → Pin / Delete actions
- `+` toolbar button → new note, editor auto-focused
- Top toolbar: sidebar button (presents sidebar as sheet), search, sort menu
- Editor toolbar: attach image, markdown cheatsheet, share, delete

### iPad (regular)
- Three-column `NavigationSplitView` always visible
- Sidebar | NoteList | Editor
- Keyboard shortcuts: ⌘N new, ⌘F focus search, ⌘⇧P pin, ⌘⌫ delete, ⌘B bold (inserts `**..**`), ⌘I italic

### Empty states
Centered SF Symbol glyph (monochrome) + one line of muted text. No illustrations.

### Sync status
Small footer in Sidebar: "Synced • 2m ago" or "Syncing…" or "Offline". Tappable → Settings.

## Search

Token parser:
- `#tag` → filter by tag
- `folder:name` → filter by folder (case-insensitive)
- Remaining terms → full-text match against `title + body` (case-insensitive, diacritic-insensitive)
- Multiple tokens AND together
- Ranking: title match > body match; recent `updatedAt` breaks ties

Implemented as SwiftData `#Predicate` where possible; fallback to in-memory filter for complex token combos (v1 acceptable, v2 can optimize).

## Theme (minimal mono, Bear-like)

```swift
enum Theme {
    enum Color {
        static let bg       // 0xFAFAFA / dark 0x0A0A0A
        static let surface  // 0xFFFFFF / dark 0x141414
        static let text     // 0x0A0A0A / dark 0xF5F5F5
        static let muted    // 0x737373 / dark 0xA3A3A3
        static let accent   // inverse of bg
        static let hairline // 0xE5E5E5 / dark 0x262626
    }
    enum Font {
        static let serif = "New York"       // titles, editor body
        static let sans  = "SF Pro Text"    // UI chrome
        static let mono  = "SF Mono"        // code blocks, tags
    }
    enum Metric {
        static let radius: CGFloat = 8
        static let padding: CGFloat = 16
        static let hairline: CGFloat = 0.5
    }
}
```

**Principles:**
- Single accent (inverse of bg), no color coding
- Hairlines, not shadows, for separation
- Serif for content, sans for chrome
- Respects system dark mode; no in-app toggle in v1
- Full Dynamic Type support
- Haptics only on pin / delete

## Error Handling

- **Sync errors:** surface in Settings + sidebar footer. Non-blocking.
- **Attachment > 5 MB (post-compression):** inline error banner in editor, do not insert.
- **Model save failures:** log + retry once; if still failing, user-visible alert ("Couldn't save. Try again.").
- **Missing iCloud account:** app works locally; banner in Settings explains sync disabled.
- No crash reporting SDK in v1 (Apple's built-in sufficient).

## Testing

### Unit (`SimpleNotesTests/`)
- `MarkdownRendererTests` — tag parsing, attachment resolution, CommonMark subset
- `NoteModelTests` — title derivation, tag extraction on save, `updatedAt` touch, cascade delete
- `SearchTests` — token parser (`#tag`, `folder:x`), ranking order
- `AutosaveTests` — debounce interval, no-op when body unchanged
- `AttachmentTests` — compression, size rejection

### UI (`SimpleNotesUITests/`)
- Create → appears in list
- Edit → autosave → reopen preserves body
- Pin → moves to top of "All Notes"
- Tap tag → list filters
- Delete → gone from list
- Empty state visible when no notes

**SwiftData in tests:** in-memory `ModelContainer` (`isStoredInMemoryOnly: true`). No CloudKit in CI.

**CI:** GitHub Actions, `xcodebuild test -scheme SimpleNotes -destination 'platform=iOS Simulator,name=iPhone 15'`. Cached DerivedData.

**Coverage target:** 70% on `Models/`, `Markdown/`, `Search/`. UI flows smoke-tested only.

## Milestones

1. **M0 — Scaffold:** Xcode project, SwiftData container, root `NavigationSplitView`, theme primitives, CI running
2. **M1 — CRUD:** create/edit/delete notes, autosave, list, pin
3. **M2 — Markdown:** renderer, tag parsing, render/edit toggle
4. **M3 — Organization:** folders, tags sidebar, search
5. **M4 — Attachments:** image picker, inline refs, compression
6. **M5 — Sync:** CloudKit wiring, sync status UI, error handling
7. **M6 — Polish:** empty states, keyboard shortcuts, haptics, Dynamic Type audit

Each milestone ships to TestFlight internally and is a separate plan under `docs/superpowers/plans/`.

## Open Questions

None at spec time. Any unknowns during implementation will be raised as ADRs in `docs/adr/`.
