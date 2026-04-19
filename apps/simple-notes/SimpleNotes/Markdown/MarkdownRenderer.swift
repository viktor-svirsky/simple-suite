import Foundation
import SwiftUI

enum MarkdownRenderer {
    static func render(_ markdown: String) -> AttributedString {
        let options = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: true,
            interpretedSyntax: .full
        )
        var attributed: AttributedString
        do {
            attributed = try AttributedString(
                markdown: markdown,
                options: options
            )
        } catch {
            attributed = AttributedString(markdown)
        }

        let flat = String(attributed.characters)
        let tags = MarkdownTagScanner.tags(in: flat)
        for tag in tags {
            let lower = flat.distance(from: flat.startIndex, to: tag.range.lowerBound)
            let upper = flat.distance(from: flat.startIndex, to: tag.range.upperBound)
            guard
                let start = attributed.offsetIndex(by: lower),
                let end = attributed.offsetIndex(by: upper)
            else { continue }
            attributed[start..<end].font = .system(.body, design: .monospaced)
            attributed[start..<end].foregroundColor = Theme.Color.muted
        }

        return attributed
    }
}

private extension AttributedString {
    func offsetIndex(by n: Int) -> AttributedString.Index? {
        var idx = startIndex
        for _ in 0..<n {
            guard idx < endIndex else { return nil }
            idx = characters.index(after: idx)
        }
        return idx
    }
}
