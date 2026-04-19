// Renders the simple-notes app icon as a 1024x1024 PNG.
// Run:  swift build-icon.swift
// Output: SimpleNotes/Resources/Assets.xcassets/AppIcon.appiconset/AppIcon.png
//
// Minimal mono Bear-like aesthetic: dark bg, serif wordmark.

import AppKit
import CoreGraphics
import Foundation

let size: CGFloat = 1024
let bg = NSColor(red: 0x0A / 255, green: 0x0A / 255, blue: 0x0A / 255, alpha: 1)
let fg = NSColor(red: 0xFA / 255, green: 0xFA / 255, blue: 0xFA / 255, alpha: 1)

let colorSpace = CGColorSpaceCreateDeviceRGB()
guard let context = CGContext(
    data: nil,
    width: Int(size),
    height: Int(size),
    bitsPerComponent: 8,
    bytesPerRow: 0,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fatalError("Could not create bitmap context")
}

// Background
context.setFillColor(bg.cgColor)
context.fill(CGRect(x: 0, y: 0, width: size, height: size))

// Wordmark: lowercase "sn" in New York serif.
// Fallback to Georgia if New York is unavailable (e.g. older macOS on CI).
let fontSize: CGFloat = 620
let font = NSFont(name: "NewYork-Medium", size: fontSize)
    ?? NSFont(name: "Georgia", size: fontSize)
    ?? NSFont.systemFont(ofSize: fontSize, weight: .medium)

let paragraph = NSMutableParagraphStyle()
paragraph.alignment = .center
let attrs: [NSAttributedString.Key: Any] = [
    .font: font,
    .foregroundColor: fg,
    .paragraphStyle: paragraph,
    .kern: -18,
]
let text = "sn" as NSString
let bounds = text.size(withAttributes: attrs)
let rect = CGRect(
    x: (size - bounds.width) / 2,
    y: (size - bounds.height) / 2 - 40,
    width: bounds.width,
    height: bounds.height
)

// Draw text via NSGraphicsContext so NSString.draw uses our bitmap.
let nsctx = NSGraphicsContext(cgContext: context, flipped: false)
NSGraphicsContext.saveGraphicsState()
NSGraphicsContext.current = nsctx
text.draw(in: rect, withAttributes: attrs)
NSGraphicsContext.restoreGraphicsState()

guard let cgImage = context.makeImage() else {
    fatalError("Could not create CGImage")
}
let rep = NSBitmapImageRep(cgImage: cgImage)
guard let data = rep.representation(using: .png, properties: [:]) else {
    fatalError("Could not encode PNG")
}

let script = URL(fileURLWithPath: CommandLine.arguments[0]).deletingLastPathComponent()
let repoRoot = script.deletingLastPathComponent()
let outputDir = repoRoot
    .appendingPathComponent("SimpleNotes/Resources/Assets.xcassets/AppIcon.appiconset")
let output = outputDir.appendingPathComponent("AppIcon.png")

try FileManager.default.createDirectory(at: outputDir, withIntermediateDirectories: true)
try data.write(to: output)
print("Wrote \(output.path) (\(data.count) bytes)")
