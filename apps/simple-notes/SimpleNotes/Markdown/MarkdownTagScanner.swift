import Foundation

struct MarkdownTag: Equatable {
    let name: String
    let range: Range<String.Index>
}

enum MarkdownTagScanner {
    private static let nameChars: Set<Character> = {
        var s = Set<Character>()
        for u in UnicodeScalar("A").value...UnicodeScalar("Z").value {
            s.insert(Character(UnicodeScalar(u)!))
        }
        for u in UnicodeScalar("a").value...UnicodeScalar("z").value {
            s.insert(Character(UnicodeScalar(u)!))
        }
        for u in UnicodeScalar("0").value...UnicodeScalar("9").value {
            s.insert(Character(UnicodeScalar(u)!))
        }
        s.insert("_")
        s.insert("-")
        return s
    }()

    static func tags(in text: String) -> [MarkdownTag] {
        var results: [MarkdownTag] = []
        var i = text.startIndex
        while let hash = text[i...].firstIndex(of: "#") {
            let precededOK: Bool = {
                guard hash != text.startIndex else { return true }
                let prev = text[text.index(before: hash)]
                return prev.isWhitespace || "(,.;:!?[]{}".contains(prev)
            }()
            let nameStart = text.index(after: hash)
            var nameEnd = nameStart
            while nameEnd < text.endIndex, nameChars.contains(text[nameEnd]) {
                nameEnd = text.index(after: nameEnd)
            }
            if precededOK && nameStart < nameEnd {
                results.append(
                    MarkdownTag(
                        name: String(text[nameStart..<nameEnd]),
                        range: hash..<nameEnd
                    )
                )
                i = nameEnd
            } else {
                i = text.index(after: hash)
            }
            if i >= text.endIndex { break }
        }
        return results
    }
}
