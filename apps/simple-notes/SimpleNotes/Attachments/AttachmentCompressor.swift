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
        // scale = 1 so the bitmap is pixel-accurate to `newSize` instead of the
        // screen's scale factor (on a 3x device the default would produce a
        // 6144px bitmap for a 2048pt canvas).
        let format = UIGraphicsImageRendererFormat.default()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }
}
