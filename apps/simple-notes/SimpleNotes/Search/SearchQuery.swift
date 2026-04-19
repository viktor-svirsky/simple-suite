import Foundation

struct SearchQuery: Equatable {
    var text: String = ""
    var tags: [String] = []
    var folderName: String? = nil

    var isEmpty: Bool {
        text.isEmpty && tags.isEmpty && folderName == nil
    }
}
