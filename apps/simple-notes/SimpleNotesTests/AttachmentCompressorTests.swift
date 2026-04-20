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
}
