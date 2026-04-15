import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

guard CommandLine.arguments.count == 2 else {
    fputs("Usage: make_app_icon.swift <output.png>\n", stderr)
    exit(64)
}

let outputURL = URL(fileURLWithPath: CommandLine.arguments[1])
let canvasSize = 1024
let colorSpace = CGColorSpaceCreateDeviceRGB()

try FileManager.default.createDirectory(
    at: outputURL.deletingLastPathComponent(),
    withIntermediateDirectories: true
)

guard let context = CGContext(
    data: nil,
    width: canvasSize,
    height: canvasSize,
    bitsPerComponent: 8,
    bytesPerRow: canvasSize * 4,
    space: colorSpace,
    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
) else {
    fputs("Failed to create drawing context.\n", stderr)
    exit(1)
}

context.setAllowsAntialiasing(true)
context.setShouldAntialias(true)
context.setFillColor(CGColor(red: 1, green: 1, blue: 1, alpha: 1))
context.fill(CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))

let frameInset: CGFloat = 90
let frameRect = CGRect(
    x: frameInset,
    y: frameInset,
    width: CGFloat(canvasSize) - frameInset * 2,
    height: CGFloat(canvasSize) - frameInset * 2
)

context.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
context.setLineWidth(34)
context.addPath(CGPath(roundedRect: frameRect, cornerWidth: 180, cornerHeight: 180, transform: nil))
context.strokePath()

context.setLineCap(.round)
context.setLineJoin(.round)
context.setStrokeColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
context.setLineWidth(112)
context.move(to: CGPoint(x: 304, y: 640))
context.addLine(to: CGPoint(x: 512, y: 332))
context.addLine(to: CGPoint(x: 720, y: 640))
context.strokePath()

context.setFillColor(CGColor(red: 0, green: 0, blue: 0, alpha: 1))
context.fillEllipse(in: CGRect(x: 472, y: 740, width: 80, height: 80))

guard let image = context.makeImage() else {
    fputs("Failed to render icon image.\n", stderr)
    exit(1)
}

guard let destination = CGImageDestinationCreateWithURL(
    outputURL as CFURL,
    UTType.png.identifier as CFString,
    1,
    nil
) else {
    fputs("Failed to create PNG destination.\n", stderr)
    exit(1)
}

CGImageDestinationAddImage(destination, image, nil)

guard CGImageDestinationFinalize(destination) else {
    fputs("Failed to write PNG output.\n", stderr)
    exit(1)
}
