import Foundation

enum MarkdownPlainText {
    static func strip(_ markdown: String) -> String {
        let options = AttributedString.MarkdownParsingOptions(
            allowsExtendedAttributes: false,
            interpretedSyntax: .inlineOnlyPreservingWhitespace
        )
        let attributed = (try? AttributedString(markdown: markdown, options: options))
            ?? AttributedString(markdown)
        return String(attributed.characters)
    }
}
