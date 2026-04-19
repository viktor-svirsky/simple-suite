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
