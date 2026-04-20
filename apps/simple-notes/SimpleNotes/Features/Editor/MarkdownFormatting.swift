import Foundation

enum MarkdownFormatting {
    enum Style {
        case bold
        case italic
    }

    static func insert(_ style: Style, into text: inout String) {
        let marker: String
        let placeholder: String
        switch style {
        case .bold:
            marker = "**"
            placeholder = "bold"
        case .italic:
            marker = "_"
            placeholder = "italic"
        }
        let needsSeparator = text.last.map { !$0.isWhitespace } ?? false
        let prefix = needsSeparator ? " " : ""
        text.append("\(prefix)\(marker)\(placeholder)\(marker)")
    }
}
