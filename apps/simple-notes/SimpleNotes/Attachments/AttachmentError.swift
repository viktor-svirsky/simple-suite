import Foundation

enum AttachmentError: Error, Equatable {
    case encodingFailed
    case tooLarge
}
