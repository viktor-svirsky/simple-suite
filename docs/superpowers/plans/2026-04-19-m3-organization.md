# M3 Organization Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add folders, auto-extracted tags, and a search box that supports `#tag`, `folder:x`, and full-text tokens.

**Architecture:**
- New `@Model` types `Folder` and `Tag`, plus relationships on `Note` (`folder: Folder?`, `tags: [Tag]`).
- `TagExtractor` scans `Note.body` for `#tag` tokens when a note is saved and upserts `Tag` rows; the resulting `[Tag]` is assigned to `note.tags`.
- `SearchQueryParser` turns a user string like `"review #work folder:journal"` into a `SearchQuery` (scope overrides, tag filter, folder filter, free text).
- `NoteListView` accepts a `SearchQuery?` and narrows its `@Query` via an appropriate `#Predicate`.
- `SidebarView` gets two new sections: **Folders** (with "New Folder" row + swipe-to-rename/delete) and **Tags** (read-only, sorted by note count).

**Tech Stack:** SwiftData relationships, `SortDescriptor`, SwiftData `#Predicate` with relationship traversal, SwiftUI `.searchable`.

**Branch:** `feat/m3-organization` off `main`.

**Reference spec:** `docs/superpowers/specs/2026-04-19-simple-notes-design.md`

---

## Scope

### In (M3)
- `Folder` model: name, sortOrder
- `Tag` model: name (lowercase, unique)
- `Note.folder` and `Note.tags` relationships
- Auto-tag extraction on edit (same 500 ms debounce as `touch()`)
- Sidebar Folders section with create / rename / delete (swipe)
- Sidebar Tags section (read-only, sorted by note count desc)
- Tapping a folder or tag narrows the list
- `.searchable` with tokens `#tag`, `folder:name`, free text (AND combined)
- Empty state when query yields nothing
- Tests for `TagExtractor`, `SearchQueryParser`, predicate behaviour

### Out (deferred)
- Reordering folders by drag (nice-to-have, defer)
- Renaming tags (spec calls them derived; deleting a tag is implicit — body edit removes `#tag`)
- Full-text ranking (title match > body match) — M3.1 if needed; v1 uses simple contains

### Non-goals
- Third-party search libraries
- Indexing beyond what SwiftData predicates can express

---

## File Structure (end state after M3)

```
apps/simple-notes/SimpleNotes/
├── Models/
│   ├── Note.swift              # gains folder, tags relationships
│   ├── Folder.swift            # new
│   └── Tag.swift               # new
├── Features/
│   ├── Sidebar/
│   │   └── SidebarView.swift   # + folders, tags sections
│   ├── NoteList/
│   │   ├── NoteListView.swift  # accepts optional SearchQuery
│   │   └── NoteListScope.swift # extended with folder / tag cases
│   └── Editor/
│       └── NoteEditorView.swift # triggers TagExtractor on body save
├── Search/
│   ├── SearchQuery.swift
│   ├── SearchQueryParser.swift
│   └── TagExtractor.swift
```

---

## Task 1: Feature branch

**Files:** none

- [x] **Step 1: Pull + branch**

```bash
cd /Users/viktorsvirskyi/Projects/simple-suite
git checkout main
git pull --ff-only origin main
git status
git checkout -b feat/m3-organization
```

---

## Task 2: `Folder` model

**Files:**
- Create: `apps/simple-notes/SimpleNotes/Models/Folder.swift`
- Create: `apps/simple-notes/SimpleNotesTests/FolderModelTests.swift`
- Modify: `apps/simple-notes/SimpleNotes/App/SimpleNotesApp.swift` (register Folder with ModelContainer)

- [x] **Step 1: Failing tests**

Create `apps/simple-notes/SimpleNotesTests/FolderModelTests.swift`:

```swift
import XCTest
import SwiftData
@testable import SimpleNotes

final class FolderModelTests: XCTestCase {
    private func container() throws -> ModelContainer {
        try ModelContainer(
            for: Note.self, Folder.self, Tag.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
    }

    func test_insertFolder_persists() throws {
        let c = try container()
        let ctx = ModelContext(c)
        let f = Folder(name: "Journal", sortOrder: 0)
        ctx.insert(f)
        try ctx.save()
        XCTAssertEqual(try ctx.fetchCount(FetchDescriptor<Folder>()), 1)
    }

    func test_defaultSortOrder_isZero() {
        XCTAssertEqual(Folder(name: "x").sortOrder, 0)
    }
}
```

- [x] **Step 2: Confirm failure** (skipped — implemented directly)

```bash
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -15
```

- [x] **Step 3: Implement**

Create `apps/simple-notes/SimpleNotes/Models/Folder.swift`:

```swift
import Foundation
import SwiftData

@Model
final class Folder {
    var id: UUID
    var name: String
    var sortOrder: Int
    @Relationship(inverse: \Note.folder) var notes: [Note]

    init(id: UUID = UUID(), name: String, sortOrder: Int = 0) {
        self.id = id
        self.name = name
        self.sortOrder = sortOrder
        self.notes = []
    }
}
```

Update `SimpleNotesApp.swift` model list:

```swift
        .modelContainer(for: [Note.self, Folder.self, Tag.self])
```

Add `Tag` placeholder file now so the container compiles — full model lands in Task 3:

Create `apps/simple-notes/SimpleNotes/Models/Tag.swift`:

```swift
import Foundation
import SwiftData

@Model
final class Tag {
    var id: UUID
    var name: String
    @Relationship(inverse: \Note.tags) var notes: [Note]

    init(id: UUID = UUID(), name: String) {
        self.id = id
        self.name = name.lowercased()
        self.notes = []
    }
}
```

Add `folder` and `tags` properties to `Note.swift`:

```swift
    var folder: Folder?
    @Relationship var tags: [Tag]
```

Initialize them in `init` as `nil` / `[]`.

- [x] **Step 4: Tests pass**

```bash
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -10
```

Expected: `** TEST SUCCEEDED **`.

- [x] **Step 5: Commit**

```bash
git add apps/simple-notes/SimpleNotes/Models \
        apps/simple-notes/SimpleNotes/App/SimpleNotesApp.swift \
        apps/simple-notes/SimpleNotesTests/FolderModelTests.swift \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "feat(simple-notes): add Folder, Tag models and Note relationships"
```

---

## Task 3: `TagExtractor`

**Files:**
- Create: `apps/simple-notes/SimpleNotes/Search/TagExtractor.swift`
- Create: `apps/simple-notes/SimpleNotesTests/TagExtractorTests.swift`

- [x] **Step 1: Failing tests**

```swift
import XCTest
import SwiftData
@testable import SimpleNotes

final class TagExtractorTests: XCTestCase {
    private func context() throws -> ModelContext {
        ModelContext(
            try ModelContainer(
                for: Note.self, Folder.self, Tag.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        )
    }

    func test_extracts_newTags_and_attachesToNote() throws {
        let ctx = try context()
        let note = Note(body: "hello #Work and #journal")
        ctx.insert(note)
        TagExtractor.apply(to: note, in: ctx)
        try ctx.save()
        XCTAssertEqual(Set(note.tags.map(\.name)), ["work", "journal"])
    }

    func test_reuses_existingTags() throws {
        let ctx = try context()
        let existing = Tag(name: "work")
        ctx.insert(existing)
        let note = Note(body: "hello #work")
        ctx.insert(note)
        TagExtractor.apply(to: note, in: ctx)
        try ctx.save()
        XCTAssertEqual(note.tags.count, 1)
        XCTAssertTrue(note.tags.contains { $0 === existing })
    }

    func test_removes_tagsNoLongerInBody() throws {
        let ctx = try context()
        let note = Note(body: "#a #b")
        ctx.insert(note)
        TagExtractor.apply(to: note, in: ctx)
        try ctx.save()
        XCTAssertEqual(Set(note.tags.map(\.name)), ["a", "b"])

        note.body = "only #a now"
        TagExtractor.apply(to: note, in: ctx)
        try ctx.save()
        XCTAssertEqual(Set(note.tags.map(\.name)), ["a"])
    }
}
```

- [x] **Step 2: Confirm failure** (skipped — implemented directly)

```bash
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -15
```

- [x] **Step 3: Implement**

Create `apps/simple-notes/SimpleNotes/Search/TagExtractor.swift`:

```swift
import Foundation
import SwiftData

enum TagExtractor {
    /// Scans `note.body` for `#tag` tokens (via `MarkdownTagScanner`), then
    /// reconciles `note.tags`: upsert missing, drop removed.
    static func apply(to note: Note, in context: ModelContext) {
        let names = Set(
            MarkdownTagScanner.tags(in: note.body)
                .map { $0.name.lowercased() }
        )

        // Drop tags that no longer appear in the body.
        note.tags = note.tags.filter { names.contains($0.name) }

        for name in names where !note.tags.contains(where: { $0.name == name }) {
            let existing = try? context.fetch(
                FetchDescriptor<Tag>(predicate: #Predicate { $0.name == name })
            ).first
            let tag = existing ?? Tag(name: name)
            if existing == nil { context.insert(tag) }
            note.tags.append(tag)
        }
    }
}
```

- [x] **Step 4: Tests pass**

```bash
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -10
```

- [x] **Step 5: Commit**

```bash
git add apps/simple-notes/SimpleNotes/Search/TagExtractor.swift \
        apps/simple-notes/SimpleNotesTests/TagExtractorTests.swift \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "feat(simple-notes): add TagExtractor (upsert from body)"
```

---

## Task 4: Hook `TagExtractor` into the editor autosave path

**Files:**
- Modify: `apps/simple-notes/SimpleNotes/Features/Editor/EditorAutosaver.swift`
- Modify: `apps/simple-notes/SimpleNotes/Features/Editor/NoteEditorView.swift`

- [ ] **Step 1: Extend autosaver with an `onFlush` callback**

```swift
@MainActor
final class EditorAutosaver {
    private let debounce: Duration
    private var pending: Task<Void, Never>?
    private var onFlush: (() -> Void)?

    init(debounce: Duration = .milliseconds(500)) { self.debounce = debounce }

    func onFlush(_ action: @escaping () -> Void) { onFlush = action }

    func scheduleTouch(on note: Note) {
        pending?.cancel()
        pending = Task { [debounce, onFlush] in
            do { try await Task.sleep(for: debounce) } catch { return }
            guard !Task.isCancelled else { return }
            note.touch()
            onFlush?()
        }
    }

    func cancel() { pending?.cancel(); pending = nil }
    deinit { pending?.cancel() }
}
```

- [ ] **Step 2: Wire editor**

In `NoteEditorView.body`, after creating `autosaver`:

```swift
        .task(id: note.id) {
            autosaver.onFlush {
                TagExtractor.apply(to: note, in: modelContext)
            }
        }
```

Also call `TagExtractor.apply(to: note, in: modelContext)` in the view's `flush()` helper before `modelContext.save()`.

- [ ] **Step 3: Test existing tests still pass**

```bash
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -10
```

- [ ] **Step 4: Commit**

```bash
git add apps/simple-notes/SimpleNotes/Features/Editor \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "feat(simple-notes): run TagExtractor on autosave flush"
```

---

## Task 5: `SearchQuery` + `SearchQueryParser`

**Files:**
- Create: `apps/simple-notes/SimpleNotes/Search/SearchQuery.swift`
- Create: `apps/simple-notes/SimpleNotes/Search/SearchQueryParser.swift`
- Create: `apps/simple-notes/SimpleNotesTests/SearchQueryParserTests.swift`

- [ ] **Step 1: Failing tests**

```swift
import XCTest
@testable import SimpleNotes

final class SearchQueryParserTests: XCTestCase {
    func test_parses_freeText() {
        let q = SearchQueryParser.parse("hello world")
        XCTAssertEqual(q.text, "hello world")
        XCTAssertTrue(q.tags.isEmpty)
        XCTAssertNil(q.folderName)
    }

    func test_parses_tag() {
        let q = SearchQueryParser.parse("#journal review")
        XCTAssertEqual(q.tags, ["journal"])
        XCTAssertEqual(q.text, "review")
    }

    func test_parses_folderToken() {
        let q = SearchQueryParser.parse("folder:Journal notes")
        XCTAssertEqual(q.folderName, "journal")
        XCTAssertEqual(q.text, "notes")
    }

    func test_parses_multipleTokens() {
        let q = SearchQueryParser.parse("folder:work #todo urgent")
        XCTAssertEqual(q.tags, ["todo"])
        XCTAssertEqual(q.folderName, "work")
        XCTAssertEqual(q.text, "urgent")
    }

    func test_empty_isEmpty() {
        XCTAssertTrue(SearchQueryParser.parse("").isEmpty)
    }
}
```

- [ ] **Step 2: Confirm failure**

```bash
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -15
```

- [ ] **Step 3: Implement**

`apps/simple-notes/SimpleNotes/Search/SearchQuery.swift`:

```swift
import Foundation

struct SearchQuery: Equatable {
    var text: String = ""
    var tags: [String] = []
    var folderName: String? = nil

    var isEmpty: Bool {
        text.isEmpty && tags.isEmpty && folderName == nil
    }
}
```

`apps/simple-notes/SimpleNotes/Search/SearchQueryParser.swift`:

```swift
import Foundation

enum SearchQueryParser {
    static func parse(_ raw: String) -> SearchQuery {
        var query = SearchQuery()
        var freeWords: [String] = []

        for token in raw.split(whereSeparator: \.isWhitespace) {
            let s = String(token)
            if s.hasPrefix("#") && s.count > 1 {
                query.tags.append(String(s.dropFirst()).lowercased())
            } else if s.lowercased().hasPrefix("folder:") {
                let name = s.dropFirst("folder:".count)
                if !name.isEmpty {
                    query.folderName = String(name).lowercased()
                }
            } else if !s.isEmpty {
                freeWords.append(s)
            }
        }

        query.text = freeWords.joined(separator: " ")
        return query
    }
}
```

- [ ] **Step 4: Tests pass**

```bash
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -10
```

- [ ] **Step 5: Commit**

```bash
git add apps/simple-notes/SimpleNotes/Search/SearchQuery.swift \
        apps/simple-notes/SimpleNotes/Search/SearchQueryParser.swift \
        apps/simple-notes/SimpleNotesTests/SearchQueryParserTests.swift \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "feat(simple-notes): add SearchQuery and parser"
```

---

## Task 6: Extend `NoteListScope` with folder / tag filtering + apply `SearchQuery`

**Files:**
- Modify: `apps/simple-notes/SimpleNotes/Features/NoteList/NoteListScope.swift`
- Create: `apps/simple-notes/SimpleNotesTests/SearchFilteringTests.swift`

- [ ] **Step 1: Failing tests**

```swift
import XCTest
import SwiftData
@testable import SimpleNotes

final class SearchFilteringTests: XCTestCase {
    private func ctx() throws -> ModelContext {
        ModelContext(
            try ModelContainer(
                for: Note.self, Folder.self, Tag.self,
                configurations: ModelConfiguration(isStoredInMemoryOnly: true)
            )
        )
    }

    func test_filtersByFolderName() throws {
        let c = try ctx()
        let journal = Folder(name: "Journal")
        let work = Folder(name: "Work")
        c.insert(journal); c.insert(work)
        let a = Note(body: "A"); a.folder = journal
        let b = Note(body: "B"); b.folder = work
        c.insert(a); c.insert(b)
        try c.save()

        let query = SearchQueryParser.parse("folder:journal")
        let matches = try NoteSearch.run(query: query, in: c)
        XCTAssertEqual(matches.map(\.body), ["A"])
    }

    func test_filtersByTag() throws {
        let c = try ctx()
        let t = Tag(name: "todo"); c.insert(t)
        let a = Note(body: "A #todo"); a.tags = [t]
        let b = Note(body: "B")
        c.insert(a); c.insert(b)
        try c.save()

        let matches = try NoteSearch.run(
            query: SearchQueryParser.parse("#todo"),
            in: c
        )
        XCTAssertEqual(matches.map(\.body), ["A #todo"])
    }

    func test_filtersByFreeText_caseInsensitive() throws {
        let c = try ctx()
        c.insert(Note(body: "A note about Swift"))
        c.insert(Note(body: "Something else"))
        try c.save()

        let matches = try NoteSearch.run(
            query: SearchQueryParser.parse("swift"),
            in: c
        )
        XCTAssertEqual(matches.map(\.body), ["A note about Swift"])
    }
}
```

- [ ] **Step 2: Confirm failure**

```bash
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -15
```

- [ ] **Step 3: Implement `NoteSearch`**

Create `apps/simple-notes/SimpleNotes/Search/NoteSearch.swift`:

```swift
import Foundation
import SwiftData

/// Pure filter runner usable in tests and in the view. Production `@Query`
/// relies on this for its `FetchDescriptor`.
enum NoteSearch {
    static func descriptor(query: SearchQuery, base: NoteListScope) -> FetchDescriptor<Note> {
        let scopePredicate = base.predicate
        let lowerText = query.text.lowercased()
        let tagNames = query.tags
        let folderName = query.folderName

        let composite = #Predicate<Note> { note in
            scopePredicate.evaluate(note)
            && (folderName == nil
                || (note.folder?.name.localizedLowercase ?? "") == folderName!)
            && tagNames.allSatisfy { name in
                note.tags.contains { $0.name == name }
            }
            && (lowerText.isEmpty
                || note.body.localizedStandardContains(lowerText))
        }

        return FetchDescriptor<Note>(
            predicate: composite,
            sortBy: NoteListScope.sortDescriptors
        )
    }

    static func run(query: SearchQuery, base: NoteListScope = .all, in context: ModelContext) throws -> [Note] {
        try context.fetch(descriptor(query: query, base: base))
    }
}
```

(If `#Predicate` complains about `Predicate.evaluate` inside another predicate, fall back to manually composing the clauses with the stored predicate cases — see the README for the idiomatic form. Keep the public surface the same either way.)

- [ ] **Step 4: Tests pass**

```bash
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -10
```

- [ ] **Step 5: Commit**

```bash
git add apps/simple-notes/SimpleNotes/Search/NoteSearch.swift \
        apps/simple-notes/SimpleNotesTests/SearchFilteringTests.swift \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "feat(simple-notes): SearchQuery-driven FetchDescriptor"
```

---

## Task 7: Wire search UI + sidebar folder / tag rows

**Files:**
- Modify: `apps/simple-notes/SimpleNotes/Features/NoteList/NoteListView.swift`
- Modify: `apps/simple-notes/SimpleNotes/Features/Sidebar/SidebarView.swift`
- Modify: `apps/simple-notes/SimpleNotes/App/RootView.swift`

- [ ] **Step 1: Search in `NoteListView`**

Add `.searchable(text: $searchText)` bound to a `@State` string; on change, call `SearchQueryParser.parse` and rebuild the fetch descriptor (recreate the view with the new predicate via `@State` query key).

Use `@Environment(\.modelContext)` + a manually fetched `@State var notes: [Note]` that refreshes on `.onChange(of: searchText)`. (`@Query` doesn't take a dynamic predicate, so swap to imperative fetch here.)

- [ ] **Step 2: Sidebar folders section**

Inside `SidebarView`:

```swift
            Section("Folders") {
                ForEach(folders) { folder in
                    row(folder.name, count: folder.notes.count, systemImage: "folder", scope: .folder(folder.id))
                }
                Button {
                    let next = (folders.map(\.sortOrder).max() ?? 0) + 1
                    let f = Folder(name: "New Folder", sortOrder: next)
                    modelContext.insert(f)
                } label: {
                    Label("New Folder", systemImage: "folder.badge.plus")
                }
            }
```

`folders` from `@Query(sort: \Folder.sortOrder)`. Add swipe-to-delete on the folder rows.

- [ ] **Step 3: Sidebar tags section**

```swift
            if !tags.isEmpty {
                Section("Tags") {
                    ForEach(tags) { tag in
                        row("#\(tag.name)", count: tag.notes.count, systemImage: nil, scope: .tag(tag.id))
                    }
                }
            }
```

Extend `NoteListScope` with `.folder(UUID)` and `.tag(UUID)` cases.

- [ ] **Step 4: `RootView` passes folder / tag filter down**

Translate the scope into a `SearchQuery` pre-populated with `folderName` or `tags[0]` before reaching the list, OR route all filtering through `NoteSearch.descriptor`.

- [ ] **Step 5: Tests + build pass**

```bash
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -10
```

- [ ] **Step 6: Commit**

```bash
git add apps/simple-notes/SimpleNotes/Features \
        apps/simple-notes/SimpleNotes/App/RootView.swift \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "feat(simple-notes): sidebar folders/tags + searchable list"
```

---

## Task 8: End-to-end verification

- [ ] **Step 1: Full test run**

```bash
cd /Users/viktorsvirskyi/Projects/simple-suite
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes clean test 2>&1 | tail -20
```

- [ ] **Step 2: Manual smoke (mark [x] with skip note)**

- Create folder in sidebar, drag note into folder (long-press context menu), folder filters
- Type `#foo` in body, save → sidebar Tags section shows `#foo`
- Use `.searchable` with `folder:x #y z` → combined filter
- Swipe folder → delete → notes remain (with `folder = nil`)

- [ ] **Step 3: Stop**

Do not push.

---

## Definition of Done (M3)

- [ ] All unit tests pass
- [ ] Sidebar Folders + Tags sections render real data
- [ ] Search bar accepts `#tag`, `folder:x`, and free text
- [ ] Editor auto-extracts tags on save
- [ ] No push, no PR
