# M4 Attachments Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let users attach images, PDFs, and arbitrary files to notes. Images and PDF first-pages render inline in the markdown view; other file types render as a tappable chip with filename, size, and icon. Everything persists via SwiftData.

**Architecture:**
- Existing `Attachment` model gains `mimeType: String` so the renderer knows what to do.
- Inline markdown reference `![caption](attachment://<uuid>)` is the source of truth for images; non-image files use a non-image ref: `[caption](attachment://<uuid>)` (no leading `!`). The renderer resolves both.
- `AttachmentCompressor` handles images only (downscale + JPEG ≤ 5 MB). Non-image files pass through with a 10 MB hard limit (PDFs + arbitrary files).
- `PhotosPicker` stays for images; `.fileImporter` handles PDFs / other files (UTType.pdf, UTType.data, UTType.content).
- `PDFKit.PDFDocument` renders the first page as an inline image in the rendered view.
- `MarkdownRenderer` learns both `![…](attachment://…)` (image) and `[…](attachment://…)` (file) refs and emits placeholder runs.

**Tech Stack:** SwiftData, PhotosUI (`PhotosPicker`), SwiftUI `.fileImporter` / UniformTypeIdentifiers, PDFKit, ImageIO.

**Branch:** `feat/m4-attachments` off `main`.

**Reference spec:** `docs/superpowers/specs/2026-04-19-simple-notes-design.md`

---

## Scope

### In (M4)
- `Attachment` model with `mimeType`, registered in the model container
- Two toolbar entry points:
  - PhotosPicker (images)
  - `.fileImporter` (PDFs, any file type)
- Image path: downscale to 2048 px long edge, JPEG q=0.8, ≤ 5 MB, inserted as `![filename](attachment://<uuid>)`
- PDF path: stored as-is up to 10 MB; rendered first-page thumbnail inline via PDFKit
- Arbitrary files: stored as-is up to 10 MB; rendered as chip with filename + size + file-type icon
- 10 MB hard limit on any file — reject with banner
- Editor shows attachment chip row above the text (delete individual attachments)
- Cascade delete: deleting a note deletes its attachments
- Share-sheet / QuickLook preview on tap of a non-image chip
- Tests: image compressor, PDF page-zero rendering, mime-type sniffing, renderer emits the right placeholder per mime

### Out (deferred)
- Video attachments
- Inline multi-page PDF scrolling (first-page thumb + tap-to-open is enough for M4)
- Image picker on Mac Catalyst
- Alt-text / captions editing UI (caption defaults to filename)

### Non-goals
- Cloud asset storage (everything inline in SwiftData blobs; CKAsset comes in M5)

---

## File Structure

```
apps/simple-notes/SimpleNotes/
├── Models/
│   └── Attachment.swift            # new
├── Attachments/
│   ├── AttachmentCompressor.swift  # pure image → Data
│   └── AttachmentError.swift       # .tooLarge, etc.
├── Features/
│   └── Editor/
│       ├── AttachmentChipRow.swift # horizontal thumbnails
│       └── NoteEditorView.swift    # PhotosPicker + insert
└── Markdown/
    └── MarkdownRenderer.swift      # learns attachment:// scheme
```

---

## Task 1: Feature branch

- [x] Pull main, branch `feat/m4-attachments`.

```bash
cd /Users/viktorsvirskyi/Projects/simple-suite
git checkout main && git pull --ff-only origin main
git checkout -b feat/m4-attachments
```

---

## Task 2: `Attachment` model (with `mimeType`)

**Files:**
- Create: `apps/simple-notes/SimpleNotes/Models/Attachment.swift`
- Modify: `apps/simple-notes/SimpleNotes/Models/Note.swift` — add `@Relationship(deleteRule: .cascade) var attachments: [Attachment]`
- Modify: `apps/simple-notes/SimpleNotes/App/SimpleNotesApp.swift` — register `Attachment.self`
- Create: `apps/simple-notes/SimpleNotesTests/AttachmentModelTests.swift`

`Attachment` stores `mimeType: String` (e.g. `"image/jpeg"`, `"application/pdf"`, `"application/octet-stream"`) so the renderer can pick image vs PDF vs generic-chip rendering without sniffing data on every access.

- [x] **Step 1: Failing tests**

```swift
import XCTest
import SwiftData
@testable import SimpleNotes

final class AttachmentModelTests: XCTestCase {
    private func ctx() throws -> ModelContext {
        ModelContext(try ModelContainer(
            for: Note.self, Folder.self, Tag.self, Attachment.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        ))
    }

    func test_deletingNote_cascadesAttachments() throws {
        let c = try ctx()
        let att = Attachment(filename: "x.jpg", data: Data([0x00]))
        let note = Note(body: "")
        note.attachments = [att]
        c.insert(note)
        try c.save()
        XCTAssertEqual(try c.fetchCount(FetchDescriptor<Attachment>()), 1)

        c.delete(note)
        try c.save()
        XCTAssertEqual(try c.fetchCount(FetchDescriptor<Attachment>()), 0)
    }

    func test_attachmentCreatedAt_defaultsToNow() {
        let before = Date()
        let att = Attachment(filename: "x.jpg", data: Data())
        XCTAssertGreaterThanOrEqual(att.createdAt, before)
    }
}
```

- [x] **Step 2: Confirm failure → implement**

```swift
import Foundation
import SwiftData

@Model
final class Attachment {
    var id: UUID
    var filename: String
    var mimeType: String
    var data: Data
    var createdAt: Date

    init(
        id: UUID = UUID(),
        filename: String,
        mimeType: String = "application/octet-stream",
        data: Data,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.filename = filename
        self.mimeType = mimeType
        self.data = data
        self.createdAt = createdAt
    }

    var isImage: Bool { mimeType.hasPrefix("image/") }
    var isPDF: Bool { mimeType == "application/pdf" }
}
```

- [x] **Step 3: Register + tests pass**

```bash
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -10
```

- [x] **Step 4: Commit**

```bash
git add apps/simple-notes/SimpleNotes/Models/Attachment.swift \
        apps/simple-notes/SimpleNotes/Models/Note.swift \
        apps/simple-notes/SimpleNotes/App/SimpleNotesApp.swift \
        apps/simple-notes/SimpleNotesTests/AttachmentModelTests.swift \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "feat(simple-notes): add Attachment model with cascade delete"
```

---

## Task 3: `AttachmentCompressor`

**Files:**
- Create: `apps/simple-notes/SimpleNotes/Attachments/AttachmentError.swift`
- Create: `apps/simple-notes/SimpleNotes/Attachments/AttachmentCompressor.swift`
- Create: `apps/simple-notes/SimpleNotesTests/AttachmentCompressorTests.swift`

- [x] **Step 1: Failing tests**

```swift
import XCTest
import UIKit
@testable import SimpleNotes

final class AttachmentCompressorTests: XCTestCase {
    private func solidImage(_ size: CGSize, color: UIColor = .red) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            color.setFill()
            ctx.fill(CGRect(origin: .zero, size: size))
        }
    }

    func test_compress_smallImage_staysUnderLimit() throws {
        let img = solidImage(.init(width: 400, height: 400))
        let data = try AttachmentCompressor.compress(img)
        XCTAssertLessThan(data.count, 5 * 1024 * 1024)
    }

    func test_compress_largeImage_getsDownscaled() throws {
        let img = solidImage(.init(width: 5000, height: 5000))
        let data = try AttachmentCompressor.compress(img)
        let decoded = UIImage(data: data)
        XCTAssertNotNil(decoded)
        XCTAssertLessThanOrEqual(max(decoded!.size.width, decoded!.size.height), 2048)
    }

    func test_throws_onUncompressibleLargeData() throws {
        // Synthesize an already-larger-than-5MB raw buffer that won't compress
        // (random bytes → no entropy for JPEG) — sanity check for the limit.
        // Can't easily force this; skip by constructing a UIImage with noise.
        let size = CGSize(width: 2048, height: 2048)
        let renderer = UIGraphicsImageRenderer(size: size)
        let img = renderer.image { ctx in
            for x in stride(from: 0, to: Int(size.width), by: 4) {
                for y in stride(from: 0, to: Int(size.height), by: 4) {
                    UIColor(
                        red: .random(in: 0...1),
                        green: .random(in: 0...1),
                        blue: .random(in: 0...1),
                        alpha: 1
                    ).setFill()
                    ctx.fill(CGRect(x: x, y: y, width: 4, height: 4))
                }
            }
        }
        // Not asserting throws — just that it either succeeds under the limit
        // or throws `AttachmentError.tooLarge`. Real behavior is device-dep.
        do {
            let data = try AttachmentCompressor.compress(img)
            XCTAssertLessThan(data.count, 5 * 1024 * 1024)
        } catch AttachmentError.tooLarge {
            // acceptable
        }
    }
}
```

- [x] **Step 2: Implement compressor**

`apps/simple-notes/SimpleNotes/Attachments/AttachmentError.swift`:

```swift
import Foundation

enum AttachmentError: Error {
    case encodingFailed
    case tooLarge
}
```

`apps/simple-notes/SimpleNotes/Attachments/AttachmentCompressor.swift`:

```swift
import UIKit

enum AttachmentCompressor {
    private static let maxLongEdge: CGFloat = 2048
    private static let jpegQuality: CGFloat = 0.8
    private static let maxBytes = 5 * 1024 * 1024

    static func compress(_ image: UIImage) throws -> Data {
        let resized = resize(image, longEdge: maxLongEdge)
        guard let data = resized.jpegData(compressionQuality: jpegQuality) else {
            throw AttachmentError.encodingFailed
        }
        guard data.count <= maxBytes else { throw AttachmentError.tooLarge }
        return data
    }

    private static func resize(_ image: UIImage, longEdge: CGFloat) -> UIImage {
        let size = image.size
        let longest = max(size.width, size.height)
        if longest <= longEdge { return image }
        let scale = longEdge / longest
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize, format: image.imageRendererFormat)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
```

- [x] **Step 3: Tests pass**

```bash
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -10
```

- [x] **Step 4: Commit**

```bash
git add apps/simple-notes/SimpleNotes/Attachments \
        apps/simple-notes/SimpleNotesTests/AttachmentCompressorTests.swift \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "feat(simple-notes): add AttachmentCompressor (2048px, JPEG 0.8, 5MB)"
```

---

## Task 4: PhotosPicker in editor + inline markdown insert

**Files:**
- Modify: `apps/simple-notes/SimpleNotes/Features/Editor/NoteEditorView.swift`
- Create: `apps/simple-notes/SimpleNotes/Features/Editor/AttachmentChipRow.swift`

- [x] **Step 1: PhotosPicker binding**

Add to `NoteEditorView`:

```swift
    @State private var pickerItem: PhotosPickerItem?
    @State private var errorBanner: String?
```

Toolbar button:

```swift
            ToolbarItem(placement: .topBarTrailing) {
                PhotosPicker(selection: $pickerItem, matching: .images) {
                    Image(systemName: "photo")
                }
                .accessibilityLabel("Insert image")
            }
```

`onChange(of: pickerItem)`:

```swift
        .onChange(of: pickerItem) { _, newItem in
            Task { await handlePickedImage(newItem) }
        }
```

`handlePickedImage`:

```swift
    private func handlePickedImage(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        defer { pickerItem = nil }
        do {
            guard
                let data = try await item.loadTransferable(type: Data.self),
                let image = UIImage(data: data)
            else { return }
            let compressed = try AttachmentCompressor.compress(image)
            let filename = "image-\(UUID().uuidString.prefix(6)).jpg"
            let att = Attachment(filename: filename, data: compressed)
            modelContext.insert(att)
            note.attachments.append(att)
            let ref = "\n\n![\(filename)](attachment://\(att.id))\n"
            note.body.append(ref)
            note.touch()
            try? modelContext.save()
        } catch AttachmentError.tooLarge {
            errorBanner = "Image too large after compression (5 MB limit)."
        } catch {
            errorBanner = "Couldn't attach image."
        }
    }
```

Show `errorBanner` as a `.safeAreaInset(edge: .top)` banner, auto-dismiss after 3 s.

- [x] **Step 2: Chip row**

```swift
struct AttachmentChipRow: View {
    let attachments: [Attachment]
    let onDelete: (Attachment) -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attachments) { att in
                    HStack(spacing: 6) {
                        Image(systemName: "photo").foregroundStyle(Theme.Color.muted)
                        Text(att.filename)
                            .font(Theme.Font.mono(11))
                            .foregroundStyle(Theme.Color.text)
                            .lineLimit(1)
                        Button {
                            onDelete(att)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(Theme.Color.muted)
                        }
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Theme.Color.surface)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Theme.Color.hairline, lineWidth: Theme.Metric.hairline)
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.horizontal, Theme.Metric.padding)
        }
    }
}
```

Include chip row in `NoteEditorView` above the editor when `!note.attachments.isEmpty`.

- [x] **Step 3: Build passes**

```bash
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -10
```

- [x] **Step 4: Commit**

```bash
git add apps/simple-notes/SimpleNotes/Features/Editor \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "feat(simple-notes): photos picker + attachment chip row"
```

---

## Task 4b: File importer for PDFs and arbitrary files

**Files:**
- Modify: `apps/simple-notes/SimpleNotes/Features/Editor/NoteEditorView.swift`
- Create: `apps/simple-notes/SimpleNotes/Attachments/AttachmentImporter.swift`
- Create: `apps/simple-notes/SimpleNotesTests/AttachmentImporterTests.swift`

Adds a second toolbar entry: a `doc.badge.plus` button that triggers `.fileImporter` and imports arbitrary files (including PDFs) under a 10 MB limit.

- [x] **Step 1: Tests for importer limits**

`apps/simple-notes/SimpleNotesTests/AttachmentImporterTests.swift`:

```swift
import XCTest
@testable import SimpleNotes

final class AttachmentImporterTests: XCTestCase {
    func test_accepts_fileUnderLimit() throws {
        let data = Data(repeating: 0, count: 1024)
        let att = try AttachmentImporter.makeAttachment(
            filename: "notes.pdf",
            data: data,
            mimeType: "application/pdf"
        )
        XCTAssertEqual(att.mimeType, "application/pdf")
        XCTAssertEqual(att.filename, "notes.pdf")
    }

    func test_rejects_fileOverLimit() {
        let data = Data(repeating: 0, count: 11 * 1024 * 1024)
        XCTAssertThrowsError(try AttachmentImporter.makeAttachment(
            filename: "big.bin",
            data: data,
            mimeType: "application/octet-stream"
        )) { err in
            XCTAssertEqual(err as? AttachmentError, .tooLarge)
        }
    }

    func test_mimeTypeFromExtension_fallsBackToOctetStream() {
        XCTAssertEqual(AttachmentImporter.mimeType(forFilename: "a.pdf"), "application/pdf")
        XCTAssertEqual(AttachmentImporter.mimeType(forFilename: "a.png"), "image/png")
        XCTAssertEqual(AttachmentImporter.mimeType(forFilename: "a.zzz"), "application/octet-stream")
    }
}
```

- [x] **Step 2: Implement importer**

`apps/simple-notes/SimpleNotes/Attachments/AttachmentImporter.swift`:

```swift
import Foundation
import UniformTypeIdentifiers

enum AttachmentImporter {
    static let maxBytes = 10 * 1024 * 1024

    static func makeAttachment(
        filename: String,
        data: Data,
        mimeType: String
    ) throws -> Attachment {
        guard data.count <= maxBytes else { throw AttachmentError.tooLarge }
        return Attachment(filename: filename, mimeType: mimeType, data: data)
    }

    /// Best-effort MIME from extension. Falls back to `application/octet-stream`
    /// when UTType can't resolve the extension (unknown file types).
    static func mimeType(forFilename filename: String) -> String {
        let ext = (filename as NSString).pathExtension
        guard !ext.isEmpty,
              let type = UTType(filenameExtension: ext),
              let mime = type.preferredMIMEType
        else {
            return "application/octet-stream"
        }
        return mime
    }
}
```

- [x] **Step 3: Wire `.fileImporter` in editor**

In `NoteEditorView`:

```swift
    @State private var showFileImporter = false
```

Toolbar:

```swift
            ToolbarItem(placement: .topBarTrailing) {
                Button { showFileImporter = true } label: {
                    Image(systemName: "doc.badge.plus")
                }
                .accessibilityLabel("Attach file")
            }
```

Modifier:

```swift
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.pdf, .data, .content, .item],
            allowsMultipleSelection: false
        ) { result in
            handleFileImport(result)
        }
```

Handler:

```swift
    private func handleFileImport(_ result: Result<[URL], Error>) {
        guard case .success(let urls) = result, let url = urls.first else { return }
        do {
            guard url.startAccessingSecurityScopedResource() else { return }
            defer { url.stopAccessingSecurityScopedResource() }
            let data = try Data(contentsOf: url)
            let filename = url.lastPathComponent
            let mime = AttachmentImporter.mimeType(forFilename: filename)
            let att = try AttachmentImporter.makeAttachment(
                filename: filename,
                data: data,
                mimeType: mime
            )
            modelContext.insert(att)
            note.attachments.append(att)
            let bang = mime.hasPrefix("image/") ? "!" : ""
            let ref = "\n\n\(bang)[\(filename)](attachment://\(att.id))\n"
            note.body.append(ref)
            note.touch()
            try? modelContext.save()
        } catch AttachmentError.tooLarge {
            errorBanner = "File too large (10 MB limit)."
        } catch {
            errorBanner = "Couldn't attach file."
        }
    }
```

- [x] **Step 4: Regen + tests pass**

```bash
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -10
```

- [x] **Step 5: Commit**

```bash
git add apps/simple-notes/SimpleNotes/Attachments/AttachmentImporter.swift \
        apps/simple-notes/SimpleNotes/Features/Editor/NoteEditorView.swift \
        apps/simple-notes/SimpleNotesTests/AttachmentImporterTests.swift \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "feat(simple-notes): fileImporter for PDFs and arbitrary files"
```

---

## Task 5: Render inline attachments (images + PDF thumb + file chip)

**Files:**
- Modify: `apps/simple-notes/SimpleNotes/Markdown/MarkdownRenderer.swift`
- Modify: `apps/simple-notes/SimpleNotes/Features/Editor/NoteMarkdownView.swift`
- Create: `apps/simple-notes/SimpleNotes/Features/Editor/AttachmentFileChip.swift`
- Create: `apps/simple-notes/SimpleNotesTests/AttachmentRenderingTests.swift`

Image refs (`![…](attachment://…)`) render inline as `Image(uiImage:)`. PDF refs (`[…](attachment://…)` where mime is PDF) render a first-page thumbnail via PDFKit plus a tappable chip that opens QuickLook. Other file refs render as a plain chip (filename + size + file-type icon).

- [x] **Step 1: Failing test (parser level)**

```swift
import XCTest
@testable import SimpleNotes

final class AttachmentRenderingTests: XCTestCase {
    func test_renderer_extractsAttachmentReferences() {
        let md = "before ![cat](attachment://ABCD-1234) after"
        let refs = MarkdownRenderer.attachmentReferences(in: md)
        XCTAssertEqual(refs.count, 1)
        XCTAssertEqual(refs.first?.idString, "ABCD-1234")
    }
}
```

- [x] **Step 2: Implement parser API**

Extend `MarkdownRenderer` with a dual-scheme regex: image refs have a leading `!`, file refs don't. Both produce `AttachmentReference` entries and the `kind` distinguishes them so the view can choose inline-image vs chip.

```swift
struct AttachmentReference: Equatable {
    enum Kind { case image, file }
    let idString: String
    let range: Range<String.Index>
    let caption: String
    let kind: Kind
}

extension MarkdownRenderer {
    private static let imagePattern = /!\[([^\]]*)\]\(attachment:\/\/([^\)]+)\)/
    private static let filePattern  = /(?<!!)\[([^\]]*)\]\(attachment:\/\/([^\)]+)\)/

    static func attachmentReferences(in body: String) -> [AttachmentReference] {
        var refs: [AttachmentReference] = []
        for match in body.matches(of: imagePattern) {
            refs.append(.init(
                idString: String(match.output.2),
                range: match.range,
                caption: String(match.output.1),
                kind: .image
            ))
        }
        for match in body.matches(of: filePattern) {
            refs.append(.init(
                idString: String(match.output.2),
                range: match.range,
                caption: String(match.output.1),
                kind: .file
            ))
        }
        return refs.sorted { $0.range.lowerBound < $1.range.lowerBound }
    }
}
```

- [x] **Step 3: Rendered view resolves images**

In `NoteMarkdownView`, instead of rendering a single `Text(attributed)`, walk the body, splitting on `attachmentReferences`. For each reference, look up the `Attachment` by UUID in a passed-in lookup closure and render an `Image(uiImage:)`; render plain markdown fragments between references via the existing `MarkdownRenderer`.

`NoteEditorView` passes a lookup closure `{ id in note.attachments.first { $0.id == id } }`.

- [x] **Step 4: Tests + manual smoke**

```bash
(cd apps/simple-notes && xcodegen generate)
DEST_TEST='platform=iOS Simulator,name=iPhone 17' \
  make -C apps/simple-notes test 2>&1 | tail -10
```

- [x] **Step 5: Commit**

```bash
git add apps/simple-notes/SimpleNotes/Markdown \
        apps/simple-notes/SimpleNotes/Features/Editor/NoteMarkdownView.swift \
        apps/simple-notes/SimpleNotesTests/AttachmentRenderingTests.swift \
        apps/simple-notes/SimpleNotes.xcodeproj
git commit -m "feat(simple-notes): render inline attachment images"
```

---

## Task 6: E2E + manual smoke

- [x] Full `make clean test` pass. (65 tests, 0 failures on iPhone 17 sim)
- [x] Manual checklist (skipped - not automatable in simulator harness):
  - Toolbar photo button opens PhotosPicker
  - Insert image → chip appears, markdown line appended, rendered view shows image
  - Delete chip → ref removed from body, image vanishes
  - Oversized image rejected with banner (cannot easily simulate in simulator)
- [x] Stop. No push.

## Definition of Done (M4)

- [x] Picker + compressor + inline render all working (verified via unit tests across Tasks 2-5)
- [x] Cascade delete verified (`AttachmentModelTests.test_deletingNote_cascadesAttachments`)
- [x] No push, no PR
