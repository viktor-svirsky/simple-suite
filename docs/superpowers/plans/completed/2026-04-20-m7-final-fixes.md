# M7 Final Review Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Address the must-fix + priority should-fix items from the v1.0 code review so simple-notes is ready for a confident v1.0.0 tag.

**Architecture:** Targeted, surgical edits — no new subsystems. Mostly schema corrections, build config, and extraction of duplicated editor logic.

**Branch:** `feat/m7-final-fixes` off `main`.

---

## Scope

### Must-fix from review
1. Add `Attachment.note` inverse relationship (CloudKit rejects unidirectional)
2. `@Attribute(.externalStorage)` on `Attachment.data` (CloudKit 1 MB record limit)
3. Split entitlements per-config (AltStore `Release` must not declare iCloud)
4. Config-parameterized `make ipa` so CloudKit builds exist as a separate artifact

### Should-fix included
5. Guard `Data(contentsOf:)` on picked files with `fileSizeKey` pre-check
6. Extract duplicated insert/delete attachment logic into helper
7. Move release tag push to **after** bundle verification
8. Drop Sentry `tracesSampleRate` to `0.01` to protect free-tier quota

### Out of scope (deferred)
- Replacing `@retroactive Comparable` on `Bool` (cosmetic, Swift 6-pending)
- `NoteAttachmentActions` full extraction (keep minimum viable dedup)
- `@Transient` title cache

---

## Task 1: Branch

- [x] Pull main, branch `feat/m7-final-fixes`.

---

## Task 2: Attachment inverse + external storage

**Files:**
- Modify: `apps/simple-notes/SimpleNotes/Models/Attachment.swift`
- Modify: `apps/simple-notes/SimpleNotes/Models/Note.swift`
- Modify: `apps/simple-notes/SimpleNotesTests/AttachmentModelTests.swift` (add inverse assertion)

- [x] **Step 1: Failing test**

```swift
    func test_attachment_knowsItsNote() throws {
        let c = try ctx()
        let note = Note(body: "")
        let att = Attachment(filename: "x", data: Data())
        note.attachments = [att]
        c.insert(note)
        try c.save()
        XCTAssertEqual(att.note?.body, "")
    }
```

- [x] **Step 2: Implement**

`Attachment.swift`:

```swift
    var note: Note?
```

`Note.swift` — change relationship to declare inverse:

```swift
    @Relationship(deleteRule: .cascade, inverse: \Attachment.note)
    var attachments: [Attachment] = []
```

Also add external storage attribute:

```swift
    @Attribute(.externalStorage) var data: Data
```

- [x] **Step 3: Regen + test pass**

```bash
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -10
```

- [x] **Step 4: Commit**

```bash
git add apps/simple-notes/SimpleNotes/Models \
        apps/simple-notes/SimpleNotesTests/AttachmentModelTests.swift \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "fix(simple-notes): Attachment inverse + externalStorage for CloudKit"
```

---

## Task 3: Split entitlements per config

**Files:**
- Rename: `apps/simple-notes/SimpleNotes/Resources/SimpleNotes.entitlements` → `SimpleNotes.CloudKit.entitlements`
- Create: `apps/simple-notes/SimpleNotes/Resources/SimpleNotes.Release.entitlements`
- Modify: `apps/simple-notes/project.yml`

- [x] **Step 1: Create Release entitlements (no iCloud keys)**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
</dict>
</plist>
```

- [x] **Step 2: Update project.yml**

Under `targets.SimpleNotes.settings.configs`:

```yaml
          Debug:
            CODE_SIGN_ENTITLEMENTS: SimpleNotes/Resources/SimpleNotes.Release.entitlements
          Release:
            CODE_SIGN_ENTITLEMENTS: SimpleNotes/Resources/SimpleNotes.Release.entitlements
          ReleaseCloudKit:
            CODE_SIGN_ENTITLEMENTS: SimpleNotes/Resources/SimpleNotes.CloudKit.entitlements
```

Remove the global `CODE_SIGN_ENTITLEMENTS` from the base settings.

- [x] **Step 3: Regen + build both configs**

```bash
(cd apps/simple-notes && xcodegen generate)
xcodebuild -project apps/simple-notes/SimpleNotes.xcodeproj -scheme SimpleNotes \
  -configuration Release -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO build | tail -5
xcodebuild -project apps/simple-notes/SimpleNotes.xcodeproj -scheme SimpleNotes \
  -configuration ReleaseCloudKit -destination 'generic/platform=iOS' \
  CODE_SIGNING_ALLOWED=NO build | tail -5
```

Both should succeed.

- [x] **Step 4: Commit**

```bash
git add apps/simple-notes/SimpleNotes/Resources \
        apps/simple-notes/project.yml \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "fix(simple-notes): per-config entitlements (Release has no iCloud)"
```

---

## Task 4: Config-parameterized `make ipa` + CI job for CloudKit artifact

**Files:**
- Modify: `apps/simple-notes/Makefile`
- Modify: `.github/workflows/release.yml`

- [x] **Step 1: Makefile**

```make
CONFIG ?= Release
…
ipa: generate
	rm -rf /tmp/$(APP_NAME).xcarchive /tmp/$(APP_NAME)IPA
	xcodebuild -project $(PROJECT) -scheme $(SCHEME) \
		-configuration $(CONFIG) \
		-archivePath /tmp/$(APP_NAME).xcarchive \
		-destination 'generic/platform=iOS' \
		archive \
		CODE_SIGN_IDENTITY=- \
		CODE_SIGNING_ALLOWED=NO \
		MARKETING_VERSION=$(VERSION) \
		CURRENT_PROJECT_VERSION=$(VERSION) \
		SENTRY_DSN="$(SENTRY_DSN)"
	mkdir -p /tmp/$(APP_NAME)IPA/Payload
	cp -r /tmp/$(APP_NAME).xcarchive/Products/Applications/$(APP_NAME).app \
		/tmp/$(APP_NAME)IPA/Payload/
	cd /tmp/$(APP_NAME)IPA && zip -r /tmp/$(APP_NAME).ipa Payload/
```

- [x] **Step 2: release.yml — build both IPAs**

Add a second build step for ReleaseCloudKit that produces `SimpleNotesCloudKit.ipa`. Keep the existing step for `SimpleNotes.ipa` (AltStore). Upload both to the GitHub Release. altstore-source.json keeps pointing at `SimpleNotes.ipa`.

- [x] **Step 3: actionlint pass + commit**

```bash
actionlint .github/workflows/*.yml
git add apps/simple-notes/Makefile .github/workflows/release.yml \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "fix(simple-notes): parameterize ipa config; build both Release IPAs"
```

---

## Task 5: Size-check picked files before loading

**Files:**
- Modify: `apps/simple-notes/SimpleNotes/Features/Editor/NoteEditorView.swift`

- [x] **Step 1: Guard in `handleFileImport`**

```swift
    let values = try url.resourceValues(forKeys: [.fileSizeKey])
    if let size = values.fileSize, size > AttachmentImporter.maxBytes {
        errorBanner = "File too large (10 MB limit)."
        return
    }
```

Runs before `Data(contentsOf: url)`.

- [x] **Step 2: Commit**

```bash
git add apps/simple-notes/SimpleNotes/Features/Editor/NoteEditorView.swift \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "fix(simple-notes): pre-check file size before loading into memory"
```

---

## Task 6: Extract attachment helper

**Files:**
- Create: `apps/simple-notes/SimpleNotes/Attachments/NoteAttachments.swift`
- Modify: `apps/simple-notes/SimpleNotes/Features/Editor/NoteEditorView.swift`

- [x] **Step 1: Helper**

```swift
enum NoteAttachments {
    static func attach(
        _ att: Attachment,
        to note: Note,
        context: ModelContext,
        isImage: Bool
    ) {
        context.insert(att)
        note.attachments.append(att)
        let bang = isImage ? "!" : ""
        note.body.append("\n\n\(bang)[\(att.filename)](attachment://\(att.id))\n")
        note.touch()
        try? context.save()
    }

    static func detach(_ att: Attachment, from note: Note, context: ModelContext) {
        let marker = "(attachment://\(att.id))"
        let lines = note.body.split(omittingEmptySubsequences: false, whereSeparator: \.isNewline)
        let filtered = lines.filter { !$0.contains(marker) }
        note.body = filtered.joined(separator: "\n")
        note.attachments.removeAll { $0.id == att.id }
        context.delete(att)
        note.touch()
        try? context.save()
    }
}
```

- [x] **Step 2: Swap call sites**

In `handlePickedImage` and `handleFileImport`, replace the ~10-line attach sequence with a single `NoteAttachments.attach(att, to: note, context: modelContext, isImage: isImage)`. Replace `deleteAttachment` body with `NoteAttachments.detach(...)`.

- [x] **Step 3: Tests + commit**

```bash
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -10
```

```bash
git add apps/simple-notes/SimpleNotes/Attachments/NoteAttachments.swift \
        apps/simple-notes/SimpleNotes/Features/Editor/NoteEditorView.swift \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "refactor(simple-notes): extract NoteAttachments helper"
```

---

## Task 7: Release pipeline — verify before tag

**Files:**
- Modify: `.github/workflows/release.yml`

- [x] **Step 1: Reorder**

Move the `Create tag` step to **after** `Verify published bundle`. Keep `Create GitHub Release` first (it doesn't create the tag if `tag_name` doesn't exist yet — `softprops/action-gh-release@v2` creates it from `tag_name` automatically; re-check current behaviour and adjust: if the action creates the tag, move the `Create tag` block deletion and let the action do it after verify).

Simpler safer path: keep current order but add a cleanup on failure that deletes the tag if `Verify published bundle` fails.

```yaml
      - name: Rollback tag on verification failure
        if: failure() && steps.version.outputs.bump != 'none' && env.SKIP_RELEASE != 'true'
        run: |
          git push origin :refs/tags/${{ env.TAG }} || true
          gh release delete "${{ env.TAG }}" --yes || true
```

- [x] **Step 2: Lint + commit**

```bash
actionlint .github/workflows/*.yml
git add .github/workflows/release.yml
git commit -m "fix(ci): roll back tag + release if bundle verification fails"
```

---

## Task 8: Lower Sentry traces sample rate

**Files:**
- Modify: `apps/simple-notes/SimpleNotes/App/SentryConfig.swift`

- [x] **Step 1: Drop from 0.1 → 0.01**

```swift
            options.tracesSampleRate = 0.01
```

- [x] **Step 2: Commit**

```bash
git add apps/simple-notes/SimpleNotes/App/SentryConfig.swift \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "chore(simple-notes): lower Sentry tracesSampleRate to 0.01"
```

---

## Task 9: E2E + stop

- [x] Full `make clean test`.
- [x] Both configs build (Release + ReleaseCloudKit).
- [x] No push.

## Definition of Done (M7)

- [x] Attachment inverse + externalStorage wired
- [x] Per-config entitlements
- [x] Both IPAs build in CI
- [x] File size pre-check
- [x] Attachment helper extracted
- [x] Release pipeline rolls back on verification failure
- [x] Sentry sample rate lowered
- [x] No push, no PR
